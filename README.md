# EQE

https://eqe.fm/thread/4

The EQE source is broken down into two parts:

* Lua (~60% of the codebase)
* Objective-C (~40% of the codebase)

This repo contains all of the Lua code. The Objective-C code is closed source. (See reasoning below)

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

# Objective-C stuff that ISN'T in this repo

* The equalizer UI itself, other than the frequency response curve (LuaJIT gets buggy when injected into SpringBoard, so for activator integration, I had to write this part in Objective-C)
* MobileSubstrate hooking logic (needs to be fast)
* Inter-process communication (multithreading is a nightmare in Lua)
* Biquad filter logic (needs to be fast)
* Activator / Flipswitch boilerplate (I'm pretty sure nobody cares about this code)
* cycript-esque REPL (multithreading is a nightmare in Lua)

**WHY THE OBJECTIVE-C PART IS CLOSED SOURCE**:

1. I plan on continuing development far into the future. For me, disclosing **all** of the source has no pros and is nothing but potential cons. For all I know, some Chinese company might steal this and run off with it into the sunset, like the [Citra 3DS emulator](https://gbatemp.net/threads/citra-unofficial-chinese-builds-discussion.431974/).
2. I want to discourage Objective-C contributions. Lua code is much easier to extend and maintain.

If people start contributing to (or the community substantially benefits from) the Lua side of things, I will open source the Objective-C side as well. But for now, I don't want to risk getting burned. I hope you will understand.

# Pull requests

I don't know if I'll accept pull requests. This is mostly just a mirror. Better to ask / post code on [the Discord chat](https://discordapp.com/invite/RSJWAuX) or on [the forum](https://eqe.fm/forum) first.
