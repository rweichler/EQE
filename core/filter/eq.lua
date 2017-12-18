local super = require 'filter/base/gain'
local filter = super:new()

function filter:process(omega, alpha, A)
    local a0 = 1 + alpha/A
    local omegaC = math.cos(omega)

    return
        (1 + alpha*A) / a0, --b0
        (-2 * omegaC) / a0, --b1
        (1 - alpha*A) / a0, --b2
        (-2 * omegaC) / a0, --a1
        (1 - alpha/A) / a0  --a2
end

return filter
