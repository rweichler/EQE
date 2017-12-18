return [[
# EQE

[(AKA EqualizerEverywhere 2.0)](http://google.com)

![](http://i.imgur.com/465gMXgm.png)
![](http://i.imgur.com/EGQ9Nl5m.png)
![](http://i.imgur.com/XYTknBAm.png)
![](http://i.imgur.com/L2W85Cnm.png)
![](http://i.imgur.com/YCm35Psm.png)

# What this is

[This](http://google.com) is two different concepts combined into one tweak:

* Realtime system-wide parametric equalizer
* Playback history tracker and music discovery platform (the eventual goal is to be kinda like Last.FM and What.CD (minus the piracy))

## _Equalizer_

* Parametric, so you can control Q-factor, frequency and gain of each band
* You can have up to 200 (!) bands simultaneously without it lagging
* Real-time. The instant you move your finger, you hear the audio change
* 9 built-in filter types
* Sexy UI
* Left/right ear equalization
* Activator integration ([more info here](/thread/2))
* Control over SSH or MobileTerminal via the `eqe` command
* Lua scripting ([more info here](/thread/2))

Available filter types:

* All-pass
* Band-pass
* Band-pass with Q peak gain
* Peaking EQ (this is the only one that was in EqualizerEverwhere 1.0)
* High-pass
* Low-pass
* High-shelf
* Low-shelf
* Notch

## _eqe.fm_

That's this website you're on right now.

So, you might have noticed this screenshot up there:

![](http://i.imgur.com/L2W85Cnm.png) ![](http://i.imgur.com/ejB7uQtm.png)

That's the playback history tracker. Every time you play a song (in an app that puts the info in the control center), EQE records it to `/var/db/com.r333d.eqe/history.db`. Kind of nifty way to keep track of what music you're into.

On top of this, you have the option to sign up on this website and have a backup of your playback history here as well. If you want an example of how it looks, click on my profile.  You can also opt into having your presets uploaded and stored on eqe.fm as well.

After you sign up you can follow people and stuff like that to see what they're listening to and discover new music. You can also look at their equalizer presets to get an idea of how to configure yours. I definitely know the struggle of finding the perfect preset and I think this site will help a lot with that.

And then obviously there's this forum.

## _Future plans_

eqe.fm:

* Top10 (like What.CD)
* Comment/rating pages for albums, personal collages, etc (like What.CD)
* Chat system (similar to Facebook)

EQE tweak:

* Port to jailed iOS (yes, this is possible)
* Scriptable music player that plays off of your filesystem using ffmpeg (basically, like iFile and Filza, but not shitty)
* Flex/Cydia-like platform where you can install Lua script plugins
* Possibly a built-in Gazelle browser and torrent client?
* Eventually port to Mac, Linux, Windows

The main issue that either makes or breaks these features is if I make enough money off this to support myself. Otherwise I'll be forced to get a job and won't have time to focus on this.

## _Supporting the project_

There are basically two ways to support this project:

* Writing Lua script plugins
* Giving me money

As far as the Lua scripts go I hope that this forum will facilitate that. As far as money goes, I hope that this website eventually facilitates that though some sort of "premium" thing, but for now I am doing a form of virtual panhandling. So please fund me if you want EQE to succeed.  As much as I'd like to do this for free, I can't.

# Download

You can get it off of Cydia by searching "EQE". It's on the [BigBoss](http://google.com) repo.
]]
