-- if you're reading this code for the first time,
-- look in window.lua

if jit.arch == 'arm64' then
    jit.off()
end

package.path = package.path..';'..LUA_PATH..'/?.lua;'..LUA_PATH..'/?/init.lua'
require 'util'

step = 1

local ui = require 'ui'
local eqe = require 'eqe'
local window = require 'window'

function main()
    ui.cursor_visible = false
    ui.suspend_quit = true
    while not ui.wants_to_quit do
        window.draw()
        local key = ui.get_key()
        keypress(key)
    end
    ui.suspend_quit = false
end

local old_print = print
local print_after = {}
function onquit()
    print = old_print

    for i,v in ipairs(print_after) do
        print(table.concat(v, ', '))
    end
end

setting = nil
local has_decimal = false

filter_type = 'eq'

local function get_current_band()
    return eqe[window.selected - 1]
end

function keypress(key)
    if HELP_MODE then
        if key == 'esc' or key == 'h' then
            HELP_MODE = false
            ui.scr:clear()
        end
        return
    end
    if PRESET_MODE and (key == 'esc' or key == 'p' or key == 'enter') then
        if key == 'enter' then
            if window.selected == 1 then
                -- save
                setting = {name = 'Preset name', val = '', input = 'txt'}
                setting.target = function(val)
                    if val then
                        ipc('eqe.save[['..val..']]')
                    end
                end
            else
                -- load
                local presetlist = ipc('return presetlist()')
                local i = 1
                local sep = '\n'
                for preset in string.gmatch(presetlist, "([^"..sep.."]+)") do
                    i = i + 1
                    if i == window.selected then
                        ipc('eqe.load([['..preset..']])')
                        break
                    end
                end
            end
        end
        PRESET_MODE = false
        window.selected = 1
        ui.scr:clear()
        return
    end
    if not PRESET_MODE and (not setting or not(setting.input == 'txt')) then
        if window.selected > 1 then
            if key == 'f' then
                setting = {name = 'frequency', val = '', target = get_current_band}
                return
            elseif key == 'q' then
                setting = {name = 'Q', title = 'Q factor', val = '', target = get_current_band}
                return
            end
        end
        if key == 't' then
            setting = {name = 'filter_type', val = '', input = 'txt', target = function() return _G end}
            return
        elseif key == 'g' and (window.selected == 1 or get_current_band().gain) then
            if window.selected == 1 then
                setting = {name = 'preamp', val = '', target = function(val) if val then ipc('eqe.preamp = '..val) else return {preamp = ipc('return eqe.preamp')} end end}
            else
                setting = {name = 'gain', val = '', target = get_current_band}
            end
            return
        elseif key == 's' then
            setting = {name = 'step', val = '', target = function() return _G end}
            return
        elseif key == 'h' then
            HELP_MODE = true
            ui.scr:clear()
        elseif key == 'p' then
            PRESET_MODE = true
            window.selected = 1
            ui.scr:clear()
        end
    end
    if setting then
        local num = string.byte(key) - string.byte('0')
        if key == 'esc' then
            key = 'enter'
            setting = nil
        end
        if key == 'enter' then
            if setting and not(#setting.val == 0 or setting.val == '.') then
                local target = setting.target(setting.val)
                if target then
                    if setting.input == 'txt' then
                        target[setting.name] = setting.val
                    else
                        target[setting.name] = tonumber(setting.val)
                    end
                end
            end
            setting = nil
            has_decimal = false
            ipc('eqe.save()')
        elseif key == 'backspace' then
            setting.val = string.sub(setting.val, 1, #setting.val - 1)
        elseif #key == 1 then
            if setting.input == 'txt' then
                setting.val = setting.val..key
            else
                if not has_decimal and key == '.' then
                    setting.val = setting.val..key
                    has_decimal = true
                elseif num >= 0 and num <= 9 then
                    setting.val = setting.val..key
                elseif key == '-' and #setting.val == 0 then
                    setting.val = setting.val..key
                end
            end
        end
        return
    end

    if key == 'esc' then
        return ui.quit()
    end

    if key == 'down' then
        window.selected = window.selected + 1
        if PRESET_MODE then
            if window.selected > presetlist_count() + 1 then
                window.selected = 1
            end
        elseif window.selected > #eqe + 1 then
            window.selected = 1
        end
    elseif key == 'up' then
        window.selected = window.selected - 1
        if window.selected < 1 then
            if PRESET_MODE then
                window.selected = presetlist_count() + 1
            else
                window.selected = #eqe + 1
            end
        end
    elseif not PRESET_MODE then
        if key == 'left' or key == 'right' then
            local delta = key == 'left' and -1 or 1
            delta = delta * step
            if window.selected == 1 then
                --preamp
                ipc('eqe.preamp = eqe.preamp + ('..delta..')')
            else
                local band = get_current_band()
                if band and band.gain then
                    band.gain = band.gain + delta
                end
            end
            ipc('eqe.save()')
        elseif key == 'n' then
            ipc("eqe[#eqe + 1] = filters[ [["..filter_type.."]] ]; eqe.save()")
            window.selected = #eqe + 1
            ipc('eqe.save()')
        elseif key == 'x' then
            local size = #eqe + 1
            if window.selected > 1 and size > 0 then
                ipc("eqe["..(window.selected - 1).."] = nil; eqe.save()")
                size = size - 1
                if window.selected > size then
                    window.selected = size
                end
            end
        end
    end
end

function print(...)
    local n = select('#', ...)
    local t = {...}
    for i=1,n do
        t[i] = tostring(t[i])
    end
    if #t == 0 then
        t[1] = 'nil'
    end
    table.insert(print_after, t)
end

ui.start()
