local filter = {}

function filter:new()
    local self = setmetatable({}, {__index=self})
    self.class = {}
    self.frequency = 0
    self.Q = 2
    return self
end

function filter:get_coefs(sample_rate, ...)
    if self.frequency == 0 or
       self.Q == 0 then return end

    sample_rate = sample_rate or eqe.sample_rate
    local omega = 2*math.pi*self.frequency/sample_rate
    local alpha = math.sin(omega) / (2*self.Q)

    return self:process(omega, alpha, ...)
end

return filter
