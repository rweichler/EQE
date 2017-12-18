local object = {}

function object:new()
    return setmetatable({}, {__index = self})
end

return object
