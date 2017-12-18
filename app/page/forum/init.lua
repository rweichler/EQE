local json = require 'dkjson'
local page = {}
page.title = 'Forum (beta)'
page.hide_nav_button = true
page.icon = IMG('person-stalker.png', PAGE_ICON_COLOR):retain()

local load_failed = require 'vc.load_failed'

local view_forum = require 'page.forum.threads'

local icon_cache = {}
local function loadicon(url, cb)
    local cache = icon_cache[url]
    if cache then
        if type(cache) == 'table' then
            table.insert(cache, cb)
        elseif type(cache) == 'cdata' then
            cb(cache)
        end
        return
    end
    icon_cache[url] = {}
    HTTP(url, {convert = 'image'}, function(img, status, headers)
        if not(img and status == 200) then return end
        img:retain()
        cb(img)
        for i,v in ipairs(icon_cache[url]) do
            v(img)
        end
        icon_cache[url] = img
    end)
end

function page:init()
    local function push(f, title)
        self.nav:pushViewController_animated(VIEWCONTROLLER(f, title), true)
    end
    self.nav = objc.UINavigationController:alloc():initWithRootViewController(VIEWCONTROLLER(function(m)
        local target = ns.target:new()
        target.onaction = function()
            TOGGLE_NAV()
        end

        local nav_button = new_nav_button(0, 0)
        nav_button.ontoggle = TOGGLE_NAV

        local item = objc.UIBarButtonItem:alloc():initWithCustomView(nav_button.m)
        m:navigationItem():setLeftBarButtonItem(item)

        local tbl = ui.table:new()
        tbl.items = {{}}
        tbl.m:setHidden(true)
        m:view():addSubview(tbl.m)

        local list_forums

        local load_fail = load_failed.new()
        function load_fail.onretry()
            list_forums()
        end
        m:view():addSubview(load_fail.m)

        local refresh_control = objc.UIRefreshControl:alloc():init()
        local refresh_target = ns.target:new()
        function refresh_target.onaction()
            list_forums(function()
                refresh_control:endRefreshing()
                tbl:refresh()
            end)
        end
        refresh_control:addTarget_action_forControlEvents(refresh_target.m, refresh_target.sel, UIControlEventValueChanged)
        tbl.m:addSubview(refresh_control)

        local function make_label(font, siz, color)
            local label = objc.UILabel:alloc():init()
            label:setFont(objc.UIFont:fontWithName_size(font, siz))
            label:setNumberOfLines(0)
            label:setBackgroundColor(objc.UIColor:clearColor())
            if color then
                label:setTextColor(COLOR(color))
            end
            return label
        end

        local min_height = 84
        local avatar_siz = 56
        local pad = (min_height - avatar_siz)/2

        local super = tbl.cell.mnew
        function tbl.cell.mnew(_)
            local m = super(_)
            m:detailTextLabel():setFont(m:detailTextLabel():font():fontWithSize(8))

            local self = objc.getref(m)

            self.title = make_label('HelveticaNeue-Bold', 17, 0xffffffcc)
            self.title:setFrame{{min_height,pad/2},{0,0}}
            self.title:setNumberOfLines(1)
            m:addSubview(self.title)

            self.description = make_label('HelveticaNeue', 12, 0xffffff9a)
            self.description:setFrame{{min_height,0},{0,0}}
            m:addSubview(self.description)

            self.icon = objc.UIImageView:alloc():initWithFrame{{pad,pad/2},{avatar_siz,avatar_siz}}
            self.icon:setClipsToBounds(true)
            self.icon:layer():setCornerRadius(8)
            m:addSubview(self.icon)

            return m
        end
        tbl.m:setFrame(m:view():bounds())
        local loading = true

        function tbl.cell.onselect(_, section, row)
            local forum = tbl.items[section][row]
            push(view_forum(forum, push, loadicon))
        end

        function list_forums(cb)
            load_fail:start_load(m:view():frame().size)
            HTTP(BASE_URL..'/api/forum/list_forums', {convert = 'json'}, function(forums, status, headers)
                if forums and status == 200 and not forums.error then
                    tbl.items[1] = forums
                    function tbl.cell.onshow(_, m, section, row)
                        local forum = tbl.items[section][row]
                        local self = objc.getref(m)

                        self.title:setText(forum.name)
                        self.title:sizeToFit()

                        self.description:setText(forum.description)
                        self.description:setFrame{{min_height, self.title:frame().origin.y + self.title:frame().size.height},{m:frame().size.width - min_height - pad, 0}}
                        self.description:sizeToFit()

                        self.icon:setImage(forum.icon)
                    end
                    function tbl.cell.getheight(_, section, row)
                        return min_height - pad
                    end

                    if cb then
                        cb()
                    else
                        tbl:refresh()
                    end
                    loading = false
                    for i,v in ipairs(forums) do
                        loadicon(BASE_URL..'/res/static/forum/'..v.id..'.png', function(icon)
                            v.icon = icon

                            local rows = objc.toobj{objc.NSIndexPath:indexPathForRow_inSection(i - 1, 0)}
                            tbl.m:reloadRowsAtIndexPaths_withRowAnimation(rows, UITableViewRowAnimationNone)
                        end)
                    end
                    tbl.m:setHidden(false)
                    load_fail:stop()
                    load_fail.m:removeFromSuperview()
                else
                    local msg
                    if forums then
                        msg = forums.error or 'Got HTTP error code: '..status
                    else
                        msg = status
                    end
                    load_fail:set_message(msg, m:view():frame().size)
                    --[[
                    C.alert_display_c(msg, 'Dismiss', 'Try again', function()
                        list_forums(cb)
                    end)
                    ]]
                end
            end)
        end
        list_forums()

    end))

    self.nav:navigationBar():setBarTintColor(objc.EQEMainView:themeColor())
    self.nav:navigationBar():setTintColor(objc.UIColor:whiteColor())
    self.nav:navigationBar():setTitleTextAttributes{[C.NSForegroundColorAttributeName] = objc.UIColor:whiteColor()}
    self.view = self.nav:view()
end

function page:navpressed(is_showing_list)
end

return page
