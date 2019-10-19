package.path = LUA_PATH..'/?.lua;'..
               LUA_PATH..'/?/init.lua;'..
               LUA_PATH..'/../common/?.lua;'..
               LUA_PATH..'/../common/?/init.lua;'..
               package.path

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

dofile(LUA_PATH..'/crossfeed.lua')
dofile(LUA_PATH..'/compressor.lua')
