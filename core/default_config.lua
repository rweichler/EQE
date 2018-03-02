-- this is loaded if config.lua doesn't exist, or if config.lua errors
local esc = require 'str_esc'

local f = io.open(preset_file(), 'r')
if not f then
    local s = 'WRITE_FILE('..esc(preset_file())..','..esc('return {}')..')'
    print(s)
    print(IPCD(s))
else
    f:close()
end
eqe.load()
