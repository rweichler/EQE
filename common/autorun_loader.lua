local ls = require 'ls'
local prefix = LUA_PATH..'/../autorun/'

return function(suffix)
    local dir = prefix..suffix
    for k,v in pairs(ls(dir)) do
        v = dir..'/'..v
        if string.sub(v, #v - 3, #v) == '.lua' then
            local success, err = pcall(dofile, v)
            if not success then
                print('ERROR loading autorun script ('..v..'):'..err)
            end
        end
    end
end
