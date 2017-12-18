return function(m, thread, cb, body)
    local mid
    local title
    local button_title
    if type(thread) == 'number' then
        mid = '/api/forum/edit_post?post='..thread
        button_title = 'Save'
        title = 'Edit post'
    else
        mid = '/api/forum/new_post?thread='..thread.id
        button_title = 'Reply'
        title = 'Post reply'
    end
    local vc = VIEWCONTROLLER(function(m)
        m:view():setBackgroundColor(objc.EQEMainView:themeColor())
        m:setAutomaticallyAdjustsScrollViewInsets(false)

        local y = NAV_HEIGHT + STATUS_BAR_HEIGHT
        local textview = objc.UITextView:alloc():initWithFrame{{0, y},{m:view():frame().size.width, m:view():frame().size.height - y}}

        textview:setFont(objc.UIFont:fontWithName_size('HelveticaNeue-Light', 16))
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
        textview:becomeFirstResponder()

        local reply = ns.target:new()
        local button = objc.UIBarButtonItem:alloc():initWithTitle_style_target_action(button_title, UIBarButtonItemStylePlain, reply.m, reply.sel)
        m:navigationItem():setRightBarButtonItem(button)
        function reply.onaction()
            textview:resignFirstResponder()
            local activity = objc.UIActivityIndicatorView:alloc():initWithFrame{{0,0},{44,44}}
            activity:startAnimating()
            local item = objc.UIBarButtonItem:alloc():initWithCustomView(activity)
            m:navigationItem():setRightBarButtonItem(item)
            local body = textview:text():stringByAddingPercentEncodingWithAllowedCharacters(objc.NSCharacterSet:alphanumericCharacterSet())
            HTTP(BASE_URL..mid..'&body='..objc.tolua(body), {convert = 'json'}, function(json, status, headers)
                m:navigationItem():setRightBarButtonItem(button)
                if status == 200 then
                    m:dismissModalViewControllerAnimated(true)
                    cb(json)
                end
            end)
        end


        local close = ns.target:new()
        local button = objc.UIBarButtonItem:alloc():initWithTitle_style_target_action('Close', UIBarButtonItemStylePlain, close.m, close.sel)
        m:navigationItem():setLeftBarButtonItem(button)
        function close.onaction()
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
