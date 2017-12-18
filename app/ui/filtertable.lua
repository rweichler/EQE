local super = ui.table
ui.filtertable = Object.new(super)

function ui.filtertable:new()
    local self = super.new(self)
    self.searchbar = ui.searchbar:new()
    self.searchbar.m:setFrame{{0,0},{SCREEN.WIDTH,44}}
    self.m:setTableHeaderView(self.searchbar.m)
    function self.searchbar.ontextchange(_, text)
        self:updatefilter(text)
        self:refresh(true)
    end
    return self
end

function ui.filtertable:list()
    if self.filtered then
        if self.lastfiltered == self.deblist then
            return self.filtered
        else
            self.filtered = nil
        end
    end
    self.lastfiltered = nil
    return self.deblist
end

function ui.filtertable:filter(t)
    self.filtered = t
    if self.filtered then
        self.lastfiltered = self.deblist
    else
        self.lastfiltered = nil
    end
end

function ui.filtertable:updatefilter(text)
    text = text or (self.searchbar and objc.tolua(self.searchbar.m:text() or '') or '')
    if text == '' then
        self:filter(nil)
    elseif self.deblist then
        local t = {}
        for k,v in pairs(self.deblist) do
            if self:search(text, v) then
                t[#t + 1] = v
            end
        end
        self:filter(t)
    end
end

function ui.filtertable:search(text, item)
    return true
end

function ui.filtertable:refresh(skipupdate)
    self.items[1] = self:list() or self.items[1]
    if not skipupdate then
        self:updatefilter()
    end
    super.refresh(self)
end

function ui.filtertable:onscroll()
    super.onscroll(self)
    self.searchbar.m:resignFirstResponder()
end

return ui.filtertable
