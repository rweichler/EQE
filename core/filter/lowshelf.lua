local super = require 'filter/base/gain'
local filter = super:new()

function filter:process(omega, alpha, A)
    local omegaC = math.cos(omega)
    local omegaS = math.sin(omega)
    local beta = math.sqrt(A/self.Q)
    local a0, b0, b1, b2, a1, a2

    a0 = (A + 1) + ((A - 1) * omegaC) + (beta * omegaS)
    b0 = (A * ((A + 1) - ((A - 1) * omegaC) + (beta * omegaS)))     / a0
    b1 = (2 * A * ((A - 1 ) - ((A + 1) * omegaC)))                  / a0
    b2 = (A * ((A + 1) - ((A - 1) * omegaC) - (beta * omegaS)))     / a0
    a1 = (-2 * ((A - 1) + ((A + 1) * omegaC)))                      / a0
    a2 = ((A + 1) + ((A - 1) * omegaC) - (beta * omegaS))           / a0

    return
        b0,
        b1,
        b2,
        a1,
        a2
end

return filter
