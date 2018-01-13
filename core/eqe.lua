ffi.cdef[[
typedef void (*filter_function_t)(float **samples, int frames, int channel, float sampleRate);
void eqe_filter_set_raw_c(filter_function_t f);
filter_function_t eqe_filter_get_raw_c();
]]
local sort_mt = {
    __index = function(t, k)
        local s2r = {} -- sorted to raw index mapping
        local r2s = {} -- raw to sorted index mapping
        for i=1,#t do
            s2r[i] = i
        end
        table.sort(s2r, function(a, b)
            return FILTER_GET(a).frequency < FILTER_GET(b).frequency
        end)

        for s=1,#t do
            local r = s2r[s]
            r2s[r] = s
        end

        if t == eqe.s2r then
            t = s2r
        elseif t == eqe.r2s then
            t = r2s
        else
            error('wat??')
        end
        eqe.s2r = s2r
        eqe.r2s = r2s
        return t[k]
    end,
    __newindex = function(t, k, v)
        error('read only')
    end,
    __len = FILTER_COUNT,
}

_G.filters = setmetatable({}, {
    __index = function(t, k)
        local filter = require('filter/'..k)
        filter.name = k
        return filter:new()
    end,
    __newindex = function()
        error('read only')
    end
})

function eqe:reset()
    if not getmetatable(eqe.s2r) then
        eqe.s2r = setmetatable({}, sort_mt)
        eqe.r2s = setmetatable({}, sort_mt)
    end
end

eqe.raw = FILTER_RUN_RAW
eqe.insert = FILTER_INSERT
function eqe.update(...)
    eqe:reset()
    return FILTER_UPDATE(...)
end
function eqe.flatten(...)
    eqe:reset()
    return FILTER_FLATTEN(...)
end

local get = {}
get.preamp = FILTER_GET_PREAMP
get.sample_rate = FILTER_GET_SAMPLE_RATE
get.raw_c = function()
    return ffi.C.eqe_filter_get_raw_c()
end

local set = {}
set.preamp = FILTER_SET_PREAMP
set.raw_c = function(v)
    ffi.C.eqe_filter_set_raw_c(v)
end

eqe.attr = {}

setmetatable(eqe, {
    __index = function(t, k)
        local f = get[k]
        if f then
            return f()
        else
            return FILTER_GET(k)
        end
    end,
    __newindex = function(t, k, v)
        local f = set[k]
        if f then
            f(v)
        elseif type(k) == 'number' then
            if type(v) == 'table' then
                FILTER_INSERT(k, v)
                eqe:reset()
            elseif v == nil then
                FILTER_REMOVE(k)
                eqe:reset()
            else
                error('invalid type')
            end
        elseif get[k] then
            error('readonly')
        else
            rawset(t, k, v)
        end
    end,
    __len = FILTER_COUNT,
})

eqe:reset()
return eqe
