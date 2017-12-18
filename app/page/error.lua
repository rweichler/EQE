local frame = objc.UIScreen:mainScreen():bounds()
local window = objc.UIWindow:alloc():initWithFrame(frame)
local label = objc.UILabel:alloc():initWithFrame(frame)
label:setFont(label:font():fontWithSize(10))
label:setTextColor(objc.UIColor:whiteColor())
label:setNumberOfLines(0)
window:setRootViewController(VIEWCONTROLLER(function(m)
    m:view():addSubview(label)
end))
window:makeKeyAndVisible()


return function(s)
    label:setText([[Lua died :(

    Here's the error. Screenshot it and
    send it to the developer. Close and relaunch
    this app to make this message go away.



    ]]..s)
end
