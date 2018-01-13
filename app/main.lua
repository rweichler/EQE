local app = objc.UIApplication:sharedApplication()
app:setStatusBarHidden(false)
app:setStatusBarStyle(UIStatusBarStyleLightContent)

ffi.cdef[[
id image_fill(id image, id color);
void ipc_sand(const char *query, void (*callback)(const char*));
]]

--BASE_URL = 'http://127.0.0.1:19999'
--BASE_URL = 'http://192.168.1.9:8080'
BASE_URL = 'https://eqe.fm'

_G.sesh = require 'sesh'

STATUS_BAR_HEIGHT = objc.UIApplication:sharedApplication():statusBarFrame().size.height
NAV_HEIGHT = 44

function IMG(name, color)
    if type(color) == 'string' then
        local c = objc.UIColor
        color = c[color..'Color'](c)
    end
    local img = objc.UIImage:imageWithContentsOfFile(ASSET_PATH..'/'..name)
    if color == false then
        return img
    else
        return C.image_fill(img, color or objc.UIColor:whiteColor())
    end
end

function COLOR(r, g, b, a)
    if not g then
        a = r % 0x100
        r = (r - a)/0x100
        b = r % 0x100
        r = (r - b)/0x100
        g = r % 0x100
        r = (r - g)/0x100
    end
    return objc.UIColor:colorWithRed_green_blue_alpha(r/0xff, g/0xff, b/0xff, a/0xff)
end

function new_nav_button(x, y, img)
    local nav_size = 32
    local pad = (NAV_HEIGHT-nav_size)/2
    local nav_icon = objc.UIImageView:alloc():initWithFrame{{pad, pad},{nav_size, nav_size}}
    nav_icon:setImage(img or IMG('navicon.png'))

    local nav_button = ui.button:new()
    nav_button.m:setFrame{{x, y},{NAV_HEIGHT, NAV_HEIGHT}}
    nav_button.m:addSubview(nav_icon)
    return nav_button
end

local window = objc.UIWindow:alloc():initWithFrame(objc.UIScreen:mainScreen():bounds())
window:setRootViewController(VIEWCONTROLLER(function(m)
    _G.MAIN_VIEW = m:view()

    m:view():setBackgroundColor(objc.EQEMainView:themeColor())
    local self = objc.getref(m)
    local frame = m:view():bounds()

    local active

    local main = objc.UIView:alloc():initWithFrame(frame)
    main:setBackgroundColor(objc.EQEMainView:themeColor())

    CONTENT_FRAME = ffi.new('struct CGRect', {{0, NAV_HEIGHT + STATUS_BAR_HEIGHT}, {frame.size.width, frame.size.height - (NAV_HEIGHT + STATUS_BAR_HEIGHT)}})

    local eqe = objc.EQEMainView:alloc():initWithFrame(frame)
    --eqe:setBackgroundColor(objc.UIColor:colorWithWhite_alpha(0.07, 1))

    local nav_button = new_nav_button(16, STATUS_BAR_HEIGHT)
    local big_button = ui.button:new()
    big_button.m:setFrame{{frame.size.width - 44, 0}, {44, frame.size.height}}
    big_button.m:setHidden(true)
    function TOGGLE_NAV()
        if nav_button.active then
            if active == Page.eqe.view then
                active:onAppRelaunch()
            end
            ANIMATE(function()
                main:setFrame(frame)
            end)
            big_button.m:setHidden(true)
        else
            ANIMATE(function()
                main:setFrame{{frame.size.width - 44, 0}, {frame.size.width, frame.size.height}}
            end)
            big_button.m:setHidden(false)
        end
        nav_button.active = not nav_button.active
        if active_item.navpressed then
            active_item:navpressed(nav_button.active)
        end
    end
    MAIN_NAV_BUTTON = nav_button
    nav_button.ontoggle = TOGGLE_NAV
    big_button.ontoggle = TOGGLE_NAV

    local nav = ui.table:new()
    nav.m:setFrame{{0, STATUS_BAR_HEIGHT},{frame.size.width-44, frame.size.height - STATUS_BAR_HEIGHT}}
    nav.m:setBackgroundColor(objc.UIColor:clearColor())
    nav.m:setSeparatorColor(objc.UIColor:clearColor())
    nav.m:setContentInset{22, 0, 0, 0}

    _G.Page = {}
    PAGE_ICON_COLOR = 'gray'
    Page.eqe = {title = 'Equalizer', icon = IMG('levels.png', PAGE_ICON_COLOR):retain(), view = eqe}
    Page.history = require 'page.history'
    Page.update = require 'page.update'
    Page.forum = require 'page.forum'
    Page.discord = require 'page.discord'

    nav.items = {{
        Page.update,
        Page.eqe,
        Page.history,
        Page.forum,
        Page.discord,
    }}
    local super = nav.cell.mnew
    function nav.cell.mnew(_)
        local m = super(_)
        m:textLabel():setFont(objc.UIFont:fontWithName_size('HelveticaNeue-Bold', 22))
        return m
    end
    local selected_view = objc.UIView:alloc():initWithFrame{{0, 0},{2, 44}}
    selected_view:setBackgroundColor(COLOR(0x4bc2ffaa))
    function nav.cell.onshow(_, m, section, row)
        local item = nav.items[section][row]
        m:textLabel():setText(item.title)
        m:imageView():setImage(item.icon)
        if item.icon then
            local siz = 22
            m:imageView():setTransform(C.CGAffineTransformMakeScale(siz/item.icon:size().width, siz/item.icon:size().height))
        end
        if item.view == active then
            m:addSubview(selected_view)
        end
    end
    function SWAP_PAGE(item)
        if not item.view then
            item:init()
            if item.view then
                main:addSubview(item.view)
                main:addSubview(nav_button.m) -- put it in front
            else
                return
            end
        end
        active:setHidden(true)
        if item.hide then
            item:hide(true)
        elseif active.hide then
            active:hide(true)
        end
        active_item = item
        active = item.view
        active:setHidden(false)
        if item.hide then
            item:hide(false)
        elseif active.hide then
            active:hide(false)
        end
        nav_button:ontoggle()
        if active_item.hide_nav_button then
            nav_button.m:setHidden(true)
        else
            nav_button.m:setHidden(false)
        end
        nav:refresh()
    end
    function nav.cell.onselect(_, section, row)
        SWAP_PAGE(nav.items[section][row])
    end

    active_item = Page.eqe
    active = eqe
    if active.hide then
        active:hide(false)
    end

    m:view():addSubview(nav.m)
    m:view():addSubview(require 'vc.userinfo'(nav, frame).m)
    m:view():addSubview(main)
    m:view():addSubview(big_button.m)

    for i,v in ipairs(nav.items[1]) do
        if v.view then
            if not(active == v.view) then
                v.view:setHidden(true)
            end
            main:addSubview(v.view)
        end
    end

    main:addSubview(nav_button.m)
    main:layer():setMasksToBounds(false)
    main:layer():setShadowOffset{-15, 20}
    main:layer():setShadowRadius(5)
    main:layer():setShadowOpacity(0.5)

    eqe:update()

end))

_G.ROOT_VC = window:rootViewController()
window:makeKeyAndVisible()

CHECK_UPDATE(function(json, err)
    if err or not SHOULD_ALERT_UPDATE then return end

    C.alert_display_c('An update is available!', 'Later', 'More info', function()
        if not MAIN_NAV_BUTTON.active then
            TOGGLE_NAV()
            DISPATCH(0.2, function()
                SWAP_PAGE(Page.update)
            end)
        else
            SWAP_PAGE(Page.update)
        end
    end)
end)

require 'autorun_loader'('app')
