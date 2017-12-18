local Object = {}

function Object:new()
    return setmetatable({}, {__index=self})
end

return Object
