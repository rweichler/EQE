-- this is just a wrapper around ncurses

local ffi = require 'ffi'

ffi.cdef[[
int usleep(unsigned int s);
]]
local ui = {}

local curses = require 'curses'
local dll = curses.dll
local scr = curses.stdscr()

ui.curses = curses
ui.dll = dll
ui.scr = scr


local used_colors = {}
local used_color_pairs = {}
for i=1,7 do
    used_colors[i] = true
end
local short_ptr = ffi.typeof("short[1]")
local function save_old_color(i)
    local r, g, b = ffi.new(short_ptr), ffi.new(short_ptr), ffi.new(short_ptr)
    dll.color_content(i, r, g, b)
    used_colors[i] = {r[0], g[0], b[0]}
    local f, b = r, g
    dll.pair_content(i, f, b)
    used_color_pairs[i] = {f[0], b[0]}
end
local function alloc_color(i)
    for i=1,dll.COLORS  do
        if not used_colors[i] then
            save_old_color(i)
            return i
        end
    end
    return curses.COLOR_WHITE
end

function ui.print(...)
    scr:printw(table.concat({...}, ', '))
end

function ui.free_color(i)
    if not used_colors[i] then return end
    if used_colors[i] == true then return end
    local color = used_colors[i]
    local r, g, b = unpack(color)
    dll.init_color(i, r, g, b)
    local color_pair = used_color_pairs[i]
    local f, b = unpack(color_pair)
    dll.init_pair(i, f, b)

    used_colors[i] = nil
    used_color_pairs[i] = nil
end

local function free_all_colors()
    for i=1,dll.COLORS do
        ui.free_color(i)
    end
end

local colorz = {}
local last_color = nil

local function preinit()
    dll.init_pair(3, curses.COLOR_BLACK, curses.COLOR_WHITE)
    dll.init_pair(4, curses.COLOR_WHITE, curses.COLOR_BLACK)
end

function ui.set_color(mode, r, g, b, i)
    if preinit then
        preinit()
        preinit = nil
    end
    local pair
    if mode == 'fill' then
        pair = 3
    else
        pair = 4
    end
    scr:attron(dll.COLOR_PAIR(pair))
    --[[
    local fetched = false
    if r and not g then
        i = r
        r, g, b = unpack(colorz[i])
        fetched = true
    end
    if not fetched then
        i = i or alloc_color()
        dll.init_color(i, r, g, b)
        colorz[i] = {r, g, b}
    end
    if mode == 'fill' then
        dll.init_pair(i, curses.COLOR_BLACK, i)
    elseif mode == 'text' then
        dll.init_pair(i, i, curses.COLOR_BLACK)
    else
        error('invalid mode')
    end
    if last_color then
        scr:attroff(dll.COLOR_PAIR(last_color))
    end
    scr:attron(dll.COLOR_PAIR(i))
    last_color = i
    return i
    ]]
end

function ui.set_fill_color(r, g, b, i)
    return ui.set_color('fill', r, g, b, i)
end

function ui.set_text_color(r, g, b, i)
    return ui.set_color('text', r, g, b, i)
end

function ui.reset_color()
    if last_color then
        scr:attroff(dll.COLOR_PAIR(last_color))
        last_color = nil
    end
end

function ui.rect(orig_x, orig_y, w, h)
    w = math.round(w)
    h = math.round(h)
    scr:move(orig_x, orig_y)
    for y=1, h do
        for x=1, w do
            scr:printw(' ')
        end
        scr:move(orig_x, orig_y + y)
    end
end

function ui.sleep(s)
    return ffi.C.usleep(math.floor(s*1000000))
end

function ui.get_key()
    return curses.convert_key(scr:getch())
end

local success, err, traceback
function ui.start()
    curses.initscr()
    curses.raw(true)
    curses.echo(false)
    scr:keypad(true)
    dll.start_color()
    dll.set_escdelay(25)
    success = xpcall(main, function(e)
        err = e
        traceback = debug.traceback()
    end)
    ui.suspend_quit = false
    ui.quit()
end

function ui.quit()
    if ui.suspend_quit then
        ui.wants_to_quit = true
        return
    end
    if last_color then
        scr:attroff(dll.COLOR_PAIR(last_color))
    end
    free_all_colors()
    curses.endwin()
    if not success then
        print("ERROR")
        print(err)
        --print("ERROR: "..err)
        print(traceback)
    end
    if onquit then
        onquit()
    end
end

local cursor_visible = true

local get = {}
function get.cursor_visible()
    return cursor_visible
end
local set = {}
function set.cursor_visible(v)
    assert(type(v) == 'boolean')
    cursor_visible = v
    dll.curs_set(v and 1 or 0)
end

setmetatable(ui, {
    __index = function(t, k)
        local get = get[k]
        if get then return get() end
    end,
    __newindex = function(t, k, v)
        local set = set[k]
        if set then
            return set(v)
        else
            rawset(t, k, v)
        end
    end
})

return ui
