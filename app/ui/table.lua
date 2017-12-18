local super = Object
ui.table = Object.new(super)

function ui.table:new()
    local self = super.new(self)
    self.m = self.class:alloc():init()
    objc.ref(self.m, self)
    self.m:setDelegate(self.m)
    self.m:setDataSource(self.m)
    self.items = {}
    self.cell = ui.cell:new()
    self.cell_cache = {}

    self.m:setBackgroundColor(objc.EQEMainView:themeColor())
    self.m:setSeparatorColor(objc.UIColor:clearColor())

    return self
end

function ui.table:init()
end

function ui.table:caneditcell(section, row)
    return false
end

function ui.table:editcell(section, row, style)
end

function ui.table:getmcell(section, row)
    local indexPath = objc.NSIndexPath:indexPathForRow_inSection(row-1, section-1)
    return self.m:cellForRowAtIndexPath(indexPath) or error 'wtf'
end

function ui.table:refresh()
    self.m:reloadData()
    self:onupdate()
end

local function ipath(row, section)
    section = section or 1
    return objc.NSIndexPath:indexPathForRow_inSection(row - 1, section - 1)
end
local function convert_rows(rows)
    if type(rows) == 'number' then
        rows = {rows}
    end
    for i=1,#rows do
        rows[i] = ipath(rows[i])
    end
    return rows
end

function ui.table:insert(rows, anim)
    rows = convert_rows(rows)
    anim = anim or UITableViewRowAnimationNone

    self.m:insertRowsAtIndexPaths_withRowAnimation(rows, anim)
    self:onupdate()
end

function ui.table:reload(rows, anim)
    rows = convert_rows(rows)
    anim = anim or UITableViewRowAnimationNone

    self.m:reloadRowsAtIndexPaths_withRowAnimation(rows, anim)
    self:onupdate()
end

function ui.table:scrollto(row, animated)
    row = ipath(row)
    animated = animated or false

    self.m:scrollToRowAtIndexPath_atScrollPosition_animated(row, UITableViewScrollPositionTop, animated)
end

function ui.table:getcell(section, row)
    if self.cell then
        self.cell.table = self
        return self.cell
    else
        error('wat??')
    end
end

function ui.table:onupdate()
end

function ui.table:onscroll()
end

function ui.table:endscroll()
end

function ui.table:enddrag()
end

function ui.table:dealloc()
    for i,v in ipairs(self.cell_cache) do
        v:release()
    end
end

ui.table.class = objc.GenerateClass('UITableView', 'UITableViewDelegate', 'UITableViewDataSource', 'UIScrollViewDelegate')
local class = ui.table.class

function class:dealloc()
    objc.getref(self):dealloc()
    objc.unref(self)
    objc.callsuper(self, 'dealloc')
end

function class:tableView_didSelectRowAtIndexPath(tableView, indexPath)
    local this = objc.getref(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    cell:onselect(section, row)

    tableView:deselectRowAtIndexPath_animated(indexPath, true)

end

function class:tableView_heightForRowAtIndexPath(tableView, indexPath)
    local this = objc.getref(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    return cell:getheight(section, row)
end

function class:tableView_estimatedHeightForRowAtIndexPath(tableView, indexPath)
    local this = objc.getref(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    return cell:estimateheight(section, row)
end

function class:tableView_numberOfRowsInSection(tableView, section)
    local this = objc.getref(self)
    local section = tonumber(section) + 1

    if this.section then
        return this.section[section]
    else
        return #this.items[section]
    end
end

function class:numberOfSectionsInTableView(tableView)
    local this = objc.getref(self)

    if this.section then
        return #this.section
    else
        return #this.items
    end
end

function class:scrollViewDidScroll(scrollView)
    local this = objc.getref(self)
    this.scrolling = true
    this:onscroll()
end

function class:scrollViewDidEndDecelerating(scrollView)
    local this = objc.getref(self)
    this.scrolling = false
    this:endscroll()
end
function class:scrollViewDidEndDragging_willDecelerate(scrollView, decelerating)
    if type(decelerating) == 'number' then
        decelerating = decelerating ~= 0
    end
    local this = objc.getref(self)
    this.dragging = false
    if not decelerating then
        this.scrolling = false
    end
    this:enddrag()
    if not decelerating then
        this:endscroll()
    end
end

function class:scrollViewWillBeginDragging(scrollView)
    local this = objc.getref(self)
    this.dragging = true
    this:onscroll(true)
end

function class:tableView_cellForRowAtIndexPath(tableView, indexPath)
    local this = objc.getref(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    local m = tableView:dequeueReusableCellWithIdentifier(cell.identifier)
    if m == ffi.NULL then
        m = cell:mnew()
        table.insert(this.cell_cache, m)
    end

    cell:gotcell(m, section, row)

    return m
end

function class:tableView_willDisplayCell_forRowAtIndexPath(tableView, mcell, indexPath)
    local this = objc.getref(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    local cell = this:getcell(section, row)
    cell:onshow(mcell, section, row)
end

function class:tableView_canEditRowAtIndexPath(tableView, indexPath)
    local this = objc.getref(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    if this:caneditcell(section, row) then
        return true
    else
        return false
    end
end

objc.addmethod(class, 'tableView:commitEditingStyle:forRowAtIndexPath:', function(self, tableView, style, indexPath)
    local this = objc.getref(self)
    local section, row = tonumber(indexPath:section()) + 1, tonumber(indexPath:row()) + 1

    this:editcell(section, row, style)
end, ffi.arch == 'arm64' and 'v40@0:8@16q24@32' or 'v20@0:4@8i12@16')

return ui.table
