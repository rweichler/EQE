local super = Object
ui.cell = Object.new(super)

local count = 0
function ui.cell:new()
    local self = super.new(self)
    self.identifier = objc.toobj('hax'..count):retain()
    count = count + 1
    return self
end

function ui.cell:getheight(section, row)
    return 44
end

function ui.cell:estimateheight(section, row)
    return self:getheight(section, row)
end

function ui.cell:onshow(m, section, row)
    if self.table.section then return end

    local o = self.table.items[section][row]
    m:textLabel():setText(tostring(o))
end

function ui.cell:onselect(section, row)
end

function ui.cell:mnew()
    local m = self.class:alloc():initWithStyle_reuseIdentifier(3, self.identifier)
    local self = setmetatable({}, {__index = self})
    self.m = m
    objc.ref(m, self)

    m:textLabel():setTextColor(objc.UIColor:whiteColor())
    m:textLabel():setBackgroundColor(objc.UIColor:clearColor())
    m:detailTextLabel():setTextColor(objc.UIColor:whiteColor())
    m:detailTextLabel():setBackgroundColor(objc.UIColor:clearColor())

    m:setBackgroundColor(objc.UIColor:clearColor())

    return m
end

function ui.cell:gotcell(section, row)
end

function ui.cell:dealloc()
end

ui.cell.class = objc.GenerateClass('UITableViewCell')
local class = ui.cell.class

function class.dealloc(m)
    objc.getref(m):dealloc()
    objc.unref(m)
    objc.callsuper(m, 'dealloc')
end

return ui.cell
