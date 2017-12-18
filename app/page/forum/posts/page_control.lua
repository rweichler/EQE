local pwidth = 130
local pheight = 30
local theight = 350
local pad = 44
local radius = 10

return function(m)
    local self = {}

    local page_hidden_frame = ffi.new('CGRect', {
        m:view():frame().size.width - pwidth - pad,
        m:view():frame().size.height
    }, {
        pwidth,
        theight + radius
    })

    local page_visible_frame = ffi.new('CGRect', page_hidden_frame)
    page_visible_frame.origin.y = page_hidden_frame.origin.y - pheight
    local page_table_frame = ffi.new('CGRect', page_hidden_frame)
    page_table_frame.origin.y = page_hidden_frame.origin.y - theight

    self.m = objc.UIView:alloc():initWithFrame(page_hidden_frame)
    self.m:layer():setCornerRadius(radius)
    self.m:layer():setBorderWidth(1)
    self.m:setBackgroundColor(COLOR(0x222222d2))
    self.m:layer():setBorderColor(COLOR(0xffffff1a):CGColor())
    self.m:setClipsToBounds(true)

    self.button = ui.button:new()
    self.button:setTitle('LOLOLOL')
    self.button:setFont('HelveticaNeue-Light', 13)
    self.button:setColor(COLOR(0xffffffaa))
    self.button.m:setFrame{{0, 0},{pwidth, pheight}}
    local expanded = false
    function self.button.ontoggle()
        expanded = true
        self.button.m:setUserInteractionEnabled(false)
        self.tbl.m:setUserInteractionEnabled(true)
        ANIMATE(0.3, function()
            self.m:setFrame(page_table_frame)
            self.button.m:setAlpha(0)
            self.tbl.m:setAlpha(1)
        end)
    end
    self.m:addSubview(self.button.m)

    self.tbl = ui.table:new()
    self.tbl.m:setBackgroundColor(objc.UIColor:clearColor())
    self.tbl.m:setSeparatorColor(objc.UIColor:clearColor())
    self.tbl.m:setFrame{{0, 0},{pwidth, theight}}
    local super = self.tbl.cell.mnew
    function self.tbl.cell.mnew(_)
        local m = super(_)
        m:setBackgroundColor(objc.UIColor:clearColor())
        m:textLabel():setTextColor(objc.UIColor:whiteColor())
        return m
    end
    function self.tbl.cell.gotcell(_, m, section, row)
        m:textLabel():setText(tostring(row))
    end
    function self.tbl.cell.onselect(_, section, row)
        self:jumpto(row)
        self:show(true)
    end
    self.tbl.m:setUserInteractionEnabled(false)
    self.tbl.m:setAlpha(0)
    self.m:addSubview(self.tbl.m)

    local page_is_visible = false
    local function anim(visible)
        local frame = visible and page_visible_frame or page_hidden_frame
        self.button.m:setUserInteractionEnabled(true)
        self.tbl.m:setUserInteractionEnabled(false)
        ANIMATE(function()
            self.m:setFrame(frame)
            self.button.m:setAlpha(1)
            self.tbl.m:setAlpha(0)
        end)
        page_is_visible = visible
    end

    local should_hide = false
    function self:show(override)
        should_hide = false
        if override or not page_is_visible then
            expanded = false
            anim(true)
        end
    end

    function self:jumpto(page)
    end

    function self:hide(delay)
        should_hide = true
        DISPATCH(delay or 0, function()
            if expanded or not should_hide then return end
            anim(false)
        end)
    end

    function self:update(page, num_pages)
        num_pages = num_pages or self.tbl.section[1]
        self.page = page
        self.tbl.section = {num_pages}
        self.tbl:refresh()

        local height = math.min(num_pages*44, theight)
        page_table_frame.origin.y = page_hidden_frame.origin.y - height
        self.tbl.m:setFrame{{0,0},{pwidth,height}}

        self.button:setTitle('Page '..page..' / '..num_pages)
        if num_pages == 1 then
            self.m:setHidden(true)
        end
    end

    return self
end
