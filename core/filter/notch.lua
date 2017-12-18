local super = require 'filter/base'
local filter = super:new()

function filter:process(omega, alpha)
    local a0 = 1 + alpha
    local omegaC = math.cos(omega)

    return
        1               / a0, --b0
        (-2 * omegaC)   / a0, --b1
        1               / a0, --b2
        (-2 * omegaC)   / a0, --a1
        (1 - alpha)     / a0  --a2
end

return filter
