# Blahaj Subsonic Player

This is, right now, a very basic music player for CC:T, that uses any subsonic server with a compatible dfpwm encoder(see below), a CC:T computer with a speaker, and optionally a monitor to display the song queue and current song.

## Features

- Can play a playlist from a subsonic server, optionally with shuffle
- Display all the songs in the queue on a monitor
- Skip to the next song
- Not much else

### Maybe features in the future

- Pause and resume
- Volume control
- Search and play individual songs

## Installation

- download both startup.lua and md5.lua
- Set the following settings using the setting api, or edit the settings example file and run it

```sh
> set bsp.instance <URL>
> set bsp.user <username>
> set bsp.password <password>
> set bsp.playlist <playlist>
```

Where:

- `instance` is the URL of the subsonic server
- `user` is the username to the subsonic user
- `password` is the password to the subsonic user
- `playlist` is the subsonic playlist to play

And optionally the following:

```sh
> set bsp.client <clientname>
> set bsp.volume <volume>
> set bsp.displayNum <number>
> set bsp.shuffle <true/false>
```

Where:

- `client` is the client name to use when connecting to the subsonic server
- `volume` is the volume to set the speaker to
- `displayNum` is the number of songs to display on the monitor
- `shuffle` is whether to shuffle the playlist

## Server Information

- I personally use navidrome as my subsonic server, but this should work with any subsonic API compatible server
- To get dfpwm encoding support, you need to enable the `ND_ENABLETRANSCODINGCONFIG` setting in navidrome, and add a new encoder with the following settings:

  - `Name`: dfpwm (this can actually be whatever you want)
  - `Target Format`: dfpwm
  - `Default Bit Rate`: 48
  - `Command`:

```sh
 ffmpeg -i %s -c:a dfpwm -ar 48k -ac 1 -f dfpwm -
```

> Warning: This setting allows for any arbitrary command to be run on the server, so be careful with what you put in here and who has access to it

## Credit and License

- Parts of startup.lua are based on code from KSSS, License MIT, Copyright (c) 2024 kotahu
- This repository includes md5.lua, License MIT, Copyright (c) 2013 Enrique García Cota + Adam Baldwin + hanzao + Equi 4 Software
- The rest of this code is licensed under the FAFO-2-CLAUSE version 2, [a permissive public license](https://github.com/aspen-reeves/FAFO-PL)
