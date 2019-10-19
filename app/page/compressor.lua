-- put this into /var/tweak/com.r333d.eqe/lua/autorun/app/
-- load by restarting the EQE app

local str_esc = require 'str_esc'
local md = require 'md'

local page = {}
page.title = 'Compressor (beta)'
page.icon = IMG('radio-waves.png', PAGE_ICON_COLOR):retain()

local function ipc(s, safe)
    s = str_esc(s)
    if safe then
        return IPC('return eqe.raw('..s..')')
    else
        return IPC('return eqe.raw('..s..', true)')
    end
end

local pad = 11
local function create_switch(y, canvaswidth, title, m)
    local target = ns.target:new()
    target.switch = objc.UISwitch:alloc():init()
    local s = target.switch:frame().size
    local x = canvaswidth - s.width - pad*3
    target.switch:setFrame{{x, y},s}
    target.switch:setOnTintColor(COLOR(0x4bc2ffaa))
    target.switch:setTintColor(COLOR(0xffffff55))
    target.switch:addTarget_action_forControlEvents(target.m, target.sel, UIControlEventValueChanged)

    target.label = objc.UILabel:alloc():init()
    target.label:setFont(objc.UIFont:fontWithName_size('HelveticaNeue', 16))
    target.label:setTextColor(COLOR(0xffffff8d))
    target.label:setBackgroundColor(objc.UIColor:clearColor())
    target.label:setText(title)
    target.label:sizeToFit()
    local switchS = s
    local s = target.label:frame().size
    target.label:setFrame{{x - s.width - pad, y + (switchS.height - s.height)/2},s}

    m:view():addSubview(target.label)
    m:view():addSubview(target.switch)
    return target, y + target.switch:frame().size.height
end

function page:init()
    local vc = VIEWCONTROLLER(function(m)
        local frame = m:view():frame()
        local width = frame.size.width

        local y = 64

        local enable, y = create_switch(y, width, 'Enabled', m)
        function enable.onaction()
            local on = objc.weirdbool(enable.switch:isOn())
            ipc('compressor.enabled('..tostring(on)..')')
            ipc('compressor.save()')
        end
        self.enable = enable

        local r = md.new(width - pad*2)
        self.helper_text = r.m
        self.helper_text:setFrame{{pad, y + pad},{0,0}}
        m:view():addSubview(self.helper_text)
        r:init[[
This basically makes your audio more "level" and "loud". Good for listening to podcasts and that kinda stuff. [Wikipedia article](https://en.wikipedia.org/wiki/Dynamic_range_compression)

This is a super basic version of a compressor, it's literally just an enable switch with some super basic presets. There should be more options here but I don't know how compressors work.

If you know how to use a compressor, hop on the [Discord chat](https://discord.gg/RSJWAuX). I can show you the under-the-hood settings in Terminal.

This code is open source.
]]

    end)
    self.view = vc:view()
end

function page:refresh()
    local enabled = ipc('return compressor.enabled()') == 'true'

    self.enable.switch:setOn(enabled)
end

function page:hide(hiding)
    if not hiding then
        self:refresh()
    end

end

Page.compressor = page
ADD_NAV_PAGE(page, Page.eqe)
