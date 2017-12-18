local load_failed = {}
local mt = {__index = load_failed}


function load_failed.new()
    local self = setmetatable({}, mt)

    local m = objc.UIView:alloc():init()

    local container = objc.UIView:alloc():init()

    local title = objc.UILabel:alloc():init()
    title:setFont(objc.UIFont:fontWithName_size('HelveticaNeue-Bold', 28))
    title:setText('Load failed :(')
    title:sizeToFit()
    title:setColor(COLOR(0xff5555dd))

    container:addSubview(title)

    local message = objc.UILabel:alloc():initWithFrame{{0, 0},{title:frame().size.width*4/5, 0}}
    message:setFont(objc.UIFont:fontWithName_size('HelveticaNeue', 16))
    message:setNumberOfLines(0)
    message:setColor(COLOR(0xffffffaa))
    message:setTextAlignment(NSTextAlignmentCenter)
    container:addSubview(message)

    local retry = ui.button:new()
    retry.parent = self
    retry:setFont('HelveticaNeue', 16)
    retry:setColor(COLOR(0xffffff99))
    retry.m:setBackgroundColor(COLOR(0xffffff08))
    retry.m:layer():setCornerRadius(17)
    retry:setTitle('Try again')
    retry.m:setFrame{{0, 0}, {110, 34}}
    function retry.ontoggle(retry)
        retry.parent:onretry()
    end
    container:addSubview(retry.m)

    local activity = objc.UIActivityIndicatorView:alloc():init()
    activity:setActivityIndicatorViewStyle(UIActivityIndicatorViewStyleWhiteLarge)

    self.m = m
    self.activity = activity
    self.container = container
    self.title = title
    self.message = message
    self.retry = retry

    return self
end

function load_failed:onretry()
end

function load_failed:stop()
    self.container:removeFromSuperview()
    self.activity:removeFromSuperview()
    self.activity:stopAnimating()
end

function load_failed:start_load(parent_size)
    local siz = 128
    local x = (parent_size.width - siz)/2
    local y = (parent_size.height - siz)/2
    self.activity:setFrame{{x,y},{siz,siz}}
    self.container:removeFromSuperview()
    self.activity:startAnimating()
    self.m:setFrame{{0,0},parent_size}
    self.m:addSubview(self.activity)
end

function load_failed:set_message(txt, parent_size)
    self.message:setText(txt)
    self.message:sizeToFit()

    local pad = 14

    local w = self.title:frame().size.width

    local x = (w - self.message:frame().size.width)/2
    local y = self.title:frame().size.height + pad
    self.message:setFrame{{x, y}, self.message:frame().size}

    local x = (w - self.retry.m:frame().size.width)/2
    local y = y + self.message:frame().size.height + pad
    self.retry.m:setFrame{{x, y}, self.retry.m:frame().size}

    local h = y + self.retry.m:frame().size.height
    local x = (parent_size.width - w)/2
    local y = (parent_size.height - h)/2

    self.activity:stopAnimating()
    self.activity:removeFromSuperview()
    self.m:addSubview(self.container)

    self.m:setFrame{{x,y},{w,h}}
    self.container:setFrame{{0,0},{w,h}}
end

return load_failed
