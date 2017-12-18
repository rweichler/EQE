local super = require 'filter/base'
local filter = super:new()

function filter:process(omega, alpha)
    local omegaC = math.cos(omega)
    local a0, b0, b1, b2, a1, a2


    a0 = 1 + alpha
    b0 = alpha                  / a0
    b1 = 0                      / a0
    b2 = (-1 * alpha)           / a0
    a1 = (-2 * omegaC)          / a0
    a2 = (1 - alpha)            / a0

    return
        b0,
        b1,
        b2,
        a1,
        a2
end

return filter
