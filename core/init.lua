if jit.arch == 'arm64' then
    jit.off()
end

package.path = LUA_PATH..'/?.lua;'..
               LUA_PATH..'/?/init.lua;'..
               LUA_PATH..'/../common/?.lua;'..
               LUA_PATH..'/../common/?/init.lua;'..
               package.path
ffi = require 'ffi'
C = ffi.C
eqe = {}
require 'util'
require 'preset'
require 'eqe'

function IPCD(s)
    return DAEMON_IPC(s, true) or IPCD(s)
end

-- load config, if its there
local success = pcall(require, 'config')

if not success then
    require 'default_config'
end

require 'autorun_loader'('core')
