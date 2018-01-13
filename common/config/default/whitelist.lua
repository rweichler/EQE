--[[

this list is checked against the CFBundleIdentifier
property in the app's Info.plist file.

if an app is not found in this list, then
EQE will prompt the user and ask if it should record
playback history from within that app.

]]

return {
    -- apps that should record
    -- playback history without asking
    -- are set to true
    ['com.apple.Music'] = true,
    ['com.soundcloud.TouchApp'] = true,
    ['com.hypem.hyperadio'] = true,
    ['com.amazon.mp3.AmazonCloudPlayer'] = true,
    ['com.spotify.client'] = true,
    ['com.ascellamobile.musicloudfree'] = true,
    ['com.google.PlayMusic'] = true,

    -- apps that should be disabled by
    -- default are set to false
    ['com.zimride.instant'] = false,
    ['com.audible.iphone'] = false,
    ['com.apple.WebKit.WebContent'] = false,
    ['com.reddit.alienblue'] = false,
    ['bumpersfm.Bumper'] = false,
}
