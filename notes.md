# HOW TO INSTALL

If you are having any issues, go on the Discord chat: https://discord.gg/RSJWAuX

checkra1n, unc0ver, Electra and Chimera are supported. A12 is supported.

0. Install Filza and Debian Packager and coreutils and MTerminal (MTerminal from sbingner’s repo) and RocketBootstrap (RocketBootstrap from https://rpetri.ch/repo)
1. Copy/paste this link into Safari:  [github.com/rweichler/EQE/releases/download/checkra1n-beta1/eqe.deb](https://github.com/rweichler/EQE/releases/download/checkra1n-beta1/eqe.deb)
2. Open In/Copy to Filza (DON'T USE SILEO)
3. Tap on the file, tap Install, then Respring
4. Open MTerminal and type `uicache` (`uicache —all` on Coolstar jailbreaks) and press enter
5. If you have a previous install of EQE, reboot/rejailbreak. Otherwise the app may crash on launch.

_______

**App won't launch / crashes / freezes when launching**:
Reboot/rejailbreak.

________________________

**Activator / Control Center integration**
1. Install FlipConvert from https://julioverne.github.io/
2. Go to Settings>Control Center>Customize Controls
3. Add "EQE: Main controls"

There will now be an EQE button in your CC

________________________

**Can't connect to mediaserverd error**:
Try all of these:
1. Make sure to install the latest version of RocketBootstrap off rpetrich's repo (https://rpetri.ch/repo)
2. Make sure you're using the .deb in #download, not the version of EQE off Cydia.
3. Try manually killing mediaserverd. Open MTerminal, type `killall mediaserverd`, press enter.

________________________

**If you have any error such as "CoreFundation Error" or "Command Not Found"**, manually install eqe.deb by opening MTerminal, then
1. Type `su` and press enter
2. Type your root password (default is `alpine`) and press enter
3. Type `dpkg -i "/var/mobile/Documents/eqe.deb"` and press enter
4. Type `killall backboardd` and press enter
5. Once it resprings, open MTerminal again, type `uicache` and press enter
