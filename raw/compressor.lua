local prefspath = '/var/tweak/com.r333d.eqe/db/compressor.lua'

local defaults = {
    pregain = 0,
    threshold = -24,
    knee = 30,
    ratio = 12,
    attack = 0.003,
    release = 0.25,
    predelay = 0.006,
    releasezone1 = 0.09,
    releasezone2 = 0.16,
    releasezone3 = 0.42,
    releasezone4 = 0.98,
    postgain = 0.98,
    wet = 1,
}

function compressor.save()
    IPCD_WRITE(prefspath, {
        enabled = compressor.enabled(),
        comp = compressor.comp(),
    })
end

function compressor.load()
    local success, prefs = pcall(dofile, prefspath)
    if not success then
        compressor.save()
        return compressor.load()
    end

    compressor.enabled(prefs.enabled)
    compressor.comp(prefs.comp or defaults)

    return t
end
