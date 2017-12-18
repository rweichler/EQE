local str_esc = require 'str_esc'


local sesh = {}

sesh.default_path = LUA_PATH..'/../common/config/default/sesh.lua'
sesh.path = '/var/tweak/com.r333d.eqe/db/sesh.lua'

function sesh.read()
    local success, result = pcall(dofile, sesh.path)
    if success then
        sesh.data = result
    else
        sesh.data = dofile(sesh.default_path)
    end
    return sesh.data
end

function sesh.write(data)
    local s
    if data == nil then
        s = 'nil'
    elseif type(data) == 'string' then
        s = str_esc(data)
    else
        error('unexpected type '..type(data))
    end

    sesh.data = data

    local f = io.open(sesh.path, 'w')
    f:write('return '..s)
    f:close()
end

sesh.read()
return sesh
