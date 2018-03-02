local history = require 'history'

return function(m)
    local tbl = ui.table:new()
    tbl.m:setFrame(m:view():bounds())

    local apps = history.db:exec('SELECT * FROM app')

    tbl.section = {#apps + 2}

    local super = tbl.cell.mnew
    function tbl.cell.mnew(_)
        local m = super(_)
        m:imageView():setClipsToBounds(true)
        m:imageView():layer():setCornerRadius(5)
        local switch = objc.UISwitch:alloc():init()
        m:setAccessoryView(switch)

        local self = objc.getref(m)
        local target = ns.target:new()
        function target.onaction()
            local on = objc.weirdbool(switch:isOn())
            if self.app then
                on = on and 1 or 0
                history.db:exec('UPDATE app SET enabled='..on..' WHERE id='..self.app.id)
                self.app.enabled = on
            else
                on = on and 'true' or 'false'
                if self.is_local then
                    IPCD('SET_SHOULD_I_SPIN(true, '..on..')')
                else
                    IPCD('SET_SHOULD_I_SPIN(false, '..on..')')
                end
            end
        end
        switch:addTarget_action_forControlEvents(target.m, target.sel, UIControlEventValueChanged)

        return m
    end

    local icons = {}
    function tbl.cell.onshow(_, m, section, row)
        local self = objc.getref(m)

        if row <= 2 then
            self.app = nil
            m:imageView():setImage(nil)
            if row == 1 then
                m:textLabel():setText('Enable (locally)')
                m:accessoryView():setOn(IPCD('return SHOULD_I_SPIN(true)') == 'true')
                self.is_local = true
            elseif row == 2 then
                m:textLabel():setText('Enable (for online)')
                m:accessoryView():setOn(IPCD('return SHOULD_I_SPIN(false)') == 'true')
                self.is_local = false
            end
            m:detailTextLabel():setText(nil)
        else
            self.is_local = nil

            local app = apps[row - 2]
            self.app = app

            local icon = icons[app.id]
            if not icon then
                local path = app.icon
                local img = objc.UIImage:imageWithContentsOfFile(path)
                if img then
                    icon = img:retain()
                else
                    icon = true
                end
                icons[app.id] = icon
            end
            if icon == true then
                icon = nil
            end
            m:imageView():setImage(icon)
            m:textLabel():setText(app.name)
            m:detailTextLabel():setText(app.bundle)
            m:accessoryView():setOn(app.enabled == 1 and true or false)

            if icon then
                local scale = 22
                scale = scale/math.max(icon:size().width, icon:size().height)
                m:imageView():setTransform(C.CGAffineTransformMakeScale(scale, scale))
            end
        end
    end



    m:view():addSubview(tbl.m)
end
