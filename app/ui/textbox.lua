local super = Object
ui.textbox = Object.new(super)

function ui.textbox:new()
    local self = super.new(self)
    self.m = self.class:alloc():init()
    objc.ref(self.m, self)
    self.m:setDelegate(self.m)
    return self
end

function ui.textbox:onactive()
end

ui.textbox.class = objc.GenerateClass('UITextField')
local class = ui.textbox.class

function class:dealloc()
    objc.unref(self)
    objc.callsuper(self, 'dealloc')
end

objc.addmethod(class, 'textFieldDidBeginEditing:', function(self, field)
    local this = objc.getref(self)
    this:onactive()
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')


return ui.textbox
