--required settings

settings.set("bsp.instance", "https://music.example.com") -- url of the subsonic server
settings.set("bsp.user", "username")                      -- username for the subsonic user
settings.set("bsp.password", "password")                  -- password for the subsonic user, password is not sent anywhere, only a salted hash
settings.set("bsp.playlist", "playlistname")              -- for now, you have to set the playlist name here

--optional settings
settings.set("bsp.client", "bsp")  -- this is what the client will report itself as to the server
settings.set("bsp.volume", 3)      -- volume to set the speaker to when playing music
settings.set("bsp.displayNum", 10) -- number of songs that display on the monitor
settings.set("bsp.shuffle", true)  -- shuffle the playlist



settings.save()
