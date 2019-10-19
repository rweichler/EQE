local prefix = LUA_PATH..'/../autorun/'

local function run(dir)
    for k,v in pairs(io.ls(dir) or {}) do
        v = dir..'/'..v
        if string.sub(v, #v - 3, #v) == '.lua' then
            dofile(v)
        end
    end
end

return function(suffix)
    run(LUA_PATH..'/autorun')
    run(prefix..suffix)
end
