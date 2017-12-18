local page = {}
page.title = 'Playback history'
page.icon = IMG('ios7-paper.png', PAGE_ICON_COLOR):retain()
page.hide_nav_button = true

local history = require 'history'
history.init('r')

function page:init()
    local function push(f, title)
        self.nav:pushViewController_animated(VIEWCONTROLLER(f, title), true)
    end

    local vc = VIEWCONTROLLER(function(m)
        local target = ns.target:new()
        target.onaction = function()
            TOGGLE_NAV()
        end

        local nav_button = new_nav_button(0, 0)
        nav_button.ontoggle = TOGGLE_NAV

        local item = objc.UIBarButtonItem:alloc():initWithCustomView(nav_button.m)
        m:navigationItem():setLeftBarButtonItem(item)

        local tbl = ui.table:new()
        local items = {
            {
                icon = IMG('ios7-time.png', PAGE_ICON_COLOR):retain(),
                title = 'Recent tracks',
                cb = require 'page.history.recent',
            },
            {
                icon = IMG('mus/note.png', PAGE_ICON_COLOR):retain(),
                title = 'Top tracks',
                cb = require 'page.history.top.tracks',
            },
            {
                icon = IMG('mus/artist.png', PAGE_ICON_COLOR):retain(),
                title = 'Top artists',
                cb = require 'page.history.top.artists',
            },
            {
                icon = IMG('mus/album.png', PAGE_ICON_COLOR):retain(),
                title = 'Top albums',
                cb = require 'page.history.top.albums',
            },
            {
                icon = IMG('ios7-paper.png', PAGE_ICON_COLOR):retain(),
                title = 'App whitelist',
                cb = require 'page.history.whitelist',
            },

        }
        tbl.section = {#items}
        tbl.m:setFrame(m:view():bounds())
        local super = tbl.cell.mnew
        function tbl.cell.mnew(_)
            local m = super(_)
            m:textLabel():setFont(objc.UIFont:fontWithName_size('HelveticaNeue', 22))
            m:textLabel():setTextColor(COLOR(0xffffffe0))
            return m
        end
        function tbl.cell.getheight()
            return 64
        end
        function tbl.cell.onshow(_, m, section, row)
            local item = items[row]
            m:textLabel():setText(item.title)
            local scale = 22
            scale = scale/math.max(item.icon:size().width, item.icon:size().height)
            m:imageView():setTransform(C.CGAffineTransformMakeScale(scale, scale))
            m:imageView():setImage(item.icon)
        end
        function tbl.cell.onselect(_, section, row)
            local item = items[row]
            if item.cb then
                push(item.cb, item.title)
            end
        end

        m:view():addSubview(tbl.m)

    end, page.title)
    self.nav = objc.UINavigationController:alloc():initWithRootViewController(vc)

    self.nav:navigationBar():setBarTintColor(objc.EQEMainView:themeColor())
    self.nav:navigationBar():setTintColor(objc.UIColor:whiteColor())
    self.nav:navigationBar():setTitleTextAttributes{[C.NSForegroundColorAttributeName] = objc.UIColor:whiteColor()}
    self.view = self.nav:view()
end
return page
