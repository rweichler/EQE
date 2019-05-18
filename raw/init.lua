if jit.arch == 'arm64' then
    jit.off()
end

package.path = LUA_PATH..'/?.lua;'..
               LUA_PATH..'/?/init.lua;'..
               LUA_PATH..'/../common/?.lua;'..
               LUA_PATH..'/../common/?/init.lua;'..
               package.path

local ffi = require 'ffi'
local C = ffi.C
ffi.cdef[[
typedef void (*filter_function_t)(float **samples, int num_frames, int num_channels, float sampleRate);
size_t eqe_filter_set_raw_c_no_lock(filter_function_t f);
size_t eqe_filter_unset_raw_c_no_lock(size_t idx);
filter_function_t eqe_filter_get_raw_c(size_t idx);
]]

_G.examples = require 'examples'
_G.raw = {}

local luamap = {}
local cmap = {}

local luastorage = {}
local cstorage = {}

local function genclosure(map, setfunc, unsetfunc, storage)
    local function closure(t, k, v)
        if v == nil then
            local idx = map[k]
            if not idx then return end

            unsetfunc(idx)
            map[k] = nil
            storage[k] = nil
            for k,v in pairs(map) do
                -- the array was reallocated, shift everything > idx down by 1
                if v > idx then
                    map[k] = v - 1
                end
            end
        else
            local chan0 = ffi.new('float[20]')
            local chan1 = ffi.new('float[20]')
            local audio = ffi.new('float *[2]', chan0, chan1)
            if type(v) == 'function' then
                v(audio, 20, 2, 44100, true)
            else
                v(audio, 20, 2, 44100)
            end

            -- remove the old one if it exists
            closure(t, k, nil)

            -- add it
            local len = setfunc(v)
            map[k] = len - 1
            storage[k] = v
        end
    end
    return closure
end

_G.raw.lua = setmetatable({}, {
    __index = luastorage,
    __newindex = genclosure(luamap, SET_MAIN, UNSET_MAIN, luastorage),
})

_G.raw.c = setmetatable({}, {
    __index = cstorage,
    __newindex = genclosure(cmap, C.eqe_filter_set_raw_c_no_lock, C.eqe_filter_unset_raw_c_no_lock, cstorage),
})

_G.IPCD = function(s)
    return DAEMON_IPC(s, true) or IPCD(s)
end

local serialize = require 'str_esc'
_G.IPCD_WRITE = function(filepath, contents)
    assert(type(filepath) == 'string')

    return IPCD([[
    local filepath = ]]..serialize(filepath)..[[
    local f = assert(io.open(filepath, 'w'))
    f:write([=[return ]]..serialize(contents)..[[]=])
    f:close()
    os.execute('chown mobile:mobile '..filepath)
    ]])
end

require 'autorun_loader'('raw')
