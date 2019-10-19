package.path = '/var/tweak/com.r333d.eqe/lua/core/?.lua;'
             ..'/var/tweak/com.r333d.eqe/lua/core/?/init.lua;'
             ..package.path

local prefspath = '/var/tweak/com.r333d.eqe/db/crossfeed.lua'

function crossfeed.save()
    IPCD_WRITE(prefspath, {
        enabled = crossfeed.enabled(),
        delay = crossfeed.delay(),
        intensity = crossfeed.intensity(),
    })
end

function crossfeed.load()
    local success, prefs = pcall(dofile, prefspath)
    if not success then
        crossfeed.save()
        return crossfeed.load()
    end

    crossfeed.enabled(prefs.enabled)
    crossfeed.delay(prefs.delay)
    crossfeed.intensity(prefs.intensity)

    return true
end


local f = require('filter.lowpass'):new()
f.Q = 0.048578
f.frequency = 9604.148

crossfeed.coefs({{f:get_coefs(44100)}})
crossfeed.enabled(false)
crossfeed.delay(0.3)
crossfeed.intensity(0.4)
crossfeed.load()
