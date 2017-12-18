PRESET_FOLDER = '/var/tweak/com.r333d.eqe/db/presets'
function preset_file(name)
    name = name or 'CURRENT_BANDS'
    return PRESET_FOLDER..'/'..name..'.lua'
end

local function list(folder, ignore)
    local t = ls(folder)
    local s = ''
    for k,v in pairs(t) do
        if not(v == ignore) and string.sub(v, #v - 3, #v) == '.lua' then
            s = s..string.sub(v, 1, #v - 4)

            if next(t, k) then
                s = s ..'\n'
            end
        end
    end
    return s
end

function presetlist()
    return list(PRESET_FOLDER, 'CURRENT_BANDS.lua')
end

function bandlist()
    return list(LUA_PATH..'/filter', 'base')
end
local esc = require 'str_esc'

function eqe.save(name)
    name = name and string.gsub(name, '%/', '\\')
    local path = preset_file(name)
    local f = io.open(path, 'w')
    f:write('return {\n')
    f:write('    {\n')
    f:write('        name = "preamp",\n')
    f:write('        gain = '..eqe.preamp..',\n')
    f:write('    },\n')
    for i=1,#eqe do
        local filter = eqe[i]
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
    f:close()
    DAEMON_IPC('UPDATE_PRESET('..esc(name or 'CURRENT_BANDS')..','..esc(path)..')')
end

function eqe.load(name, target)
    target = target or eqe
    local f = loadfile(preset_file(name))
    setfenv(f, {}) -- prevent "heres my preset" OSHIT PWNED situations
    local t = f()
    -- clear all bands
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
    if target == eqe then
        eqe.update()
    end
    if name then
        eqe.save()
    end
    return target
end

function eqe.flatten()
    local n = #eqe
    for i=1,n do
        eqe[#eqe] = nil
    end
    eqe.preamp = 0
end
