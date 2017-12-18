local history = require 'history'

return function(query, render)
    return function(m)
        local tbl = ui.table:new()
        tbl.m:setFrame(m:view():bounds())

        local songs = history.db:exec(query)

        tbl.section = {#songs}

        local super = tbl.cell.mnew
        function tbl.cell.mnew(_)
            local m = super(_)
            m:imageView():setClipsToBounds(true)
            m:imageView():layer():setCornerRadius(5)
            return m
        end

        local icons = {}
        function tbl.cell.onshow(_, m, section, row)
            local song = songs[row]
            local icon = icons[song.appid]
            if not icon then
                local path = history.getapp(song.appid).icon
                local img = objc.UIImage:imageWithContentsOfFile(path)
                if img then
                    icon = img:retain()
                else
                    icon = true
                end
                icons[song.appid] = icon
            end
            if icon == true then
                icon = nil
            end
            m:imageView():setImage(icon)
            m:textLabel():setText(render(song))
            m:detailTextLabel():setText(song.count..' spins')

            if icon then
                local scale = 22
                scale = scale/math.max(icon:size().width, icon:size().height)
                m:imageView():setTransform(C.CGAffineTransformMakeScale(scale, scale))
            end
        end



        m:view():addSubview(tbl.m)
    end
end
