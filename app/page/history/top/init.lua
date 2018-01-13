local history = require 'history'

return function(query, render)
    local tbl = ui.table:new()
    return function(m)
        tbl.m:setFrame(m:view():bounds())

        local songs = history.db:exec(query)

        tbl.songs = songs
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
            local text, detailText = render(song)
            m:textLabel():setText(text)
            m:detailTextLabel():setText(detailText or song.count..' spins')

            if icon then
                local scale = 22
                scale = scale/math.max(icon:size().width, icon:size().height)
                m:imageView():setTransform(C.CGAffineTransformMakeScale(scale, scale))
            end
        end



        m:view():addSubview(tbl.m)
    end, tbl
end
