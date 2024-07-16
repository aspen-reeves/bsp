# Welcome to the Blahaj Subsonic Player

This is, right now, a very basic music player for computer craft, that uses any subsonic server with a compatible dfpwm converter, a computer craft computer with a speaker, and optionally a monitor to display the song queue and current song.

## Features

- Shuffle
- not much else

## Installation

- download both startup.lua and md5.lua
- Set the following settings using the setting api

```sh
> set bsp.instance <URL>
> set bsp.username <username>
> set bsp.password <password>
> set bsp.playlist <playlist>
```

Where:

- `instance` is the URL of the subsonic server
- `username` is the username to the subsonic user
- `password` is the password to the subsonic user
- `playlist` is the subsonic playlist to play

- and optionally the following

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

## server information

- I personally use navidrome as my subsonic server, but this should work with any subsonic API compatible server
- To get dfpwm encoding support, you need to enable the `ND_ENABLETRANSCODINGCONFIG` setting in navidrome, and add the following ffmpeg command for dfpwm encoding in the admin panel in navidrome

```sh
 ffmpeg -i input.mp3 -ac 1 -c:a dfpwm output.dfpwm -ar 48k 
```
