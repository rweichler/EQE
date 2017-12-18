local page = {}
page.title = 'Feed'
page.icon = IMG('home.png', PAGE_ICON_COLOR):retain()

page.view = objc.UIView:alloc():initWithFrame(CONTENT_FRAME)

local label = objc.UILabel:alloc():init()
label:setColor(objc.UIColor:whiteColor())
label:setBackgroundColor(objc.UIColor:clearColor())
label:setNumberOfLines(0)
label:setText('Still a work in progress.')
label:sizeToFit()
local x = (CONTENT_FRAME.size.width - label:frame().size.width)/2
local y = (CONTENT_FRAME.size.height - label:frame().size.height)/5
label:setFrame{{x, y},label:frame().size}

page.view:addSubview(label)

return page
