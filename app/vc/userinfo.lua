local userinfo

return function(nav, frame)
    if userinfo then return userinfo end

    userinfo = {}
    local height = 38
    local pad = 40
    local width = nav.m:frame().size.width - pad*2
    local radius = 20
    userinfo.m = objc.UIView:alloc():initWithFrame{{pad, frame.size.height - height}, {width, height + radius}}
    userinfo.m:layer():setCornerRadius(radius)
    userinfo.m:setBackgroundColor(COLOR(0xffffff09))

    local button = ui.button:new()
    button:setTitle('Log in / Create account')
    button:setFont('HelveticaNeue-Light', 14)
    button:setColor(COLOR(0xffffff88))
    button.m:setBackgroundColor(objc.UIColor:clearColor())
    button.m:setFrame{{0, 0},{width, height}}
    function button.ontoggle()
        local nav = require 'vc.login'(function(login)
            if login then
                LOG_IN(login)
            end
        end)
        ROOT_VC:presentModalViewController_animated(nav, true)
    end

    local x = radius/2
    local y = radius/8
    local avatar_siz = 24
    local avatar = objc.UIImageView:alloc():initWithFrame{{x + (height - avatar_siz)/2, y + (height - avatar_siz)/2},{avatar_siz, avatar_siz}}
    avatar:setClipsToBounds(true)
    avatar:layer():setCornerRadius(5)

    local username = objc.UILabel:alloc():initWithFrame{{x + height, y},{width - height, height}}
    username:setFont(button.m:titleLabel():font())
    username:setTextColor(COLOR(0xffffff88))
    username:setBackgroundColor(objc.UIColor:clearColor())

    local logout_button = ui.button:new()
    logout_button:setTitle('Log out')
    logout_button:setFont('HelveticaNeue-Light', 14)
    logout_button:setColor(COLOR(0x99bbffaa))
    logout_button.m:setFrame{{width - height * 2, y},{height * 2, height}}
    function logout_button.ontoggle()
        userinfo.logout()
        LOG_IN(nil)
    end

    function userinfo.login(user)
        if user.avatar then
            get_avatar(user.username, function(img, was_cached)
                if not img then return end
                avatar:setImage(img)
            end, '-icon')
        end
        username:setText(user.username)
        username:sizeToFit()
        local frame = username:frame()
        frame.origin.y = y + (height - frame.size.height)/2
        username:setFrame(frame)
        button.m:removeFromSuperview()
        userinfo.m:addSubview(username)
        userinfo.m:addSubview(avatar)
        userinfo.m:addSubview(logout_button.m)
    end

    function userinfo.logout()
        username:removeFromSuperview()
        avatar:removeFromSuperview()
        logout_button.m:removeFromSuperview()
        userinfo.m:addSubview(button.m)
    end

    HTTP(BASE_URL..'/api/whoami', {convert = 'json'}, function(user, status, headers)
        if not user or user.error then
            userinfo.logout()
        else
            LOG_IN(user)
            userinfo.login(user)
        end
    end)

    return userinfo
end
