local md = require 'md'
local str_esc = require 'str_esc'

local page = {}
page.title = 'Update'
page.icon = IMG('ios7-download.png', PAGE_ICON_COLOR):retain()

local update_version_path = LUA_PATH..'/../../db/update_dl_version.lua'
local update_dl_path = LUA_PATH..'/../../db/update.deb'
local current_version = require 'config.default.version'

-- this is for redundancy, in case eqe.fm ever does
-- down we can have fallbacks
local check_urls = {
    BASE_URL..'/api/deb_version',
}

local function num_good(j, c)
    return type(j) == 'number' and type(c) == 'number' and j < c
end

local function check_update(cb, idx)
    HTTP(check_urls[idx], {
        convert = 'json',
        uri_args = {
            current = current_version,
        },
    }, function(json, status, headers)
        if not json and check_urls[idx + 1] then
            check_update(cb, idx + 1)
            return
        end

        local err
        if not json or json.error then
            err = json and json.error or 'Check failed. Probably bad internet connection?'
        elseif json.version == current_version or num_good(json.version, current_version) then
            err = 'EQE is up to date.'
        end
        if err then
            cb(nil, err)
        else
            cb(json)
        end
    end)
end

function CHECK_UPDATE(cb)
    check_update(cb, 1)
end

function page:init()
    local scroll = ui.scroll:new()
    page.view = scroll.m
    scroll.m:setBackgroundColor(objc.EQEMainView:themeColor())
    scroll.m:setFrame(CONTENT_FRAME)
    local FW = CONTENT_FRAME.size.width
    local pad = 22

    local message_width = FW * 3/4
    local message_height = 64
    local message = objc.UILabel:alloc():initWithFrame{{(FW - message_width)/2, pad},{message_width, message_height}}
    message:setFont(objc.UIFont:fontWithName_size('HelveticaNeue', 14))
    message:setNumberOfLines(0)
    message:setTextAlignment(NSTextAlignmentCenter)
    message:setColor(COLOR(0xffffffaa))
    scroll.m:addSubview(message)

    local changelog

    local activity = objc.UIActivityIndicatorView:alloc():init()

    local w = 170
    self.check_button = ui.button:new()
    self.check_button.m:setFrame{{(FW - w)/2, message_height + pad*2},{w, 34}}
    self.check_button:setFont('HelveticaNeue', 16)
    self.check_button.m:layer():setCornerRadius(8)
    self.check_button:setColor(COLOR(0xff, 0xff, 0xff, 0xff*0.7))
    self.check_button.m:setBackgroundColor(COLOR(0xff, 0xff, 0xff, 0xff*0.03))
    local check, download, prompt_update, update, prompt_cydia
    local update_version, download_url, download_sha256
    function check()
        self.check_button.ontoggle = nil
        self.check_button:setTitle('')
        activity:setHidden(false)
        activity:startAnimating()
        message:setText('Checking for update...')
        CHECK_UPDATE(function(json, err)
            if err then
                self.check_button.ontoggle = check
                activity:stopAnimating()
                activity:setHidden(true)
                message:setText(err)
                self.check_button:setTitle('Check again')
                return
            end
            update_version = json.version
            download_url = json.url or BASE_URL..'/eqe.deb'
            download_sha256 = json.sha256 -- TODO actually check this lol

            if json.cydia then
                prompt_cydia()
            else
                local success, already_dled = pcall(dofile, update_version_path)
                if success and already_dled == json.version then
                    prompt_update()
                else
                    self.check_button.ontoggle = function()
                        download()
                    end
                    activity:stopAnimating()
                    activity:setHidden(true)
                    message:setText('An update is available.')
                    self.check_button:setTitle('Download it')
                end
            end

            if changelog then
                changelog:removeFromSuperview()
                changelog:release()
                changelog = nil
            end

            local f = self.check_button.m:frame()
            if type(json.changelog) == 'table' and #json.changelog > 0 then
                changelog = objc.UILabel:alloc():init()
                changelog:setColor(COLOR(0xffffffaa))
                changelog:setFont(objc.UIFont:fontWithName_size('HelveticaNeue', 14))
                changelog:setNumberOfLines(0)
                scroll.m:addSubview(changelog)
                local s = 'Changelog:'
                for i,v in ipairs(json.changelog) do
                    s = s..'\n    • '..v
                end
                changelog:setText(s)
                changelog:setFrame{{pad, f.origin.y + f.size.height + pad},{FW - pad*2, 0}}
                changelog:sizeToFit()
                scroll.m:setContentSize{scroll.m:contentSize().width, changelog:frame().origin.y + changelog:frame().size.height + pad}
            elseif type(json.changelog) == 'string' then
                local r = md.new(FW - pad*2)
                changelog = r.m
                changelog:setFrame{{pad, f.origin.y + f.size.height + pad},{0,0}}
                scroll.m:addSubview(changelog)
                function r.onupdate()
                    scroll.m:setContentSize{scroll.m:contentSize().width, changelog:frame().origin.y + changelog:frame().size.height + pad}
                end
                r:init(json.changelog)
            else
                scroll.m:setContentSize{scroll.m:contentSize().width, f.origin.y + f.size.height + pad}
            end
        end)
    end
    function prompt_cydia()
        self.check_button.ontoggle = function()
            local url = objc.NSURL:URLWithString('cydia://package/com.r333d.eqe')
            objc.UIApplication:sharedApplication():openURL(url)
        end
        activity:stopAnimating()
        activity:setHidden(true)
        message:setText("An update is available. But I can't do it here. Has to be done in Cydia this time, sry :(")
        self.check_button:setTitle('Open Cydia')
    end
    function prompt_update()
        self.check_button.ontoggle = update
        activity:stopAnimating()
        activity:setHidden(true)
        message:setText('An update has been downloaded and is ready to install.')
        self.check_button:setTitle('DO IT!!!')
    end
    function download(idx)
        local url
        if type(download_url) == 'table' then
            idx = idx or 1
            url = download_url[idx]
        else
            url = download_url
        end

        self.check_button.ontoggle = nil
        activity:setHidden(false)
        activity:startAnimating()
        message:setText('Downloading...')
        self.check_button:setTitle('')
        HTTP(url, {
            download = update_dl_path,
        }, function(success, status, headers)
            if not(success and status == 200) then
                if type(download_url) == 'table' and download_url[idx + 1] then
                    download(idx + 1)
                else
                    activity:stopAnimating()
                    activity:setHidden(true)
                    message:setText('Download failed. Probably bad internet connection?')
                    self.check_button:setTitle('Try again')
                    self.check_button.ontoggle = function()
                        download()
                    end
                end
                return
            end
            local f = io.open(update_version_path, 'w')
            local t = type(update_version)
            if t == 'string' then
                f:write('return '..str_esc(update_version))
            elseif t == 'number' then
                f:write('return '..update_version)
            else
                error('json.version is of type'..t..', which makes no sense')
            end
            f:close()
            prompt_update()
        end, function(progress, total)
            local percent = total and ''..math.floor(100*progress/total)..'%\n' or ''
            local bytes
            if progress < 1024 then
                bytes = '0 KB'
            elseif progress < 1024*1024 then
                bytes = math.floor(progress/1024)..' KB'
            else
                bytes = (math.floor(10*progress/(1024*1024) + 0.5)/10)..' MB'
            end
            message:setText(percent..bytes)
        end)
    end
    local console, append_console
    function update()
        if console then
            console:removeFromSuperview()
        end

        self.check_button.ontoggle = nil
        activity:setHidden(false)
        activity:startAnimating()
        message:setText('Installing...')
        self.check_button:setTitle('')

        local f = self.check_button.m:frame()
        local y = f.origin.y + f.size.height

        console, append_console = require 'vc.dpkg'(10, y + pad, FW - 10*2)
        local function append(...)
            append_console(...)
            local f = changelog:frame()
            f.origin.y = console:frame().origin.y + console:frame().size.height
            changelog:setFrame(f)
            scroll.m:setContentSize{scroll.m:contentSize().width, changelog:frame().origin.y + changelog:frame().size.height + pad}
        end
        scroll.m:addSubview(console)
        Cmd('dpkg -i '..update_dl_path, function(str, status)
            if str == ffi.NULL then
                -- finished
                if status == 0 then
                    append(true, 'Installed! :D You will probably want to restart the app and mediaserverd.')
                    self.check_button.m:setHidden(true)
                    activity:stopAnimating()
                    activity:setHidden(true)
                    message:setText('Installed!')

                    local wink = objc.UILabel:alloc():initWithFrame(self.check_button.m:frame())
                    wink:setText('😉')

                    wink:setFont(objc.UIFont:fontWithName_size('HelveticaNeue', 40))

                    wink:setTextAlignment(NSTextAlignmentCenter)
                    scroll.m:addSubview(wink)

                    os.remove(update_version_path)
                else
                    append(false, 'Failed :(')
                    self.check_button.ontoggle = update
                    activity:stopAnimating()
                    activity:setHidden(true)
                    message:setText('Install failed.')
                    self.check_button:setTitle('Try again')
                end
            else
                -- still running dpkg
                append(ffi.string(str))
            end
        end)
    end
    self.check_button.ontoggle = check
    scroll.m:addSubview(self.check_button.m)

    activity:setActivityIndicatorViewStyle(UIActivityIndicatorViewStyleWhite)
    activity:setFrame(self.check_button.m:frame())
    activity:setHidden(true)
    scroll.m:addSubview(activity)

    check()

end
return page
