local super = Object
ui.scroll = Object.new(super)

function ui.scroll:new()
    local self = super.new(self)
    self.m = self.class:alloc():init()
    objc.ref(self.m, self)
    self.m:setDelegate(self.m)
    return self
end

function ui.scroll:onscroll(x, y)
end

function ui.scroll:csize(w, h)
    if not w then
        local siz = self.m:contentSize()
        return siz.width, siz.height
    elseif not h then
        self.m:setContentSize(w)
    else
        return self.m:setContentSize{w, h}
    end
end

ui.scroll.class = objc.GenerateClass('UIScrollView<UIScrollViewDelegate>')
local class = ui.scroll.class

function class:dealloc()
    objc.unref(self)
    objc.callsuper(self, 'dealloc')
end

function class:scrollViewDidScroll(scrollView)
    local this = objc.getref(self)
    this:onscroll(self:contentOffset().x, self:contentOffset().y)
end

return ui.scroll
