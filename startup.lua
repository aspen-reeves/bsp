-- VERSION     = "bsp.lua v1.0",
-- DESCRIPTION = "Blahaj Subsonic Player, a simple subsonic client for ComputerCraft",
-- URL         = "",
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
local displayNum = settings.get("bsp.displayNum", 10)

local instance = settings.get("bsp.instance")
local user = settings.get("bsp.user")
local password = settings.get("bsp.password")
local version = settings.get("bsp.version", "1.16.1")
local client = settings.get("bsp.client", "bsp")


local md5 = require("md5")
local monitor = peripheral.find("monitor")
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

--subsonic would like a token to be generated for each new request, rather than using the password directly
--The token is a md5 hash of the password and a salt generated for each request
local function getAuthToken()
    local salt = ""
    --generate 8 character hex salt
    for i = 1, 8 do
        salt = salt .. string.format("%x", math.random(0, 15))
    end
    local token = md5.sumhexa(password .. salt)
    return token, salt
end

--function to get request URL, minus the optional parameters for a given method, which will be handled in the individual methods
local function getRequestURL(method)
    local token, salt = getAuthToken()
    local tmpURL = instance ..
        "/rest/" ..
        method .. "?u=" .. user .. "&t=" .. token .. "&s=" .. salt .. "&v=" .. version .. "&c=" .. client .. "&f=json"
    return tmpURL
end

--function to get the list of playlists
local function getPlaylists()
    local requesturl = getRequestURL("getPlaylists")
    local response = http.get(requesturl, {}, true)

    --return a table of paired id and name
    if response then
        local data = response.readAll()
        local decoded = textutils.unserializeJSON(data)
        local playlists = {}
        for i, v in pairs(decoded["subsonic-response"]["playlists"]["playlist"]) do
            playlists[v["id"]] = v["name"]
        end
        response.close()
        return playlists
    else
        print("Failed to connect to server")
    end
end
--here we get all the songs in a playlist, and return a table of index, id, and title
local function getPlaylistSongs(playlistName)
    local playlists = getPlaylists()
    if playlistName == nil then
        playlistName = playlist
    end
    local playlistID = nil
    for i, v in pairs(playlists) do
        if v == playlistName then
            playlistID = i
        end
    end
    if playlistID == nil then
        error("Playlist not found")
    end
    local requesturl = getRequestURL("getPlaylist") .. "&id=" .. playlistID
    local response = http.get(requesturl, {}, true)
    if response then
        local data = response.readAll()
        local decoded = textutils.unserializeJSON(data)
        local songs = {}
        -- each entry needs an index, the id, and the title

        for i, v in pairs(decoded["subsonic-response"]["playlist"]["entry"]) do
            songs[v["id"]] = v["title"]
        end
        local songCount = 1
        local queue = {} -- contain index, id, and title
        for i, v in pairs(songs) do
            queue[songCount] = { i, v }
            songCount = songCount + 1
        end

        response.close()
        return queue
    else
        print("Failed to connect to server")
    end
end

local function shufflePlaylist(songList)
    local shuffled = {}
    for i = 1, #songList do
        shuffled[i] = songList[i]
    end
    for i = 1, #shuffled do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end
local function getSong(id)
    local requesturl = getRequestURL("stream") .. "&id=" .. id .. "&format=dfpwm"
    http.request({ url = requesturl, binary = true, headers = {}, method = "GET" })
    local event, url, response = os.pullEvent("http_success", 120)

    if not response then
        error("Instance big read error! " .. url)
    end
    local data = response.readAll()
    response.close()
    return data
end
-- song data is in a big string, so we need to be able to split it into chunks
-- Stolen from ksss, Licenced MIT,  Copyright (c) 2024 kotahu
-- https://git.fish/kotahu/ksss
local function splitSong(songData, size)
    local chunks = {}
    local i = 1
    while i * size < string.len(songData) do
        chunks[#chunks + 1] = string.sub(songData, (i - 1) * size, (i * size) - 1)
        i = i + 1
    end
    chunks[#chunks + 1] = string.sub(songData, (i - 1) * size, string.len(songData))
    return chunks
end
--initialize the queueList
local queueList = nil
local currentSong = 1
local function getNextSong()
    currentSong = currentSong + 1
    if not queueList or #queueList < currentSong then
        queueList = getPlaylistSongs()
        if doShuffle then
            queueList = shufflePlaylist(queueList)
        end
        currentSong = 1
    end
    return queueList[currentSong]
end

-- this will write the current song and the next songs to the monitor, up to the displayNum
local function writeQueueMonitor()
    monitor.clear()
    monitor.setTextColor(4)
    monitor.setTextScale(1)
    if displayNum == 0 then
        return
    end
    monitor.setCursorPos(1, 1)
    monitor.write("Now Playing: ")
    monitor.setCursorPos(1, 2)
    if queueList == nil then
        error("Queue not initialized")
    end
    monitor.write(queueList[currentSong][2])
    if displayNum > 1 then
        monitor.setCursorPos(1, 3)
        monitor.write("Next Up: ")
        for i = 1, displayNum - 1 do
            monitor.setCursorPos(1, 3 + i)
            monitor.write(i .. ". ")
            monitor.write(queueList[currentSong + i][2])
        end
    end
end
local function playAudio()
    local song = getNextSong()
    writeQueueMonitor()
    print(song[2])
    local songData = getSong(song[1])
    local decoder = dfpwm.make_decoder()
    for _, chunk in pairs(splitSong(songData, 16 * 1024)) do
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer, volume) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end
while true do
    parallel.waitForAny(playAudio, function() os.pullEvent("monitor_touch") end)
    os.sleep(1)
end
