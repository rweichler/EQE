local page = {}
page.title = 'Fund development'
page.icon = IMG('card.png', PAGE_ICON_COLOR):retain()

local white = objc.UIColor:colorWithWhite_alpha(1, 0.2):retain()
local card_img = IMG('card.png', white):retain()
local card_img_view = objc.UIImageView:alloc():initWithImage(card_img)
card_img:release()

function page:init()
    local scroll = ui.scroll:new()
    page.view = scroll.m

    scroll.m:setFrame(CONTENT_FRAME)
    local FW = CONTENT_FRAME.size.width
    scroll.m:setContentSize{FW, FW*2}
    scroll.m:setBackgroundColor(objc.EQEMainView:themeColor())

    local card_siz = 30
    local card_field_pad = 10
    card_img_view:setFrame{{card_field_pad, 0},{card_siz, card_siz}}
    scroll.m:addSubview(card_img_view)

    local card_field = objc.STPPaymentCardTextField:alloc():init()
    card_field:setTextColor(objc.UIColor:whiteColor())
    card_field:setPlaceholderColor(objc.UIColor:darkGrayColor())
    card_field:setBorderColor(objc.UIColor:darkGrayColor())
    card_field:setPostalCodeEntryEnabled(true)
    card_field:setKeyboardAppearance(UIKeyboardAppearanceDark)
    local card_field_height = 44
    card_field:setFrame{{card_field_pad, card_siz}, {FW - card_field_pad*2, card_field_height}}
    scroll.m:addSubview(card_field)

    self.card_field = card_field
    function scroll:onscroll()
        card_field:endEditing(true)
    end

    self.pay_button = ui.button:new()
    local w = 160
    self.pay_button.m:setFrame{{(FW-w)/2, card_siz + card_field_height + 10},{160, 44}}
    self.pay_button:setTitle('Pay $8')
    self.pay_button:setColor(objc.UIColor:whiteColor())
    self.pay_button.m:setBackgroundColor(COLOR(52, 208, 140, 0xff*0.7))
    self.pay_button.m:layer():setCornerRadius(8)
    function self.pay_button:onpress(pressed)
        local alpha = pressed and 0.2 or 0.7
        self.m:setBackgroundColor(COLOR(52, 208, 140, 0xff*alpha))
    end
    scroll.m:addSubview(self.pay_button.m)

    local notice = objc.UILabel:alloc():initWithFrame{{card_field_pad, card_siz + card_field_height + 10 + 44 + 10},{FW - card_field_pad*2, 100}}
    notice:setTextColor(white)



    local info = "Your payment info is encrypted clientside and sent directly to Stripe. I don't see your card number."
    local learn_more = 'Learn more'
    local range = ffi.new('NSRange', #info + 1, #learn_more)
    local text = objc.NSMutableAttributedString:alloc():initWithString_attributes(info..' '..learn_more..' ', nil)
    text:addAttributes_range({
        [C.NSForegroundColorAttributeName] = COLOR(0x9bb2c0aa),
        [C.NSUnderlineStyleAttributeName] = NSUnderlineStyleSingle,
    }, range)
    text:addAttributes_range({
        [C.NSFontAttributeName] = notice:font():fontWithSize(13),
    }, ffi.new('NSRange', 0, text:length()))
    notice:setAttributedText(text)
    --notice:setFont(notice:font():fontWithSize(13))
    notice:setNumberOfLines(0)
    notice:sizeToFit()
    scroll.m:addSubview(notice)

    -- Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
    local layoutManager = objc.NSLayoutManager:alloc():init()
    local textContainer = objc.NSTextContainer:alloc():initWithSize(notice:bounds().size)
    local textStorage = objc.NSTextStorage:alloc():initWithAttributedString(text)

    -- Configure layoutManager and textStorage
    layoutManager:addTextContainer(textContainer)
    textStorage:addLayoutManager(layoutManager)
    --textStorage:addAttribute_value_range(C.NSFontAttributeName, notice:font(), {0, textStorage:length()})

    -- Configure textContainer
    textContainer:setLineFragmentPadding(0)
    textContainer:setLineBreakMode(notice:lineBreakMode())
    textContainer:setMaximumNumberOfLines(notice:numberOfLines())

    -- tap

    local tap = ns.target:new()
    local gesture = objc.UITapGestureRecognizer:alloc():initWithTarget_action(tap.m, tap.sel)
    function tap.onaction()
        local pos = gesture:locationInView(notice)
        local size = notice:bounds().size
        local textBoundingBox = layoutManager:usedRectForTextContainer(textContainer)
        local off = {
            x = (size.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y = (size.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y,
        }
        local touch = ffi.new('struct CGPoint', {
            x = pos.x - off.x,
            y = pos.y - off.y,
        })
        local idx = layoutManager:characterIndexForPoint_inTextContainer_fractionOfDistanceBetweenInsertionPoints(touch, textContainer, nil)
        if idx >= range.location and idx < range.location + range.length then
            objc.UIApplication:sharedApplication():openURL(objc.NSURL:URLWithString('https://stripe.com/docs/security/stripe'))
        end
    end
    notice:addGestureRecognizer(gesture)
    notice:setUserInteractionEnabled(true)
end
function page:navpressed()
    if self.card_field then
        self.card_field:endEditing(true)
    end
end
return page
