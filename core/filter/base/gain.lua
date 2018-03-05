local super = require 'filter/base'
local filter = super:new()


function filter:new()
    local self = super.new(self)
    getmetatable(self).__newindex = nil
    self.class.gain = true
    self.gain = 0
    return self
end

function filter:get_coefs(sample_rate, ...)
    if self.gain == 0 then return end

    local A = math.sqrt(10^(self.gain/20))

    return super.get_coefs(self, sample_rate, A, ...)
end

return filter
