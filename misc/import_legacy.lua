--[[
imports presets from the old version
of EqualizerEverywhere

To get them, type this in MobileTerminal (or SSH):
eqe core < /var/tweak/com.r333d.eqe/lua/misc/import_legacy.lua
]]

local objc = require 'objc'

local freq = {
    60,
    170,
    310,
    600,
    1000,
    3000,
    6000,
    12000,
    14000,
    16000,
}
local path = '/var/mobile/Library/Preferences/com.r333d.equalizereverywhere.plist'

do
    local f = io.open(path, 'r')
    if f then
        f:close()
    else
        error("Couldn't open legacy EqualizerEverywhere prefs: "..path)
    end
end

local prefs = objc.tolua(objc.NSDictionary:dictionaryWithContentsOfFile(path))

for name,bands in pairs(prefs.PRESETS) do
    local input = {}
    input.preamp = 0

    for i,f in pairs(freq) do
        local band = filters.eq
        band.frequency = f
        band.gain = bands[i]
        input[#input + 1] = band
    end
    eqe.save(name..' (Imported)', input)
end
