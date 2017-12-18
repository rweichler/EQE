local view_thread = require 'page.forum.posts'
local json = require 'dkjson'
local relative_time = require 'relative_time'

return function(forum, push, loadicon)
    return function(m)
        m:view():setBackgroundColor(objc.EQEMainView:themeColor())

        local tbl = ui.table:new()
        tbl.m:setBackgroundColor(objc.EQEMainView:themeColor())
        tbl.m:setSeparatorColor(objc.UIColor:clearColor())
        tbl.items = {{}}
        tbl.m:setHidden(true)
        tbl.m:setFrame(m:view():bounds())
        --tbl.m:setAllowsSelection(false)
        m:view():addSubview(tbl.m)
        tbl.m:release()

        local heights = {}

        local list_threads

        local load_fail = require 'vc.load_failed'.new()
        function load_fail.onretry()
            list_threads()
        end
        m:view():addSubview(load_fail.m)

        local refresh_control = objc.UIRefreshControl:alloc():init()
        local refresh_target = ns.target:new()
        function refresh_target.onaction()
            list_threads(function()
                heights = {}
                refresh_control:endRefreshing()
                tbl:refresh()
            end)
        end
        refresh_control:addTarget_action_forControlEvents(refresh_target.m, refresh_target.sel, UIControlEventValueChanged)
        tbl.m:addSubview(refresh_control)
        refresh_control:release()
        --refresh_target.m:release()

        local function make_label(font, siz)
            local label = objc.UILabel:alloc():init()
            label:setFont(objc.UIFont:fontWithName_size(font, siz))
            label:setNumberOfLines(0)
            label:setBackgroundColor(objc.UIColor:clearColor())
            label:setTextColor(objc.UIColor:whiteColor())
            return label
        end
        local height_label = make_label('HelveticaNeue', 16)
        local min_height = 48
        local avatar_siz = 32
        local avatar_pad = (min_height - avatar_siz)/2
        local mid = 2
        local pad = 6
        local title_frame = ffi.new('CGRect', {min_height, pad}, {m:view():frame().size.width - min_height*2, 0})

        local username_height_label = make_label('HelveticaNeue-Light', 8)
        username_height_label:setNumberOfLines(1)

        local loading = true
        local function pushposts(self)
            if loading then return end
            push(view_thread(self.parent.thread, self.last, push))
        end

        local c = COLOR(0xffffff06):retain()
        local function press(self, pressed)
            self.m:setBackgroundColor(pressed and c or objc.UIColor:clearColor())
        end

        local super = tbl.cell.mnew
        function tbl.cell.mnew(_)
            local m = super(_)
            local mm = m
            m:setBackgroundColor(objc.UIColor:clearColor())
            m:textLabel():setTextColor(objc.UIColor:whiteColor())
            m:detailTextLabel():setTextColor(objc.UIColor:whiteColor())
            m:detailTextLabel():setFont(m:detailTextLabel():font():fontWithSize(8))
            m:textLabel():setBackgroundColor(objc.UIColor:clearColor())

            local self = objc.getref(m)
            local m = m:contentView()


            self.avatar_button = ui.button:new()
            self.avatar_button.m:setFrame{{0, 0},{min_height,0}}
            self.avatar_button.onpress = press
            m:addSubview(self.avatar_button.m)

            self.mid_button = ui.button:new()
            self.mid_button.m:setFrame{{min_height,0},{m:frame().size.width - min_height*2,0}}
            self.mid_button.ontoggle = pushposts
            self.mid_button.onpress = press
            m:addSubview(self.mid_button.m)

            self.last_button = ui.button:new()
            self.last_button.last = true
            self.last_button.m:setFrame{{m:frame().size.width - min_height,0},{min_height,0}}
            self.last_button.onpress = press
            self.last_button.ontoggle = pushposts
            m:addSubview(self.last_button.m)



            self.title = make_label('HelveticaNeue', 16)
            self.title:setTextColor(COLOR(0xffffffa5))
            self.title:setUserInteractionEnabled(false)
            m:addSubview(self.title)

            self.avatar = objc.UIImageView:alloc():initWithFrame{{avatar_pad,avatar_pad},{avatar_siz,avatar_siz}}

            self.avatar:setUserInteractionEnabled(false)
            self.avatar:setClipsToBounds(true)
            self.avatar:layer():setCornerRadius(8)
            m:addSubview(self.avatar)

            local color = 0x44aaff

            self.username = make_label('HelveticaNeue-Light', 11)
            self.username:setUserInteractionEnabled(false)
            self.username:setNumberOfLines(1)
            self.username:setFrame{{min_height, 0},{0,0}}
            self.username:setTextColor(COLOR(color*0x100 + 0x88))
            m:addSubview(self.username)

            self.alienblue = objc.UIView:alloc():init()
            self.alienblue:setUserInteractionEnabled(false)
            self.alienblue:layer():setBorderWidth(1)
            self.alienblue:layer():setBorderColor(COLOR(0xffffff18):CGColor())
            self.alienblue:layer():setCornerRadius(5)
            m:addSubview(self.alienblue)

            self.replies = make_label('HelveticaNeue-Light', 10)
            self.replies:setUserInteractionEnabled(false)
            self.replies:setNumberOfLines(1)
            self.replies:setTextColor(COLOR(color*0x100 + 0x88))
            self.replies:setTextAlignment(NSTextAlignmentCenter)
            m:addSubview(self.replies)

            self.time = make_label('HelveticaNeue-Light', 9)
            self.time:setUserInteractionEnabled(false)
            self.time:setNumberOfLines(1)
            self.time:setTextColor(COLOR(0xffffff44))
            self.time:setTextAlignment(NSTextAlignmentCenter)
            m:addSubview(self.time)

            return mm
        end

        function tbl.cell.onselect(_, section, row)
        end

        function list_threads(cb)
            load_fail:start_load(m:view():frame().size)
            HTTP(BASE_URL..'/api/forum/view_forum?id='..forum.id, {convert = 'json'}, function(info, status, headers)
                if info and status == 200 and not info.error then
                    tbl.items[1] = info.threads
                    function tbl.cell.onshow(_, m, section, row)
                        if loading then return end
                        local thread = tbl.items[section][row]
                        --m:textLabel():setText(thread.title)
                        --m:detailTextLabel():setText('By '..thread.author_username..', '..thread.num_replies..' replies')
                        --m:imageView():setImage(thread.icon)

                        local self = objc.getref(m)
                        self.thread = thread

                        self.title:setFrame(title_frame)
                        self.title:setText(thread.title)
                        self.title:sizeToFit()

                        self.username:setFrame{{min_height, self.title:frame().origin.y + self.title:frame().size.height + mid},{0,0}}
                        self.username:setText(thread.author_username)
                        self.username:sizeToFit()

                        self.avatar:setImage(thread.icon)

                        local w = min_height - pad*2
                        local h = min_height/2.5
                        self.alienblue:setFrame{{m:frame().size.width - w - pad, (m:frame().size.height - h)/2}, {w, h}}

                        self.replies:setText(thread.num_replies < 1000 and tostring(thread.num_replies) or string.format('%.1fk', math.floor(thread.num_replies/100)/10))
                        self.replies:setFrame(self.alienblue:frame())

                        self.time:setText(relative_time(os.time() - thread.last_post_date, true))
                        self.time:sizeToFit()
                        local frame = self.alienblue:frame()
                        frame.origin.y = frame.origin.y - self.time:frame().size.height
                        frame.size.height = self.time:frame().size.height
                        self.time:setFrame(frame)

                        local frame = self.avatar_button.m:frame()
                        frame.size.height = m:frame().size.height
                        self.avatar_button.m:setFrame(frame)
                        self.avatar_button.parent = self

                        local frame = self.mid_button.m:frame()
                        frame.size.height = m:frame().size.height
                        self.mid_button.m:setFrame(frame)
                        self.mid_button.parent = self

                        local frame = self.last_button.m:frame()
                        frame.size.height = m:frame().size.height
                        self.last_button.m:setFrame(frame)
                        self.last_button.parent = self
                    end
                    function tbl.cell.getheight(_, section, row)
                        local thread = tbl.items[section][row]
                        if not heights[row] then
                            local frame = height_label:frame()
                            height_label:setFrame(title_frame)
                            height_label:setText(thread.title)
                            height_label:sizeToFit()

                            username_height_label:setText(thread.author_username)
                            username_height_label:sizeToFit()

                            heights[row] = math.max(min_height, pad*2 + mid + height_label:frame().size.height + username_height_label:frame().size.height)
                        end
                        return heights[row]
                    end
                    if cb then
                        cb()
                    else
                        tbl:refresh()
                    end
                    loading = false
                    for i,v in ipairs(info.threads) do
                        if v.author_avatar then
                            loadicon(BASE_URL..'/res/dynamic/avatar/'..v.author_username..'-icon.png', function(icon)
                                v.icon = icon
                                local rows = objc.toobj{objc.NSIndexPath:indexPathForRow_inSection(i - 1, 0)}
                                tbl.m:reloadRowsAtIndexPaths_withRowAnimation(rows, UITableViewRowAnimationNone)
                            end)
                        end
                    end
                    tbl.m:setHidden(false)
                    load_fail:stop()
                    load_fail.m:removeFromSuperview()
                else
                    local msg
                    if info then
                        msg = info.error or 'Got HTTP error code: '..status
                    else
                        msg = status
                    end
                    load_fail:set_message(msg, m:view():frame().size)
                end
            end)
        end
        list_threads()
    end, forum.name
end
