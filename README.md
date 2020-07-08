# EQE

https://eqe.fm/thread/4

EQE is written in Lua and Objective-C. This repo contains the Lua code. The Objective-C code is closed source.

## Oh... ok

Yeah there's a lot of Lua code though. This repo is in `/var/tweak/com.r333d.eqe/lua` on your iOS device. Edit the files there, hen SSH and run this command to reload:

```
killall -9 eqed mediaserverd backboardd
```

Errors are written to syslog with the prefix `EQE Log:`
