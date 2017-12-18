local super = Object
ui.searchbar = Object.new(super)

function ui.searchbar:new()
    local self = super.new(self)
    self.m = self.class:alloc():init()
    objc.ref(self.m, self)
    self.m:setDelegate(self.m)
    return self
end

function ui.searchbar:ontextchange(text)
end

function ui.searchbar:onsearch()
end

function ui.searchbar:oncancel()
end

ui.searchbar.class = objc.GenerateClass('UISearchBar')
local class = ui.searchbar.class

function class:dealloc()
    objc.unref(self)
    objc.callsuper(self, 'dealloc')
end

objc.addmethod(class, 'searchBar:textDidChange:', function(self, searchBar, text)
    local this = objc.getref(self)

    text = objc.tolua(text)
    this:ontextchange(text)
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')

objc.addmethod(class, 'searchBarSearchButtonClicked:', function(self, searchBar)
    local this = objc.getref(self)
    searchBar:resignFirstResponder()
    this:onsearch()
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')

objc.addmethod(class, 'searchBarTextDidBeginEditing:', function(self, searchBar)
    local this = objc.getref(self)
    searchBar:setShowsCancelButton_animated(true, true)
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')

objc.addmethod(class, 'searchBarTextDidEndEditing:', function(self, searchBar)
    local this = objc.getref(self)
    searchBar:setShowsCancelButton_animated(false, true)
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')

objc.addmethod(class, 'searchBarCancelButtonClicked:', function(self, searchBar)
    local this = objc.getref(self)
    searchBar:resignFirstResponder()
    this:oncancel()
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')

return ui.searchbar
