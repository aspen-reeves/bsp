-- VERSION     = "bsp.lua v1.0",
-- DESCRIPTION = "Blahaj Subsonic Player, a simple subsonic client for ComputerCraft",
-- URL         = "https://github.com/aspen-reeves/bsp",
-- LICENSE     =
--         FUCK AROUND and FIND OUT PUBLIC LICENSE
--                 Version 2, August 2023

-- Copyright (C) 2024 Aspen Reeves <aspenbreeves@gmail.com>

-- Everyone is permitted to copy and distribute verbatim or modified
-- copies of this license document, and changing it is allowed as long
-- as the name is changed.

--             FUCK AROUND and FIND OUT PUBLIC LICENSE
-- TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

-- 0. YOU MUST INCLUDE THE ABOVE COPYRIGHT NOTICE IN ALL COPIES, REDISTRIBUTIONS, OR MODIFICATIONS OF THE SOFTWARE
-- 1. DON'T BLAME ME FOR ANY SHIT
-- 2. else, You just DO WHAT THE FUCK YOU WANT TO.

-- THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, redistribution
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
-- THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local playlist = settings.get("bsp.playlist")
local doShuffle = settings.get("bsp.shuffle", true)
local volume = settings.get("bsp.volume", 5.0)

local instance = settings.get("bsp.instance")
local user = settings.get("bsp.user")
local password = settings.get("bsp.password")
local version = settings.get("bsp.version", "1.16.1")
local client = settings.get("bsp.client", "bsp")


local md5 = require("md5")
local monitor = peripheral.find("monitor")
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker") or error("speaker is required", 0)
local playing



---Generate the lion share of the URL.
---@param method string Method name, e.g. stream
---@return string URL Base URL
local function getRequestURL(method)
    local salt = ""
    for i = 1, 8 do
        salt = salt .. string.format("%x", math.random(0, 15))
    end
    local token = md5.sumhexa(password .. salt)
    local tmpURL = instance .. "/rest/" .. method .. "?u=" .. user .. "&t=" .. token .. "&s=" .. salt .. "&v=" .. version .. "&c=" .. client .. "&f=json"
    return tmpURL
end



---Get list of playlists.
---@return table playlists Format: Playlist Name = UUID
local function getPlaylists()
    local requesturl = getRequestURL("getPlaylists")
    local response = http.get(requesturl, {}, true)
    if response then
        ---@diagnostic disable-next-line: need-check-nil
        local data = response.readAll()
        ---@diagnostic disable-next-line: need-check-nil
        local decoded = textutils.unserializeJSON(data)
        local playlists = {}
        ---@diagnostic disable-next-line: need-check-nil
        for _, playlist in pairs(decoded["subsonic-response"].playlists.playlist) do
            playlists[playlist.name] = playlist.id
        end
        response.close()
        return playlists
    else
        print("Failed to connect to server")
    end
    return {}
end



---Get list of songs in a playlist.
---@param playlistName string|nil Name of playlist
---@return table songs Format: List of tables with keys id and name
local function getPlaylistSongs(playlistName)
    local playlists = getPlaylists()
    if playlistName == nil then
        playlistName = playlist
    end
    if not playlists[playlistName] then
        error("Playlist not found!", 0)
    end
    local requesturl = getRequestURL("getPlaylist") .. "&id=" .. playlists[playlistName]
    local response = http.get(requesturl, {}, true)
    if response then
        local data = response.readAll()
        local decoded = textutils.unserializeJSON(data)
        local songs = {}
        for _, song in pairs(decoded["subsonic-response"].playlist.entry) do
            table.insert(songs, {
                id = song.id,
                name = song.title
            })
        end
        response.close()
        return songs
    else
        print("Failed to connect to server")
    end
    return {}
end



---Shuffle around songs in playlist.
---@param playlist table Playlist
---@return table shuffled Shuffled playlist
---@see getPlaylistSongs
local function shufflePlaylist(playlist)
    local shuffled = {}
    for i = 1, #playlist do
        local newIndex
        repeat
            newIndex = math.random(1, #playlist)
        until not shuffled[newIndex]
        shuffled[newIndex] = playlist[i]
    end
    return shuffled
end



---Play song by ID.
---@param id string Song UUID 
local function playSong(id)
    -- Playing is basically a lockfile
    if playing == id then
        return
    end
    playing = id
    local requesturl = getRequestURL("stream") .. "&id=" .. id .. "&format=dfpwm"
    http.request({ url = requesturl, binary = true, headers = {}, method = "GET" })
    local _, url, response = os.pullEvent("http_success", 120)
    if not response then
        error("Instance big read error! " .. url)
    end
    local stream = response.readAll()
    response.close()
    if #stream == 0 then
        error("No audio data received! Make sure your transcoder settings are 100% correct (e.g. -f FFmpeg flag is set to dfpwm)", 0)
    end
    local decoder = dfpwm.make_decoder()
    print("Starting preprocessing...")
    local chunks = {}
    for i = 1, #stream / (16 * 1024) do
        chunks[i] = decoder(stream:sub((i - 1) * 16 * 1024 + 1, i * 16 * 1024))
    end
    print("Preprocessing done!")
    for _, chunk in pairs(chunks) do
        if playing ~= id then
            speaker.stop()
            return
        end
        while not speaker.playAudio(chunk, volume) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    playing = ""
end



---Display remaining tracks on an attached monitor.
---@param playlist table Playlist
---@param index number Index of current 
local function writeQueueMonitor(playlist, index)
    if not monitor then
        return
    end
    monitor.clear()
    monitor.setTextColor(4)
    monitor.setTextScale(1)
    monitor.setCursorPos(1, 1)
    monitor.write("Now Playing: ")
    monitor.setCursorPos(1, 2)
    monitor.write(playlist[index].name)
    if #playlist > index then
        monitor.setCursorPos(1, 3)
        monitor.write("Next Up: ")
        for i = 1, #playlist - index - 1 do
            monitor.setCursorPos(1, 3 + i)
            monitor.write(index + i .. ". ")
            monitor.write(playlist[index + i].name)
        end
    end
end



local songs = getPlaylistSongs()
for index, song in pairs(songs) do
    writeQueueMonitor(songs, index)
    print(song.name)
    playSong(song.id)
end