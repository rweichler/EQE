local json = require 'dkjson'

return function(cb)
    local nav = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)

        local hpad = 22
        local vpad = 11

        m:view():setBackgroundColor(objc.EQEMainView:themeColor())
        local target = ns.target:new()
        local button = objc.UIBarButtonItem:alloc():initWithTitle_style_target_action('Close', UIBarButtonItemStylePlain, target.m, target.sel)
        m:navigationItem():setLeftBarButtonItem(button)

        local y = NAV_HEIGHT + STATUS_BAR_HEIGHT + vpad
        local username = objc.UITextField:alloc():initWithFrame{{hpad, y}, {m:view():frame().size.width - hpad*2, 44}}
        -- username:setAutocorrectionType(UITextAutocorrectionTypeNo)
        -- TODO ^ figure out why this method isnt exposed
        username:setBackgroundColor(COLOR(0xffffff0d))
        username:setTextColor(objc.UIColor:whiteColor())
        username:layer():setBorderColor(COLOR(0xffffff44):CGColor())
        username:layer():setBorderWidth(1)
        username:layer():setCornerRadius(7)
        local left = objc.UIView:alloc():initWithFrame{{0,0},{10,44}}
        username:setLeftView(left)
        username:setLeftViewMode(UITextFieldViewModeAlways)
        left:release()

        local attr = objc.NSMutableAttributedString:alloc():initWithString('Username or Email')
        attr:addAttributes_range({
            [C.NSForegroundColorAttributeName] = COLOR(0xffffff33),
        }, ffi.new('NSRange', 0, attr:length()))
        username:setAttributedPlaceholder(attr)
        attr:release()

        y = y + username:frame().size.height + vpad
        local password = objc.UITextField:alloc():initWithFrame{{hpad, y}, {m:view():frame().size.width - hpad*2, 44}}
        password:setSecureTextEntry(true)
        password:setBackgroundColor(COLOR(0xffffff0d))
        password:setTextColor(objc.UIColor:whiteColor())
        password:layer():setBorderColor(COLOR(0xffffff44):CGColor())
        password:layer():setBorderWidth(1)
        password:layer():setCornerRadius(7)

        local left = objc.UIView:alloc():initWithFrame{{0,0},{10,44}}
        password:setLeftView(left)
        password:setLeftViewMode(UITextFieldViewModeAlways)
        left:release()

        local attr = objc.NSMutableAttributedString:alloc():initWithString('Password')
        attr:addAttributes_range({
            [C.NSForegroundColorAttributeName] = COLOR(0xffffff33),
        }, ffi.new('NSRange', 0, attr:length()))
        password:setAttributedPlaceholder(attr)
        attr:release()

        local button = ui.button:new()
        button:setTitle('Login')
        button.m:layer():setCornerRadius(10)
        button:setColor(COLOR(0xffffff99))
        button.m:setBackgroundColor(COLOR(0xbbddff0d))
        local width = 100
        y = y + password:frame().size.height + vpad
        button.m:setFrame{{m:view():frame().size.width - width - hpad, y}, {width, 39}}
        local activity = objc.UIActivityIndicatorView:alloc():initWithFrame(button.m:frame())
        local label
        local function err(txt)
            label:setText(txt)
            local frame = label:frame()
            frame.size.width = m:view():frame().size.width - 40
            label:setFrame(frame)
            label:sizeToFit()
            local frame = label:frame()
            frame.origin.x = (m:view():frame().size.width - frame.size.width)/2
            label:setFrame(frame)
        end
        function button.ontoggle()
            username:resignFirstResponder()
            password:resignFirstResponder()
            activity:startAnimating()
            m:view():addSubview(activity)
            button.m:removeFromSuperview()
            local user_arg = username:text():stringByAddingPercentEncodingWithAllowedCharacters(objc.NSCharacterSet:alphanumericCharacterSet())
            local pass_arg = password:text():stringByAddingPercentEncodingWithAllowedCharacters(objc.NSCharacterSet:alphanumericCharacterSet())
            HTTP(BASE_URL..'/api/login?username='..objc.tolua(user_arg)..'&password='..objc.tolua(pass_arg), function(blob, status, headers)
                m:view():addSubview(button.m)
                activity:removeFromSuperview()
                if blob then
                    local json = json.decode(blob)
                    if json.error then
                        err(json.error)
                    else
                        err('')
                        m:dismissModalViewControllerAnimated(true)
                        username:resignFirstResponder()
                        password:resignFirstResponder()
                        cb(json)
                        require 'vc.userinfo'().login(json)
                        local has_logged_in_path = '/var/tweak/com.r333d.eqe/db/has_logged_in_once'
                        local f = io.open(has_logged_in_path, 'r')
                        if not f then
                            C.alert_display_c('It appears this is the first time you have logged in to eqe.fm. Would you like to send your playback history there from now on, so other people can see it?\n\nTo change these settings, go to Playback history > App whitelist', 'No', 'Sure', function()
                                IPCD('SET_SHOULD_I_SPIN(false, true)')
                            end)
                            f = io.open(has_logged_in_path, 'w')
                        end
                        f:close()
                    end
                else
                    err(status)
                end
            end)
        end

        local create_account = ui.button:new()
        create_account:setTitle('Create account')
        create_account:setColor(COLOR(0x88bbffbb))
        local width = 140
        create_account.m:setFrame{{hpad, y}, {width, 39}}
        function create_account.ontoggle()
            local url = objc.NSURL:URLWithString('https://eqe.fm/register')
            objc.UIApplication:sharedApplication():openURL(url)
        end

        y = y + button.m:frame().size.height + vpad
        label = objc.UILabel:alloc():initWithFrame{{20, y}, {m:view():frame().size.width - 40, 0}}
        label:setTextAlignment(NSTextAlignmentCenter)
        label:setFont(objc.UIFont:fontWithName_size('HelveticaNeue-Light', 13.5))
        label:setNumberOfLines(0)
        label:setBackgroundColor(objc.UIColor:clearColor())
        label:setColor(COLOR(0xffaaaaff))

        m:view():addSubview(username)
        m:view():addSubview(password)
        m:view():addSubview(button.m)
        m:view():addSubview(create_account.m)
        m:view():addSubview(label)

        function target.onaction()
            m:dismissModalViewControllerAnimated(true)
            username:resignFirstResponder()
            password:resignFirstResponder()
            cb()
        end
    end, 'Login'))

    nav:navigationBar():setBarTintColor(objc.EQEMainView:themeColor())
    nav:navigationBar():setTintColor(objc.UIColor:whiteColor())
    nav:navigationBar():setTitleTextAttributes{[C.NSForegroundColorAttributeName] = objc.UIColor:whiteColor()}

    return nav
end
