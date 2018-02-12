if jit.arch == 'arm64' then
    jit.off()
end

package.path = LUA_PATH..'/?.lua;'..
               LUA_PATH..'/?/init.lua;'..
               LUA_PATH..'/../common/?.lua;'..
               LUA_PATH..'/../common/?/init.lua;'..
               package.path

local ffi = require 'ffi'
local C = ffi.C
local objc = require 'objc'

if ffi.arch == 'arm64' then
    ffi.cdef'typedef double CGFloat;'
else
    ffi.cdef'typedef float CGFloat;'
end
ffi.cdef[[
typedef void* CGContextRef;
typedef void* CGPathRef;
typedef CGPathRef CGMutablePathRef;

struct CGPoint{
    CGFloat x;
    CGFloat y;
};
struct CGSize{
    CGFloat width;
    CGFloat height;
};
struct CGRect{
    struct CGPoint origin;
    struct CGSize size;
};
struct CGColor{};

struct plot_t {
    CGFloat x;
    CGFloat y;
};
void eqe_calculate_curve(struct plot_t *plot, size_t len, bool first, float a0, float a1, float a2, float b1, float b2);

CGContextRef UIGraphicsGetCurrentContext();
void CGContextSetLineWidth(CGContextRef context, CGFloat width);
void CGContextMoveToPoint(CGContextRef context, CGFloat x, CGFloat y);
void CGContextAddLineToPoint(CGContextRef context, CGFloat x, CGFloat y);
void CGContextStrokePath(CGContextRef context);

void CGContextSetStrokeColor(CGContextRef c, const CGFloat *components);
void CGContextSetRGBStrokeColor(CGContextRef c, CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
void CGContextSetStrokeColorWithColor(CGContextRef context, struct CGColor *color);
void CGContextSetFillColorWithColor(CGContextRef context, struct CGColor *color);
void CGContextFillRect(CGContextRef context, struct CGRect frame);

void CGContextSetLineJoin(CGContextRef, int32_t);
CGPathRef CGPathCreateMutable();
void CGPathMoveToPoint(CGPathRef path, void *idc, CGFloat x, CGFloat y);
void CGPathAddLineToPoint(CGPathRef path, void *idc, CGFloat x, CGFloat y);
void CGPathCloseSubpath(CGPathRef path);

void CGContextFillPath(CGContextRef context);
void CGContextAddPath(CGContextRef context, CGPathRef path);
void CGPathRelease(CGPathRef path);

void CGContextSaveGState(CGContextRef context);
void CGContextRestoreGState(CGContextRef context);
]]

local plot, WIDTH, HEIGHT, MAX, preamp, is_flat, plot_len

local function magplot(plot, coefs, len, first)
    local a0, a1, a2, b1, b2 = unpack(coefs)
    if not a0 then return end
    -- C is faster, the commented code does the same thing
    C.eqe_calculate_curve(plot, len, first, a0, a1, a2, b1, b2)
    --[[
    for i=0,len-1 do
        local w = math.exp(math.log(1/0.001) * i/(len-1))*0.001*math.pi
        local phi = math.pow(math.sin(w/2), 2)
        local y = math.log(math.pow(a0+a1+a2, 2) - 4*(a0*a1 + 4*a0*a2 + a1*a2)*phi + 16*a0*a2*phi*phi) - math.log(math.pow(1+b1+b2, 2) - 4*(b1 + 4*b2 + b1*b2)*phi + 16*b2*phi*phi)
        y = y * 10 / math.log(10)
        if y == -1/0 or y == 1/0 then
            y = -200
        end

        if first then
            plot[i].x = i / (len - 1) / 2
            plot[i].y = y
        else
            plot[i].y = plot[i].y + y
        end
    end
    ]]
end

function update_frequency_response(filters, pre, width, height)
    preamp = pre
    plot_len = math.floor(width/4)
    if not plot then
        plot = ffi.new('struct plot_t[?]', plot_len)
        ffi.fill(plot, ffi.sizeof(plot))
    end
    WIDTH = width
    HEIGHT = height
    MAX = 70
    is_flat = true
    for _, filter in pairs(filters) do
        magplot(plot, filter, plot_len, is_flat)
        is_flat = false
    end
end

local off = 140
local function transy(y)
    return off/2 - y*HEIGHT/MAX
end

local function transform(p)
    return p.x * WIDTH * 2, transy(p.y + preamp)
end

local current_frequency

local levels = {0.1, 1}

local function getrg(y)
    if y < 0.5 then -- green
        return y*2, 1
    elseif y > 0.5 then --red
        return 1, (1-y)*2
    else
        return 1, 1
    end
end

local function setcolor(context, y, scale)
    scale = scale or 20
    local r, g = getrg(y/scale + 0.5)
    C.CGContextSetRGBStrokeColor(context, r, g, 0, 1)
end

local function draw_0(context)
    C.CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.4)
    local max = 55
    local y = transy(0)
    for i=0,max do
        local x = i*WIDTH/max
        if i % 2 == 0 then
            C.CGContextMoveToPoint(context, x, y)
        else
            C.CGContextAddLineToPoint(context, x, y)
            C.CGContextStrokePath(context)
        end
    end
end

local kCGLineJoinRound = 1
function draw_frequency_response()
    -- i should probably write this in C
    if not plot then return end

    local context = C.UIGraphicsGetCurrentContext()
    C.CGContextSetLineJoin(context, kCGLineJoinRound)
    C.CGContextSetLineWidth(context, 1)

    draw_0(context)

    if is_flat then
        local y = transy(preamp)
        setcolor(context, preamp)
        C.CGContextMoveToPoint(context, 0, y)
        C.CGContextAddLineToPoint(context, WIDTH, y)
        C.CGContextStrokePath(context)
    else
        local lasty
        for i=0,plot_len-1 do
            local x, y = transform(plot[i])
            if lasty then
                C.CGContextAddLineToPoint(context, x, y)
                setcolor(context, (plot[i].y + lasty)/2 + preamp)
                C.CGContextStrokePath(context)
                lasty = nil
            end
            C.CGContextMoveToPoint(context, x, y)
            lasty = plot[i].y
        end
    end

    if current_frequency then
        local MIN_F, MAX_F = 20, 20000
        -- this formula is pretty hacky, i have no idea why it works D:
        local pos = WIDTH*math.log((current_frequency - MIN_F)*math.exp(6.75)/(MAX_F - MIN_F) + 1)/6.75

        local top, bottom = 66, off

        for i=1,#levels do
            local x = pos - (#levels - i)
            C.CGContextSetRGBStrokeColor(context, 1, 1, 1, levels[i])
            C.CGContextSetLineJoin(context, kCGLineJoinRound)
            C.CGContextSetLineWidth(context, 1)
            C.CGContextMoveToPoint(context, x, top)
            C.CGContextAddLineToPoint(context, x, bottom)
            C.CGContextMoveToPoint(context, x, bottom)
            C.CGContextStrokePath(context)

            if not(i == #levels) then
                local x = pos + (#levels - i)
                C.CGContextSetRGBStrokeColor(context, 1, 1, 1, levels[i])
                C.CGContextSetLineJoin(context, kCGLineJoinRound)
                C.CGContextSetLineWidth(context, 1)
                C.CGContextMoveToPoint(context, x, top)
                C.CGContextAddLineToPoint(context, x, bottom)
                C.CGContextMoveToPoint(context, x, bottom)
                C.CGContextStrokePath(context)
            end
        end
    end
end

function set_current_frequency(frequency)
    current_frequency = frequency
end
