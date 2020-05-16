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




