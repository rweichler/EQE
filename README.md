# EQE

https://eqe.fm/thread/4

The EQE source is written in Lua and Objective-C. This repo contains the Lua code. The Objective-C code is closed source.

# How to make use of this code

This repo is exactly like what you would find in `/var/tweak/com.r333d.eqe/lua` on your iOS device. If you want to make changes, just edit the files there, and then run this command to load the changes:

```
killall -9 eqed mediaserverd backboardd
```

For an error log, install [deviceconsole](https://github.com/rpetrich/deviceconsole), connect your iOS device to your computer via USB, and then run this command:

```
deviceconsole | grep "EQE Log"
```

# High level overview of codebase

I'll explain the folders.

#### app

The entire app (other than the equalizer page) is in Lua. The forum browser, update logic, playback history, markdown parser, even the bootstrap code is in there. To get a high-level overview I'd look at `app/main.lua`, and everything in `app/page/`.

#### cli

![](https://i.imgur.com/fc2v7DGm.png)

The command-line ncurses "GUI". Code could use some improving, but it's a pretty small codebase. If you wanna mess around with stuff I'd recommend starting here.

#### common

Common libraries. This is where you can pilfer code from. Includes an Objective-C to Lua bridge, sqlite library (written by me), cmark library (written by me) and json library.

#### core

High-level equalizer manipulation stuff. `core/filter` is where you'll find the code for the different types of filters, `core/preset.lua` is preset saving/loading logic.

#### daemon

Code for the playback history tracker. Includes the logic for posting to [eqe.fm](https://eqe.fm). `scrobble` is called whenever an app plays a song. This is where you'd put the code for an alternative last.fm scrobbler.

#### misc

Convenience scripts you can run manually. Imports Winamp presets and that kinda stuff.

#### raw

High-level code for raw audio manipulation.

#### ui

Code for the frequency response curve in the equalizer UI. If you want to change its color or something this is where you'd do it. This is also where I hope for the equalizer UI to go once the LuaJIT bug is fixed (explained below).




