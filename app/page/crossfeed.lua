-- put this into /var/tweak/com.r333d.eqe/lua/autorun/app/
-- load by restarting the EQE app

local str_esc = require 'str_esc'
local md = require 'md'

local page = {}
page.title = 'Crossfeed (beta)'
page.icon = IMG('headphone.png', PAGE_ICON_COLOR):retain()

local function ipc(s, safe)
    s = str_esc(s)
    if safe then
        return IPC('return eqe.raw('..s..')')
    else
        return IPC('return eqe.raw('..s..', true)')
    end
end

local thumbImg = IMG('thumb.png'):retain()

local pad = 11
local function create_slider(y, width, title, m)
    local self = {}
    self.onchange = function() end
    self.onfinish = function() end

    self.label = objc.UILabel:alloc():initWithFrame{{pad,y},{width - pad*2,44}}
    self.label:setFont(objc.UIFont:fontWithName_size('HelveticaNeue', 16))
    self.label:setTextColor(COLOR(0xffffff8d))
    self.label:setBackgroundColor(objc.UIColor:clearColor())
    self.label:setText(title)

    y = y + self.label:frame().size.height

    self.slider = objc.EQEOBSlider:alloc():initWithFrame{{pad,y},{width - pad*2,44}}
    self.slider:setThumbImage_forState(thumbImg, UIControlStateNormal)
    self.slider:setMinimumTrackTintColor(COLOR(0xffffff80))
    self.slider:setMaximumTrackTintColor(COLOR(0xffffff50))

    local target = ns.target:new()
    function target.onaction()
        self.onfinish()
    end
    self.slider:addTarget_action_forControlEvents(target.m, target.sel, bit.bor(UIControlEventTouchUpInside, UIControlEventTouchUpOutside))

    local target = ns.target:new()
    function target.onaction()
        self.onchange()
    end
    self.slider:addTarget_action_forControlEvents(target.m, target.sel, bit.bor(UIControlEventValueChanged))

    local target = ns.target:new()
    self.slider:addTarget_action_forControlEvents(target.m, target.sel, UIControlEventValueChanged)
    function self.updatetext()
        self.label:setText(title..': '..self.slider:value())
    end
    function target.onaction()
        self.updatetext()
    end

    y = y + self.slider:frame().size.height

    m:view():addSubview(self.slider)
    m:view():addSubview(self.label)

    return self, y
end

local function create_button(x, y, canvaswidth, title, m)
    local height = 34
    local width = canvaswidth*2/3
    local button = ui.button:new()
    button.m:setFrame{{x + (canvaswidth-width)/2, y},{width,height}}
    button.m:layer():setCornerRadius(8)
    button:setFont('HelveticaNeue', 16)
    button:setColor(COLOR(0xff, 0xff, 0xff, 0xff*0.7))
    button.m:setBackgroundColor(COLOR(0xff, 0xff, 0xff, 0xff*0.07))
    button:setTitle(title)
    m:view():addSubview(button.m)
    return button, y + height
end

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

        local intensity, y = create_slider(64, width, 'Intensity', m)
        intensity.slider:setMinimumValue(0)
        intensity.slider:setMaximumValue(1)
        function intensity.onchange()
            ipc('crossfeed.intensity('..intensity.slider:value()..')')
        end
        function intensity.onfinish()
            intensity.onchange()
            ipc('crossfeed.save()')
        end
        self.intensity = intensity

        local delay, y = create_slider(y, width, 'Delay (ms)', m)
        delay.slider:setMinimumValue(0)
        delay.slider:setMaximumValue(4)
        function delay.onchange()
            ipc('crossfeed.delay('..delay.slider:value()..')')
        end
        function delay.onfinish()
            delay.onchange()
            ipc('crossfeed.save()')
        end
        self.delay = delay

        --[[
        y = y + pad*2

        self.save = create_button(0, y, width/2, 'Save', m)
        local load, y = create_button(width/2, y, width/2, 'Load', m)
        self.load = load

        function self.save.ontoggle()
            ipc('crossfeed.save()')
        end

        function self.load.ontoggle()
            ipc('crossfeed.load()')
            self:refresh()
        end
        ]]

        y = y + pad*2

        local enable, y = create_switch(y, width, 'Enabled', m)
        function enable.onaction()
            local on = objc.weirdbool(enable.switch:isOn())
            ipc('crossfeed.enabled('..tostring(on)..')', true)
        end
        self.enable = enable

        local r = md.new(width - pad*2)
        self.helper_text = r.m
        self.helper_text:setFrame{{pad, y + pad},{0,0}}
        m:view():addSubview(self.helper_text)
        r:init[[
If you have no clue what this does, [here's a pretty good explanation](http://www.meier-audio.homepage.t-online.de/crossfeed.htm).

Basically, you should use this if you're using headphones, it makes it sound more "full" and "open", like speakers.

Credits to xC0nfused on [Discord](https://discord.gg/RSJWAuX) for helping make this. This code is open source.]]

    end)
    self.view = vc:view()
end

function page:refresh()
    local intensity = tonumber(ipc('return crossfeed.intensity()'))
    local delay = tonumber(ipc('return crossfeed.delay()'))
    local enabled = ipc('return crossfeed.enabled()') == 'true'

    self.intensity.slider:setValue(intensity)
    self.intensity.updatetext()
    self.delay.slider:setValue(delay)
    self.delay.updatetext()
    self.enable.switch:setOn(enabled)
end

function page:hide(hiding)
    if not hiding then
        self:refresh()
    end

end

Page.crossfeed = page
ADD_NAV_PAGE(page, Page.eqe)
