local super = Object
ns.target = Object.new(super)

local newmproxy -- forward decl

local flags = {}
function ns.target:new()
    local self = super.new(self)

    self.m = self.class:alloc():init()
    objc.ref(self.m, self)

    return self
end

function ns.target:onaction()
end

local class = objc.GenerateClass()
ns.target.class = class
ns.target.sel = objc.SEL('doItLololol:')

function class.dealloc(m)
    objc.unref(m)
    objc.callsuper(m, 'dealloc')
end
objc.addmethod(class, ns.target.sel, function(m, ...)
    local self = objc.getref(m)
    self:onaction(...)
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')

return ns.target
