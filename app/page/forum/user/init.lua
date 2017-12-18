local md = require 'md'
local req_avatar = require 'req.avatar'

return function(id)
    return function(m)

        local scroll = ui.scroll:new()
        scroll.m:setFrame(m:view():bounds())
        m:view():addSubview(scroll.m)
        scroll:csize(m:view():bounds().size)

        m:view():setBackgroundColor(objc.EQEMainView:themeColor())
        HTTP(BASE_URL..'/api/user?user='..id, {convert='json'}, function(json, status, headers)
            if json and json.avatar then
                req_avatar(json.username, function(blob)
                    local img = objc.UIImageView:alloc():initWithFrame{{0, 0},blob:size()}
                    img:setImage(blob)
                    scroll.m:addSubview(img)

                    local username = objc.UILabel:alloc():initWithFrame{{img:frame().size.width, 0},{0,0}}
                    username:setBackgroundColor(objc.UIColor:clearColor())
                    username:setTextColor(objc.UIColor:whiteColor())
                    username:setText(json.username)
                    username:sizeToFit()
                    scroll.m:addSubview(username)

                    local md = md.new(m:view():frame().size.width)
                    md.m:setFrame{{0,img:frame().size.height},md.m:frame().size}
                    function md.onupdate()
                        local w, h = scroll:csize()
                        h = md.m:frame().origin.y + md.m:frame().size.height
                        scroll:csize(w, h)
                    end
                    md:init(json.info)
                    scroll.m:addSubview(md.m)

                end)
            else
                C.alert_display_c('somethin bad', 'k', nil, nil)
            end
        end)
    end
end
