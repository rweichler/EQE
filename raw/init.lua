if jit.arch == 'arm64' then
    jit.off()
end

package.path = LUA_PATH..'/?.lua;'..
               LUA_PATH..'/?/init.lua;'..
               LUA_PATH..'/../common/?.lua;'..
               LUA_PATH..'/../common/?/init.lua;'..
               package.path

local ffi = require 'ffi'
ffi.cdef[[
typedef void (*filter_function_t)(float **samples, int num_frames, int num_channels, float sampleRate);
void eqe_filter_set_raw_c_no_lock(filter_function_t f);
filter_function_t eqe_filter_get_raw_c();
]]

_G.examples = require 'examples'
_G.raw = {}

local mt = {}
mt.get = {}
mt.fget = {}
mt.set = {}
function mt.__index(t, k)
    return mt.fget[k] and mt.fget[k]() or mt.get[k]
end
function mt.__newindex(t, k, v)
    if mt.set[k] then
        mt.set[k](v)
    else
        rawset(t, k, v)
    end
end

function mt.set.lua(v)
    if not(v == nil) then
        -- test it first
        v(ffi.new('float[2][20]'), 20, 2, 44100, true)
    end

    mt.get.lua = v
    SET_MAIN(v)
end

mt.set.c = ffi.C.eqe_filter_set_raw_c_no_lock
mt.fget.c = ffi.C.eqe_filter_get_raw_c
setmetatable(raw, mt)

require 'autorun_loader'('raw')
