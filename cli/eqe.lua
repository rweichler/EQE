-- this eqe table mirrors the one
-- that's in mediaserverd

local eqe = {}
local mt = {}

local get_band
mt.__index = function(t, k)
    if type(k) == 'number' then
        return get_band(k)
    end
end
mt.__len = function(t)
    return tonumber(ipc('return #eqe'))
end
setmetatable(eqe, mt)

local band = {}
function band:pretty_frequency()
    local f = self.frequency
    --[[
    -- i dont really like how this looks
    if f % 1000 == 0 and not (f == 0) then
        return tostring(f/1000)..'K Hz'
    end
    --]]
    return tostring(f)..' Hz '..self.name
end
function band:pretty_gain()
    return tostring(math.floor(self.gain*100 + 0.5)/100)..' dB'
end

function presetlist_count()
    return tonumber(ipc('return #presetlist(true)'))
end

function get_band(i)
    return setmetatable(band, {
        __index = function(t, k)
            local v = ipc('return eqe['..i..'][ [['..k..']] ]')
            return tonumber(v) or (v ~= 'nil' and tostring(v))
        end,
        __newindex = function(t, k, v)
            if type(v) == 'string' then
                v = '[['..v..']]'
            elseif not (type(v) == 'number') then
                error('invalid type')
            end

            if not (type(k) == 'string') then
                error('invalid type')
            end

            ipc('eqe['..i..'][ [['..k..']] ] = '..v)
            ipc('eqe.update('..i..')')
        end
    })
end

return eqe
