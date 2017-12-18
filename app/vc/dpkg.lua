return function(x, y, width)
    local container = objc.UIView:alloc():init()
    container:setUserInteractionEnabled(false)

    local label = objc.UILabel:alloc():init()
    label:setFont(objc.UIFont:fontWithName_size('Courier', 14))
    label:setTextColor(objc.UIColor:whiteColor())
    label:setNumberOfLines(0)
    label:setText('')
    label:setAlpha(0.7)
    container:addSubview(label)
    return container, function(s, vanity)
        if s == true or s == false then
            local label2 = objc.UILabel:alloc():init()
            label2:setFont(label:font())
            label2:setAlpha(0.7)
            label2:setUserInteractionEnabled(false)
            label2:setBackgroundColor(label:backgroundColor())
            label2:setTextColor(s and objc.UIColor:greenColor() or objc.UIColor:redColor())
            label2:setNumberOfLines(0)
            label2:setText(vanity..'\n')
            label2:setFrame{{0, 0},{width, 0}}
            label2:sizeToFit()
            label2:setFrame{{0, label:frame().size.height},{width, label2:frame().size.height}}

            container:setFrame{{x, y},{width, label:frame().size.height + label2:frame().size.height}}

            container:addSubview(label2)
            label2:release()
            return
        end
        label:setFrame{{0, 0}, {width, label:frame().size.height}}
        label:setText(objc.tolua(label:text())..s)
        label:sizeToFit()
        label:setFrame{{0, 0}, {width, label:frame().size.height}}
        container:setFrame{{x, y},{width, label:frame().size.height}}
    end
end
