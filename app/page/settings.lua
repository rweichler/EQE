local page = {}
page.title = 'Settings'
page.icon = IMG('ios7-cog-outline.png', PAGE_ICON_COLOR):retain()
page.hide_nav_button = true

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
                title = 'Enable mediaserverd hook',
                subtitle = 'Handles processing of all audio.',
                cb = function(enabled)
                    if enabled == nil then
                        return IPC('return GET_ENABLED()') == 'true'
                    else
                        IPC('SET_ENABLED('..tostring(enabled)..')')
                    end
                end,
            },

        }
        tbl.section = {#items}
        tbl.m:setFrame(m:view():bounds())
        local super = tbl.cell.mnew
        function tbl.cell.mnew(_)
            local m = super(_)
            local switch = objc.UISwitch:alloc():init()
            m:setAccessoryView(switch)

            local self = objc.getref(m)
            local target = ns.target:new()
            function target.onaction()
                if not self.item then return end
                local on = objc.weirdbool(switch:isOn())
                self.item.cb(on)
            end
            switch:addTarget_action_forControlEvents(target.m, target.sel, UIControlEventValueChanged)

            return m
        end
        function tbl.cell.onshow(_, m, section, row)
            local self = objc.getref(m)
            local item = items[row]
            m:textLabel():setText(item.title)
            m:detailTextLabel():setText(item.subtitle)
            m:accessoryView():setOn(item.cb())

            self.item = item
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
