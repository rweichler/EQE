# EQE

https://eqe.fm/thread/4

EQE is written in Lua and Objective-C. This repo contains the Lua code. The Objective-C code is closed source.

## Oh... ok

Yeah there's a lot of Lua code though. This repo is in `/var/tweak/com.r333d.eqe/lua` on your iOS device. Just edit the files there, and then SSH and run this command to load the changes:

```
killall -9 eqed mediaserverd backboardd
```

Errors are posted to the syslog with the prefix `EQE Log:`
