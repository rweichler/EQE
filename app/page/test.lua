local md = require 'md'

local page = {}
page.title = 'TEST'

function page:init()
    page.view = objc.UIScrollView:alloc():initWithFrame(CONTENT_FRAME)
    page.view:setBackgroundColor(objc.EQEMainView:themeColor())


    local post = md.new(CONTENT_FRAME.size.width)
    function post.onupdate()
        page.view:setContentSize(post.m:bounds().size)
    end
    post:init(require 'test_post')
    page.view:addSubview(post.m)
end

return page
