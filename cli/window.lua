local ui = require 'ui'
local eqe = require 'eqe'
local window = {}

local function color_from_percent(percent)
    if percent < 0 then
        percent = 0
    elseif percent > 1 then
        percent = 1
    end
    percent = 1 - percent

    if percent <= 1/6 then
        percent = percent*6
        return 600 + 400*percent, 0, 0
    elseif percent <= 0.5 then
        percent = (percent - 1/6)/(0.5 - 1/6)
        return 1000, 1000*percent, 0
    else
        percent = (percent - 0.5)/0.5
        return 1000*(1-percent), 1000, 0
    end
end

local band_fill_colors = {}
local band_text_colors = {}

local start_x = 15
local start_y = 0

window.selected = 1

local max_color_size = 12
local function get_max_size()
    return tonumber(ipc([[
        local max = ]]..max_color_size..[[
        for i=1,#eqe do
            local gain = math.abs(eqe[i].gain or 0)
            if gain > max then
                max = gain
            end
        end
        if math.abs(eqe.preamp) > max then
            max = math.abs(eqe.preamp)
        end
        return max
    ]]))
end

local BLUE, PURPLE

local function clear_artifacts(x, y, w, h)
    ui.reset_color()
    ui.rect(0, y, x, 1)
    ui.rect(x + w, y, ui.curses.cols() - (x + w) + 1, 1)
end

local helptext = [[
h: open/close this menu
esc: quit
n: create band
x: delete band
up/down: select band
left/right: change gain
s: set step (how much left/right changes gain)
g: set gain
f: set frequency
q: set Q factor
p: open/close preset menu
t: set band type (this will be applied to every band created afterward)
    available types:
    eq (default)
    allpass
    lowshelf
    bandpass
    bandpassqpeakgain
    highshelf
    lowpass
    highpass
    notch
]]

function window.draw()
    ui.scr:move(0, 0)
    ui.reset_color()
    if PRESET_MODE then
        ui.print('::: PRESETS :::\nup/down to choose an option, enter to select, esc/p to escape\n\n')
        if window.selected == 1 then
            ui.print('---> ')
        else
            ui.print('     ')
        end
        ui.print('Save new preset\n\n')
        local presetlist = ipc('return presetlist()')
        local i = 1
        local sep = '\n'
        for preset in string.gmatch(presetlist, "([^"..sep.."]+)") do
            i = i + 1
            if i == window.selected then
                ui.print('---> ')
            else
                ui.print('     ')
            end
            ui.print(preset)
            ui.print('\n')
        end
    elseif HELP_MODE then
        ui.print(helptext)
    else
        window.draw_bands()
    end
end

local preampband = {pretty_frequency = function() return 'Preamp' end, pretty_gain = function(self) return self.gain..' dB' end}
function window.draw_bands()
    local max_size = get_max_size()
    local len = #eqe
    local max_width = (ui.curses.cols() - start_x*2)
    for i=1, len + 2 do
        local band
        if i == 1 then
            band = preampband
            band.gain = tonumber(ipc('return eqe.preamp'))
        else
            band = eqe[i - 1]
        end
        local x, w
        local y = start_y + i
        local h = 1
        if i == len + 2 then
            -- clear the bottom most one, in case if we just deleted a band
            -- TODO make this not a shitty hack
            ui.reset_color()
            ui.rect(0, y, ui.curses.cols(), h)
            break
        end
        local left_bound
        local inside_bar
        if band.gain then
            local percent = (band.gain + max_size)/(max_size*2)
            local color_percent = (band.gain + max_color_size)/(max_color_size*2)

            local anchor = percent * max_width

            x = start_x + (anchor < max_width/2 and anchor or max_width/2)
            if anchor < max_width/2 then
                w = max_width/2 - anchor
            else
                w = anchor - max_width/2
            end

            clear_artifacts(x, y, w, h)

            -- start drawing stuff
            local r, g, b = color_from_percent(color_percent)
            band_fill_colors[i] = ui.set_fill_color(r, g, b, band_fill_colors[i])
            ui.rect(x, y, w, h)
            local gain = band:pretty_gain()
            inside_bar = w >= #gain
            if inside_bar then
                ui.scr:move(x + (w - #gain)/2, y)
                ui.print(gain)
                left_bound = x
            else
                band_text_colors[i] = ui.set_text_color(r, g, b, band_text_colors[i])
                ui.scr:move(x - #gain - 1, y)
                ui.print(gain..' ')
                left_bound = x - #gain - 1
            end
        else
            x = start_x + max_width/2
            left_bound = x
            w = 1
            clear_artifacts(x, y, w, h)
            BLUE = ui.set_fill_color(200, 200, 900, BLUE)
            ui.rect(x, y, w, h)
        end

        local txt = band.Q and band.Q..(inside_bar and 'Q ' or 'Q, ') or ''
        left_bound = left_bound - #txt
        ui.scr:move(left_bound, y)
        PURPLE = ui.set_text_color(600, 100, 1000, PURPLE)
        ui.print(txt)

        ui.reset_color()
        if i == window.selected then
            left_bound = left_bound - 4
            ui.scr:move(left_bound, y)
            ui.print("--> ")
        end
        ui.scr:move(x + w, y)
        ui.print(' '..band:pretty_frequency())
    end
    ui.reset_color()
    ui.scr:move(0, 0)
    local txt
    if setting then
        txt = (setting.title or setting.name)..(setting.target() and (' ('..(setting.target()[setting.name])..'): ') or ': ')..setting.val..'_'
    else
        txt = 'Press h for help'
    end
    ui.print(txt)
    ui.rect(#txt, 0, ui.curses.cols() - #txt, 1)
end

return window
