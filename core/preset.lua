PRESET_FOLDER = '/var/tweak/com.r333d.eqe/db/presets'
function preset_file(name)
    name = name or 'CURRENT_BANDS'
    return PRESET_FOLDER..'/'..name..'.lua'
end

local function list(folder, ignore, should_return_table)
    local t = ls(folder)
    local r = should_return_table and {} or ''
    for k,v in pairs(t) do
        if not(v == ignore) and string.sub(v, #v - 3, #v) == '.lua' then
            v = string.sub(v, 1, #v - 4)

            if should_return_table then
                table.insert(r, v)
            else
                r = r..v..'\n'
            end
        end
    end
    return r
end

function presetlist(should_return_table)
    return list(PRESET_FOLDER, 'CURRENT_BANDS.lua', should_return_table)
end

function bandlist(should_return_table)
    return list(LUA_PATH..'/filter', 'base', should_return_table)
end
local esc = require 'str_esc'

function eqe.save(name, input)
    input = input or eqe
    name = name and string.gsub(name, '%/', '\\')

    local path = preset_file(name)
    local f = io.open(path, 'w')
    f:write('return {\n')
    f:write('    {\n')
    f:write('        name = "preamp",\n')
    f:write('        gain = '..input.preamp..',\n')
    f:write('    },\n')
    for i=1,#input do
        local filter = input[i]
        f:write('    {\n')
        f:write('        name = "'..filter.name..'",\n')
        f:write('        frequency = '..filter.frequency..',\n')
        f:write('        Q = '..filter.Q..',\n')
        if filter.gain then
            f:write('        gain = '..filter.gain..',\n')
        end
        if filter.channel then
            f:write('        channel = '..filter.channel..',\n')
        end
        f:write('    },\n')
    end
    f:write('}')
    if not name and input == eqe and next(eqe.attr) then
        f:write(', ')
        f:write(esc(eqe.attr))
    end
    f:close()
    DAEMON_IPC('UPDATE_PRESET('..esc(name or 'CURRENT_BANDS')..','..esc(path)..')')
end

function eqe.load(name, target)
    target = target or eqe
    local f = loadfile(preset_file(name))
    setfenv(f, {}) -- prevent "heres my preset" OSHIT PWNED situations
    local t, attr = f()
    -- clear all bands
    if target == eqe then
        local to_insert = {}
        for k,info in pairs(t) do
            if info.name == 'preamp' then
                eqe.preamp = info.gain
            else
                local filter = filters[info.name]
                for k,v in pairs(info) do
                    filter[k] = v
                end
                table.insert(to_insert, filter)
            end
        end
        if attr then
            for k,v in pairs(attr) do
                eqe.attr[k] = v
            end
        end
        eqe.insert(nil, to_insert, true)
        eqe.update()
        if name then
            eqe.save()
        end
    else
        local n = #target
        for i=1,n do
            target[#target] = nil
        end
        target.preamp = 0
        for _,info in pairs(t) do
            if info.name == 'preamp' then
                target.preamp = info.gain
            else
                local filter = filters[info.name]
                for k,v in pairs(info) do
                    filter[k] = v
                end
                target[#target + 1] = filter
            end
        end
    end
    return target
end
