local history = require 'history'

return function(m)
    local table = ui.table:new()
    table.m:setFrame(m:view():bounds())
    table.items = {{}}

    setmetatable(table.items[1], {
        __len = function(t)
            return history.count()
        end,
    })

    local super = table.cell.mnew
    function table.cell.mnew(_)
        local m = super(_)
        m:setBackgroundColor(table.m:backgroundColor())
        m:textLabel():setTextColor(objc.UIColor:whiteColor())
        m:detailTextLabel():setTextColor(objc.UIColor:whiteColor())
        m:textLabel():setBackgroundColor(table.m:backgroundColor())
        m:imageView():setClipsToBounds(true)
        m:imageView():layer():setCornerRadius(5)
        return m
    end
    local function bad(song)
        return song.deleted == 1 or song.duration < history.minimum_duration
    end
    local super = table.cell.getheight
    function table.cell.getheight(_, section, row)
        local song = history.get(history.count() - row + 1)
        if bad(song) then
            return 0
        else
            return super(_, section, row)
        end
    end
    function table.cell.estimateheight(_, section, row)
        return 44
    end

    local icons = {}
    function table.cell.onshow(_, m, section, row)
        local song = history.get(history.count() - row + 1)
        if bad(song) then
            m:textLabel():setText(nil)
            m:detailTextLabel():setText(nil)
            m:imageView():setImage(nil)
            m:setHidden(true)
        else
            m:setHidden(false)
            m:textLabel():setText(song.title)
            m:detailTextLabel():setText((song.artist or 'NULL')..' - '..(song.album or 'NULL'))
            if not icons[song.appid] then
                local path = history.getapp(song.appid).icon
                print(path)
                local img = objc.UIImage:imageWithContentsOfFile(path)
                if img then
                    icons[song.appid] = img:retain()
                end
            end
            local icon = icons[song.appid]
            m:imageView():setImage(icon)
            if icon then
                local siz = 32
                m:imageView():setTransform(C.CGAffineTransformMakeScale(siz/icon:size().width, siz/icon:size().height))
            end
        end
    end

    m:view():addSubview(table.m)
end
