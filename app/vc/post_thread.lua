return function(m, forum, cb, body)
    local mid
    local title
    local button_title
    assert(type(forum) == 'table')
    mid = '/api/forum/new_thread?forum='..forum.id
    button_title = 'Post'
    title = 'New thread'
    local vc = VIEWCONTROLLER(function(m)
        m:view():setBackgroundColor(objc.EQEMainView:themeColor())
        m:setAutomaticallyAdjustsScrollViewInsets(false)

        local y = NAV_HEIGHT + STATUS_BAR_HEIGHT

        local titleField = objc.UITextField:alloc():initWithFrame{{0, y}, {m:view():frame().size.width, 44}}
        titleField:setKeyboardAppearance(UIKeyboardAppearanceDark)
        -- username:setAutocorrectionType(UITextAutocorrectionTypeNo)
        -- TODO ^ figure out why this method isnt exposed
        titleField:setBackgroundColor(COLOR(0xffffff0d))
        titleField:setTextColor(objc.UIColor:whiteColor())
        local left = objc.UIView:alloc():initWithFrame{{0,0},{10,44}}
        titleField:setLeftView(left)
        titleField:setLeftViewMode(UITextFieldViewModeAlways)

        local attr = objc.NSMutableAttributedString:alloc():initWithString('Title')
        attr:addAttributes_range({
            [C.NSForegroundColorAttributeName] = COLOR(0xffffff33),
        }, ffi.new('NSRange', 0, attr:length()))
        titleField:setAttributedPlaceholder(attr)
        attr:release()

        m:view():addSubview(titleField)
        titleField:becomeFirstResponder()

        y = y + titleField:frame().size.height

        local textview = objc.EQETextView:alloc():initWithFrame{{0, y},{m:view():frame().size.width, m:view():frame().size.height - y}}
        textview:setFont(objc.UIFont:fontWithName_size('HelveticaNeue-Light', 16))
        textview:setPlaceholder('Body')
        textview:setBackgroundColor(objc.UIColor:clearColor())
        textview:setTextColor(objc.UIColor:whiteColor())
        textview:setText(body)

        local target = ns.target:new()
        function target.onaction(_, notification)
            local info = notification.userInfo
            local val = info:valueForKey(C.UIKeyboardFrameEndUserInfoKey)
            local rect = val:CGRectValue()
            rect = textview:convertRect_fromView(rect, nil)

            local frame = textview:frame()
            frame.size.height = rect.origin.y
            textview:setFrame(frame)
        end
        objc.NSNotificationCenter:defaultCenter():addObserver_selector_name_object(target.m, target.sel, C.UIKeyboardWillChangeFrameNotification, nil)

        m:view():addSubview(textview)

        local reply = ns.target:new()
        local button = objc.UIBarButtonItem:alloc():initWithTitle_style_target_action(button_title, UIBarButtonItemStylePlain, reply.m, reply.sel)
        m:navigationItem():setRightBarButtonItem(button)
        function reply.onaction()
            titleField:resignFirstResponder()
            textview:resignFirstResponder()
            local activity = objc.UIActivityIndicatorView:alloc():initWithFrame{{0,0},{44,44}}
            activity:startAnimating()
            local item = objc.UIBarButtonItem:alloc():initWithCustomView(activity)
            m:navigationItem():setRightBarButtonItem(item)
            local title = titleField:text():stringByAddingPercentEncodingWithAllowedCharacters(objc.NSCharacterSet:alphanumericCharacterSet())
            local body = textview:text():stringByAddingPercentEncodingWithAllowedCharacters(objc.NSCharacterSet:alphanumericCharacterSet())
            HTTP(BASE_URL..mid..'&body='..objc.tolua(body)..'&title='..objc.tolua(title), {convert = 'json'}, function(json, status, headers)
                m:navigationItem():setRightBarButtonItem(button)
                if status == 200 then
                    m:dismissModalViewControllerAnimated(true)
                    cb(json)
                elseif json.error then
                    C.alert_display_c(json.error, 'Okay', nil, nil)
                end
            end)
        end


        local close = ns.target:new()
        local button = objc.UIBarButtonItem:alloc():initWithTitle_style_target_action('Close', UIBarButtonItemStylePlain, close.m, close.sel)
        m:navigationItem():setLeftBarButtonItem(button)
        function close.onaction()
            titleField:resignFirstResponder()
            textview:resignFirstResponder()
            m:dismissModalViewControllerAnimated(true)
        end
    end, title)
    local nav = objc.UINavigationController:alloc():initWithRootViewController(vc)
    nav:navigationBar():setBarTintColor(objc.EQEMainView:themeColor())
    nav:navigationBar():setTintColor(objc.UIColor:whiteColor())
    nav:navigationBar():setTitleTextAttributes{[C.NSForegroundColorAttributeName] = objc.UIColor:whiteColor()}
    m:presentModalViewController_animated(nav, true)
end
