--[[
imports winamp presets

To get them, type this in MobileTerminal (or SSH):
eqe core < /var/tweak/com.r333d.eqe/lua/misc/import_winamp.lua
]]

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

local function lol(t, name)
    local input = {}

    local max = 0

    for k,v in pairs(t) do
        local band = filters.eq
        band.Q = 2
        band.frequency = freq[k]
        band.gain = (31 - v)*12/31
        max = math.max(band.gain, max)
        input[#input + 1] = band
    end
    input.preamp = -max
    eqe.save(name..' (Winamp)', input)
end

-- these numbers are weird because
-- the winamp config file is weird
lol({31,31,31,31,31,31,31,31,31,31},"Flat")
lol({16,16,16,22,29,39,46,49,50,50},"Full bass")
lol({20,22,31,44,40,29,18,14,12,12},"Full bass & treble")
lol({31,31,31,31,31,31,44,44,44,48},"Classical")
lol({31,31,26,22,22,22,26,31,31,31},"Club")
lol({16,20,28,32,32,42,44,44,32,32},"Dance")
lol({24,14,23,38,36,29,24,16,11, 8},"Earbuds")
lol({15,15,22,22,31,40,40,40,31,31},"Large Hall")
lol({40,31,25,23,22,22,25,27,27,28},"Live")
lol({20,20,31,31,31,31,31,31,20,20},"Party")
lol({35,24,20,19,23,34,36,36,35,35},"Pop")
lol({31,31,33,42,31,21,21,31,31,31},"Reggae")
lol({19,24,41,45,38,25,17,14,14,14},"Rock")
lol({24,29,34,36,34,25,18,16,14,12},"Soft")
lol({19,22,31,41,40,31,19,16,16,17},"Techno")
lol({48,48,48,39,27,14, 6, 6, 6, 4},"Full treble")
