-- this is loaded if config.lua doesn't exist, or if config.lua errors

local f = io.open(preset_file(), 'r')
if not f then
    f = io.open(preset_file(), 'w')
    f:write('return {}')
end
f:close()
eqe.load()
