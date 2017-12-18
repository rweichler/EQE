ffi.cdef[[
typedef void DIR;
DIR *opendir(const char *);
int closedir(DIR *dirp);
]]

ls = require 'ls'

_G.ANIMATE = function(arg1, arg2, arg3, arg4, arg5)
    local duration = 0.2
    local delay = 0
    local options = UIViewAnimationOptionCurveEaseInOut
    local canim, ccomp
    local animations
    local complete
    local completion = function(finished)
        if complete then complete() end
        canim:free()
        ccomp:free()
    end
    if type(arg1) == 'table' then
        duration = arg1.duration or duration
        delay = arg1.delay or delay
        options = arg1.options or options
        animations = arg1.animations or animations
    elseif not arg2 and not arg3 then
        animations = arg1
    elseif not arg3 then
        duration = arg1
        animations = arg2
    elseif type(arg3) == 'function' and type(arg4) == 'function' then
        duration = arg1
        delay = arg2
        animations = arg3
        complete = arg4
    elseif not arg4 then
        duration = arg1
        delay = arg2
        animations = arg3
    else
        duration, delay, options, animations = arg1, arg2, arg3, arg4
    end
    canim = ffi.cast('void (*)()', animations)
    ccomp = ffi.cast('void (*)(bool)', completion)
    C.animateit(duration, delay, options, canim, ccomp)
end

function isdir(path)
    local dir = C.opendir(path)
    if dir == ffi.NULL then
        return false
    else
        C.closedir(dir)
        return true
    end
end
function os.capture(cmd, noerr)
    local f
    if noerr then
        f = assert(io.open(cmd, 'r'))
    else
        f = assert(io.popen(cmd..' 2>&1', 'r'))
    end
    local s = assert(f:read('*a'))
    local rc = {f:close()}
    return string.sub(s, 1, #s - 1), rc[3]
end

function os.setuid(cmd)
    local f = io.popen(APP_PATH..'/setuid /usr/bin/env '..cmd..' 2>&1', 'r')
    local s = f:read('*a')
    local rc = {f:close()}
    return s, rc[3]
end


local fs = {}
fs.WIDTH = function()
    return objc.UIScreen:mainScreen():bounds().size.width
end
fs.HEIGHT = function()
    return objc.UIScreen:mainScreen():bounds().size.height
end

_G.SCREEN = setmetatable({}, {
    __index = function(t, k)
        local f = fs[k]
        if f then return f() end
    end,
})
