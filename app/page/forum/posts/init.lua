local json = require 'dkjson'
local md = require 'md'
local relative_time = require 'relative_time'

_G.get_avatar = require 'req.avatar'

return function(thread, show_last_page, push)
    return function(m)
        m:view():setBackgroundColor(objc.EQEMainView:themeColor())

        local tbl = ui.table:new()
        post_tbl = tbl
        tbl.m:setBackgroundColor(objc.EQEMainView:themeColor())
        tbl.m:setSeparatorColor(COLOR(0xffffff33))
        tbl.items = {{}}
        tbl.m:setFrame(m:view():bounds())
        tbl.m:setAllowsSelection(false)
        local clearv = objc.UIView:alloc():init()
        tbl.m:setTableFooterView(clearv)
        tbl.m:setHidden(true)
        m:view():addSubview(tbl.m)
        tbl.m:release()

        local list_posts
        local load_fail = require 'vc.load_failed'.new()
        function load_fail.onretry()
            list_posts()
        end
        m:view():addSubview(load_fail.m)

        local username_height = 15
        local replyedit_height = 0--32
        local avatar_size = 44
        local avatar_pad = 8

        local heights = {}
        local avatar_heights = {}
        local update_height
        local function create_md(i, flags)
            local x = avatar_pad*2 + avatar_size - 4
            local right = 10
            local r = md.new(tbl.m:bounds().size.width - x - right)
            local frame = r.m:frame()
            frame.origin.x = x
            frame.origin.y = username_height + 4
            r.m:setFrame(frame)
            function r.onupdate()
                update_height(heights, i, r.m:bounds().size.height)
                if not flags or flags.done then
                    flags = nil
                    tbl:reload(i)
                end
            end
            return r
        end

        local pages = {}
        dem_pages = pages

        local function get_height(i)
            local replyedit_height = 0
            if LOGIN and tbl.items[1][i].user == LOGIN.id then
                replyedit_height = 32
            end
            return avatar_pad + username_height + (heights[i] or 0) + replyedit_height
        end
        local function get_real_height(row)
            return math.max((avatar_heights[row] or 0) + avatar_pad * 2, get_height(row))
        end
        function update_height(t, k, v)
            t[k] = v
        end
        local function onupdate(self)
            local row = self.row
            update_height(heights, row, self.m:bounds().size.height)
            DISPATCH(function()
                tbl:reload(row)
            end)
        end
        local function edittoggle(self)
            local post = self.parent.post
            require 'vc.post_reply'(m, post.id, function(json)
                post.body = json.body
                post.md:init(post.body)
            end, post.body)
        end
        local function profiletoggle(self)
            local post = self.parent.post
            local f = require 'page.forum.user'(post.user)
            push(f, post.username)
        end
        local super = tbl.cell.mnew
        function tbl.cell.mnew(_)
            local m = super(_)
            m:setBackgroundColor(tbl.m:backgroundColor())
            m:textLabel():setTextColor(objc.UIColor:whiteColor())
            m:detailTextLabel():setTextColor(objc.UIColor:whiteColor())
            m:detailTextLabel():setFont(m:detailTextLabel():font():fontWithSize(8))
            m:detailTextLabel():setNumberOfLines(0)
            m:textLabel():setBackgroundColor(tbl.m:backgroundColor())
            m:setSeparatorInset{0, avatar_size + avatar_pad*2, 0, 8}

            local self = objc.getref(m)
            self.img_view = objc.UIImageView:alloc():initWithFrame{{avatar_pad, avatar_pad},{avatar_size,avatar_size}}
            m:addSubview(self.img_view)
            self.img_view:setClipsToBounds(true)
            self.img_view:layer():setCornerRadius(4)
            self.img_view:setImage(nil)

            self.username_label = objc.UILabel:alloc():initWithFrame{{avatar_pad*2 + avatar_size, avatar_pad}, {0, 0}}
            self.username_label:setTextColor(objc.UIColor:whiteColor())
            self.username_label:setBackgroundColor(objc.UIColor:clearColor())
            self.username_label:setFont(objc.UIFont:fontWithName_size('HelveticaNeue-Bold', username_height))
            m:addSubview(self.username_label)

            self.time_label = objc.UILabel:alloc():init()
            self.time_label:setTextColor(objc.UIColor:grayColor())
            self.time_label:setBackgroundColor(objc.UIColor:clearColor())
            self.time_label:setFont(objc.UIFont:fontWithName_size('HelveticaNeue', 12))
            m:addSubview(self.time_label)

            self.edit_button = ui.button:new()
            self.edit_button:setTitle('Edit')
            self.edit_button:setColor(COLOR(0xaaccffcc))
            self.edit_button:setFont('HelveticaNeue-Light', 10)
            self.edit_button.m:setBackgroundColor(COLOR(0xffffff03))
            self.edit_button.m:layer():setBorderWidth(1)
            self.edit_button.m:layer():setBorderColor(COLOR(0xffffff22):CGColor())
            self.edit_button.m:setFrame{{0,0},{36,20}}
            self.edit_button.m:setHidden(true)
            self.edit_button.ontoggle = edittoggle
            self.edit_button.parent = self
            m:addSubview(self.edit_button.m)

            self.profile_button = ui.button:new()
            self.profile_button.ontoggle = profiletoggle
            self.profile_button.parent = self
            m:addSubview(self.profile_button.m)

            return m
        end
        weakt.tbl = tbl

        local page_control = require 'page.forum.posts.page_control'(m)
        function page_control.jumpto(_, pageno)
            local page = pages[pageno]
            if page then
                tbl:scrollto(page.row)
            else
                list_posts(pageno)
            end
        end
        m:view():addSubview(page_control.m)

        local item

        function list_posts(pageno)
            tbl.m:setHidden(true)
            m:view():addSubview(load_fail.m)
            pageno = pageno or (show_last_page and thread.num_pages or 1)
            load_fail:start_load(m:view():frame().size)
            HTTP(BASE_URL..'/api/forum/view_thread?id='..thread.id..'&page='..pageno, {convert = 'json'}, function(info, status, headers)
                if not(info and status == 200) or (info and info.error) then
                    local msg
                    if info then
                        msg = info.error or 'Got HTTP error code: '..status
                    else
                        msg = status
                    end
                    load_fail:set_message(msg, m:view():frame().size)
                    return
                end

                if not item then
                    local negativeSpace = objc.UIBarButtonItem:alloc():initWithBarButtonSystemItem_target_action(UIBarButtonSystemItemFixedSpace, nil, nil)
                    negativeSpace:setWidth(-16)

                    local button = new_nav_button(0, 0, IMG('ios7-compose-outline.png'))
                    item = objc.UIBarButtonItem:alloc():initWithCustomView(button.m)
                    m:navigationItem():setRightBarButtonItems{negativeSpace, item}

                    local function cb(post)
                        list_posts(post.page)
                    end

                    function button.ontoggle()
                        if LOGIN then
                            require 'vc.post_reply'(m, thread, cb)
                        else
                            local nav = require 'vc.login'(function(login)
                                if login then
                                    LOG_IN(login)
                                    require 'vc.post_reply'(m, thread, cb)
                                end
                            end)
                            m:presentModalViewController_animated(nav, true)
                        end
                    end
                end

                pages = {}
                pages.first = info
                pages.last = info
                pages[info.page] = info
                info.row = 1

                tbl.items[1] = {}
                for i,v in ipairs(info.posts) do
                    v.page = info.page
                    table.insert(tbl.items[1], v)
                end
                page_control:update(info.page, info.num_pages)

                local current_page_no
                local loadnext, loadprev = objc.UIView:alloc():init(), objc.UIView:alloc():init()
                local added, added2 = false, false
                local pwned, pwned2 = false, false
                local didit, didit2 = false, false
                local loadheight = 64

                local endscrollcb

                function tbl:enddrag()
                    if pwned2 and not didit2 then
                        local off = tbl.m:contentOffset()
                        didit2 = true
                        loadprev:setBackgroundColor(objc.UIColor:greenColor())
                        loadprev:removeFromSuperview()
                        loadprev:setFrame{{0,0},{tbl.m:contentSize().width,loadheight}}
                        tbl.m:setTableHeaderView(loadprev)

                        print(tostring(off)..' --> '..tostring(tbl.m:contentOffset()))
                        off.y = off.y + loadheight
                        tbl.m:setContentOffset(off)

                        HTTP(BASE_URL..'/api/forum/view_thread?id='..thread.id..'&page='..(pages.first.page - 1), {convert = 'json'}, function(json, status, headers)
                            for i=pages.first.page,math.huge do
                                local page = pages[i]
                                if not page then break end
                                page.row = page.row + #json.posts
                            end
                            pages[json.page] = json
                            pages.first = json
                            json.row = 1
                            local flags = {done = false}
                            local newheights = {}
                            local newavatarheights = {}
                            for k,v in pairs(heights) do
                                newheights[k + #json.posts] = v
                            end
                            for k,v in pairs(avatar_heights) do
                                newavatarheights[k + #json.posts] = v
                            end
                            heights = newheights
                            avatar_heights = newavatarheights
                            for i=#json.posts,1,-1 do
                                local v = json.posts[i]
                                v.page = json.page
                                table.insert(tbl.items[1], 1, v)

                                v.md = create_md(i, flags)
                                v.md:init(v.body)
                            end
                            local off = tbl.m:contentOffset()
                            tbl:refresh()
                            tbl.m:setTableHeaderView(nil)
                            for i=1,#json.posts do
                                off.y = off.y + get_real_height(i)
                            end
                            tbl.m:setContentOffset(off)
                            flags.done = true
                            added2 = false
                            pwned2 = false
                            didit2 = false
                        end)
                    end
                    if pwned and not didit then
                        didit = true
                        loadnext:setBackgroundColor(objc.UIColor:greenColor())
                        loadnext:removeFromSuperview()
                        loadnext:setFrame{{0,0},{tbl.m:contentSize().width,loadheight}}
                        tbl.m:setTableFooterView(loadnext)

                        local page = pages.last
                        local reloading, nextpage
                        if page.page_is_full then
                            reloading = false
                            nextpage = page.page + 1
                        else
                            reloading = true
                            nextpage = page.page
                        end
                        HTTP(BASE_URL..'/api/forum/view_thread?id='..thread.id..'&page='..nextpage, {convert = 'json'}, function(json, status, headers)
                            local flags = {done = false}
                            if not reloading then
                                pages[json.page] = json
                                if pages.last.page < json.page then
                                    json.row = pages.last.row + #pages.last.posts
                                    pages.last = json
                                elseif pages.first.page > json.page then
                                    for i=pages.first.page,math.huge do
                                        if not pages[i] then break end
                                        pages[i].row = pages[i].row + #json.posts
                                    end
                                    pages.first = json
                                    json.row = 1
                                end
                                local rows = {}
                                local old_len = #tbl.items[1]
                                for i,v in ipairs(json.posts) do
                                    local real_i = old_len + i
                                    v.page = json.page

                                    table.insert(tbl.items[1], v)
                                    table.insert(rows, real_i)

                                    v.md = create_md(real_i, flags)
                                    v.md:init(v.body)
                                end

                                tbl:insert(rows)
                            else
                                local old_page = pages[json.page]
                                pages[json.page] = json
                                local offset = #tbl.items[1] - #old_page.posts
                                local reload_rows = {}
                                for i=1,#old_page.posts do
                                    local v = json.posts[i]
                                    v.page = json.page

                                    local old = tbl.items[1][offset + i]
                                    if not(old.id == v.id and old.body == v.body) then
                                        tbl.items[1][offset + i] = v
                                        table.insert(reload_rows, offset + i)

                                        v.md = create_md(offset + i, flags)
                                        v.md:init(v.body)
                                    end
                                end

                                local insert_rows = {}
                                for i=#old_page.posts+1,#json.posts do
                                    local v = json.posts[i]
                                    v.page = json.page
                                    table.insert(tbl.items[1], v)
                                    local real_i = #tbl.items[1]
                                    table.insert(insert_rows, real_i)

                                    v.md = create_md(real_i, flags)
                                    v.md:init(v.body)
                                end
                                tbl:insert(insert_rows)
                                tbl:reload(reload_rows)
                            end
                            flags.done = true
                            tbl.m:setTableFooterView(clearv)
                            added = false
                            pwned = false
                            didit = false
                        end)
                    end
                end

                function tbl:onscroll(starting)
                    if tbl.ignore_scroll then return end
                    page_control:show(starting)

                    -- NEXT refresh control

                    local endy
                    local loady
                    if tbl.m:contentSize().height > tbl.m:frame().size.height - tbl.m:contentInset().top then
                        endy = tbl.m:contentOffset().y + tbl.m:frame().size.height - tbl.m:contentSize().height
                        loady = tbl.m:contentSize().height
                    else
                        endy = tbl.m:contentOffset().y + tbl.m:contentInset().top
                        loady = tbl.m:frame().size.height - tbl.m:contentInset().top
                    end
                    if not didit then
                        if endy > 0 then
                            if not added then
                                loadnext:setFrame{{0, loady},{tbl.m:contentSize().width, loadheight}}
                                loadnext:setBackgroundColor(objc.UIColor:redColor())
                                tbl.m:addSubview(loadnext)
                                added = true
                            end
                            if endy > loadheight then
                                if self.dragging and not pwned then
                                    loadnext:setBackgroundColor(objc.UIColor:cyanColor())
                                    pwned = true
                                end
                            elseif added and pwned then
                                loadnext:setBackgroundColor(objc.UIColor:redColor())
                                pwned = false
                            end
                        else
                            loadnext:removeFromSuperview()
                            added = false
                            pwned = false
                        end
                    end

                    -- PREV refresh control

                    if pages.first.page == 1 then return end

                    local endy = -(tbl.m:contentOffset().y + tbl.m:contentInset().top)

                    if not didit2 then
                        if endy > 0 then
                            if not added2 then
                                loadprev:setFrame{{0,-loadheight},{tbl.m:contentSize().width, loadheight}}
                                loadprev:setBackgroundColor(objc.UIColor:redColor())
                                tbl.m:addSubview(loadprev)
                                added2 = true
                            end
                            if endy > loadheight then
                                if self.dragging and not pwned2 then
                                    loadprev:setBackgroundColor(objc.UIColor:cyanColor())
                                    pwned2 = true
                                end
                            elseif added2 and pwned2 then
                                loadprev:setBackgroundColor(objc.UIColor:redColor())
                                pwned2 = false
                            end
                        else
                            loadprev:removeFromSuperview()
                            added2 = false
                            pwned2 = false
                        end
                    end

                end
                function tbl:endscroll()
                    page_control:hide(1)
                    if endscrollcb then
                        endscrollcb()
                        endscrollcb = nil
                    end
                end
                function tbl.cell.onshow()
                end
                function tbl.cell:getheight(section, row)
                    return get_real_height(row)
                end
                tbl:refresh()
                function tbl.cell:onshow(m, section, row)
                    local post = tbl.items[section][row]
                    if m:textLabel():text() then
                        m:textLabel():setText(nil)
                        m:detailTextLabel():setText(nil)
                    end
                    local self = objc.getref(m)
                    self.post = post
                    if not(post.page == current_page_no) then
                        current_page_no = post.page
                        page_control:update(post.page)
                    end
                    self.postid = post.id
                    if self.md and self.md.parent == self then
                        self.md.m:removeFromSuperview()
                        self.md.parent = nil
                        self.md = nil
                    end
                    if post.md then
                        m:contentView():addSubview(post.md.m)
                        self.md = post.md
                        self.md.parent = self
                    end
                    self.username_label:setText(post.username)
                    self.username_label:sizeToFit()
                    self.time_label:setText(relative_time(os.time() - post.date, true))
                    self.time_label:sizeToFit()
                    local siz = self.time_label:frame().size
                    self.time_label:setFrame{{m:frame().size.width - siz.width - avatar_pad, avatar_pad},siz}
                    if post.avatar then
                        get_avatar(post.username, function(img, was_cached)
                            if not(self.postid == post.id) then return end

                            local height = avatar_size * img:size().height / img:size().width
                            self.img_view:setImage(img)
                            self.img_view:setFrame{self.img_view:frame().origin,{avatar_size, height}}

                            update_height(avatar_heights, row, height)
                            if not was_cached and avatar_heights[row] + avatar_pad * 2 > get_height(row) then
                                tbl:reload(row)
                            end
                            self.profile_button.m:setFrame{{0,0},{avatar_size + avatar_pad*2, math.min(m:frame().size.height, height + avatar_pad*2)}}
                        end)
                    else
                        self.img_view:setImage(nil)
                    end
                    if LOGIN and post.user == LOGIN.id then
                        local siz = self.edit_button.m:frame().size
                        self.edit_button.m:setFrame{{m:frame().size.width-siz.width-6, m:frame().size.height-siz.height-6},siz}
                        self.edit_button.m:setHidden(false)
                    else
                        self.edit_button.m:setHidden(true)
                    end
                    self.profile_button.m:setFrame{{0,0},{avatar_size + avatar_pad*2, math.min(m:frame().size.height, (avatar_heights[row] or avatar_size) + avatar_pad*2)}}
                end
                for i,v in ipairs(info.posts) do
                    v.md = create_md(i)
                    v.md:init(v.body)
                end
                tbl.ignore_scroll = true
                tbl.m:setContentOffset_animated({0, -tbl.m:contentInset().top}, false)
                tbl.ignore_scroll = false
                tbl.m:setHidden(false)
                load_fail:stop()
                load_fail.m:removeFromSuperview()
            end)
        end
        list_posts()

    end, thread.title
end
