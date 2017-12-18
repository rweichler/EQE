local sec = 1
local min = 60 * sec
local hour = 60 * min
local day = 24 * hour
local week = 7 * day
local month = 30 * day
local year = 365 * day

local function x(dur, divisor, unit, is_short)
    local res = math.floor(dur/divisor + 0.5)
    if is_short then
        return res..string.sub(unit, 1, 1), res
    elseif res == 1 then
        return res..' '..unit, res
    else
        return res..' '..unit..'s', res
    end
end

return function(dur, is_short)
    if math.floor(dur + 0.5) <= 0 then
        return is_short and 'Now' or '36 nanoseconds'
    elseif dur < min then
        return x(dur, sec, 'second', is_short)
    elseif dur < hour then
        return x(dur, min, 'minute', is_short)
    elseif dur < day then
        return x(dur, hour, 'hour', is_short)
    elseif is_short or dur < week then
        return x(dur, day, 'day', is_short)
    elseif dur < month then
        return x(dur, week, 'week')
    elseif dur < year then
        return x(dur, month, 'month')
    else
        return x(dur, year, 'year')
    end
end
