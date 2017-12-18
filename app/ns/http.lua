local super = Object
ns.http = Object.new(super)

function ns.http:new(...)
    local self = super.new(self, ...)

    self.m = self.class:alloc():init()
    objc.ref(self.m, self)

    self.timeout = 8

    return self
end

function ns.http:start()
    local url = objc.NSURL:URLWithString(self.url)
    local request = objc.NSMutableURLRequest:requestWithURL(url)
    for k,v in pairs(self.requestheaders or {}) do
        request:setValue_forHTTPHeaderField(v, k)
    end
    request:setHTTPMethod(self.method or 'GET')

    if not objc.NSURLSession then
        -- iOS 6- fallback
        if self.download and not self.downloadpath then
            self.downloadpath = '/var/tmp/'..math.floor(math.random()*1000000)
        end

        self.connection = objc.NSURLConnection:alloc():initWithRequest_delegate(request, self.m)
        self.connection:start()
    else
        local config = objc.NSURLSessionConfiguration:defaultSessionConfiguration()
        config:setTimeoutIntervalForRequest(self.timeout)
        local queue = objc.NSOperationQueue:mainQueue()
        local urlSession = objc.NSURLSession:sessionWithConfiguration_delegate_delegateQueue(config, self.m, queue)

        if self.download then
            self.task = urlSession:downloadTaskWithRequest(request)
        else
            self.task = urlSession:dataTaskWithRequest(request)
        end
        self.task:resume()
        urlSession:finishTasksAndInvalidate()

        self.session = urlSession
    end
end

function ns.http:parseheaders(headers)
    if headers['Last-Modified'] then
        local day, month, year, hour, min, sec = string.match(headers['Last-Modified'], '%w+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT')
        if day and month and year and hour and min and sec then
            local MON ={Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
            month = MON[month]
            local offset = os.time()-os.time(os.date("!*t"))
            local epoch = os.time({day=day,month=month,year=year,hour=hour,min=min,sec=sec})+offset
            headers['Last-Modified'] = epoch
        end
    end
    self.headers = headers
end

function ns.http:handler()
    --[[
    ARGS
    file download: url, percent, errcode
    data: data, percent, errcode
    ]]
end

ns.http.class = objc.GenerateClass()
local class = ns.http.class

function class:dealloc()
    objc.unref(self)
    objc.callsuper(self, 'dealloc')
end

-- fallback for iOS 6 and lower

objc.addmethod(class, 'connection:didReceiveResponse:', function(self, connection, response)
    local this = objc.getref(self)

    this.status = tonumber(response:statusCode())
    this:parseheaders(objc.tolua(response:allHeaderFields()))

    if this.method == 'HEAD' then
        connection:cancel()
        this:handler(nil, nil, this.status)
        return
    end

    this.length = tonumber(this.headers['Content-Length'])
    if this.length then
        this.mdata = objc.NSMutableData:alloc():initWithCapacity(this.length)
    else
        this.mdata = objc.NSMutableData:alloc():init()
    end
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')

objc.addmethod(class, 'connection:didReceiveData:', function(self, connection, data)
    local this = objc.getref(self)
    this.mdata:appendData(data)
    if this.length then
        local progress = tonumber(this.mdata:length())
        this:handler(nil, progress/this.length)
    end
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')

objc.addmethod(class, 'connectionDidFinishLoading:', function(self, connection)
    local this = objc.getref(self)

    print('finished!')

    if this.status < 200 or this.status > 299 then
        this:handler(nil, nil, this.status)
        return
    end

    if this.downloadpath then
        print('writing to '..this.downloadpath)
        this.mdata:writeToFile_atomically(this.downloadpath, true)
        local f = io.open(this.downloadpath, 'r')
        if not f then
            error('wtf?')
        else
            f:close()
        end
        this:handler(this.downloadpath)
    else
        print('data')
        this:handler(this.mdata)
    end
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')

-- data request

objc.addmethod(class, 'URLSession:dataTask:didReceiveData:', function(self, session, task, data)
    local this = objc.getref(self)

    if not this.mdata then
        this.mdata = objc.NSMutableData:alloc():init()
    end
    this.mdata:appendData(data)
end, ffi.arch == 'arm64' and 'v40@0:8@16@24@32' or 'v20@0:4@8@12@16')

-- download request

objc.addmethod(class, 'URLSession:downloadTask:didFinishDownloadingToURL:', function(self, session, task, url)
    local this = objc.getref(self)

    local status = tonumber(task:response():statusCode())

    this:parseheaders(objc.tolua(task:response():allHeaderFields()))

    if status >= 200 and status < 300 then
        local url = objc.tolua(url:description())
        url = string.sub(url, #'file://' + 1, #url)
        this:handler(url)
    else
        this:handler(objc.tolua(url), nil, status)
    end
end, ffi.arch == 'arm64' and 'v40@0:8@16@24@32' or 'v20@0:4@8@12@16')

objc.addmethod(class, 'URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:', function(self, session, task, data, bytesWritten, totalBytes)
    local this = objc.getref(self)
    local percent = tonumber(bytesWritten)/tonumber(totalBytes)

    if not this.totalbytes then
        this.totalbytes = totalBytes
    end
    this:handler(nil, percent)
end, ffi.arch == 'arm64' and 'v56@0:8@16@24Q32Q40Q48' or 'v28@0:4@8@12Q16Q20Q24')

objc.addmethod(class, 'URLSession:task:didCompleteWithError:', function(self, session, task, err)
    local this = objc.getref(self)


    if err and not(err == ffi.NULL) then
        local desc = err.description
        this:handler(nil, nil, objc.tolua(desc))
    elseif not this.download then
        local err = task:error()
        if err and not(err == ffi.NULL) then
            this:handler(nil, nil, objc.tolua(err:localizedDescription()))
        else
            local response = task:response()
            local status = response and tonumber(response:statusCode())
            if this.mdata then
                if status >= 200 and status < 300 then
                    local data = this.mdata
                    this.mdata = nil
                    this:handler(data)
                else
                    this:handler(nil, nil, status)
                end
            else
                if response then
                    this:parseheaders(objc.tolua(response:allHeaderFields()))
                end
                print("GOT A 0 LOL "..tostring(response))
                this:handler(nil, nil, status or 0)
            end
        end
    end
end, ffi.arch == 'arm64' and 'v32@0:8@16@24' or 'v16@0:4@8@12')


--- download bar

Downloadbar = Object:new(view)
function Downloadbar:new(frame)
    local self = Object.new(self)

    local textColor = objc.UIColor:whiteColor()

    local w, h = SCREEN.WIDTH - 30, 80

    frame = frame or CGRectMake((SCREEN.WIDTH - w)/2, (SCREEN.HEIGHT - h)/2, w, h)

    local view = objc.UIView:alloc():initWithFrame(frame)
    view:setUserInteractionEnabled(false)
    view:setBackgroundColor(objc.UIColor:colorWithWhite_alpha(0, 0.85))
    view:layer():setCornerRadius(5)

    local progress = objc.UIProgressView:alloc():initWithProgressViewStyle(UIProgressViewStyleDefault)
    progress:setTrackTintColor(objc.UIColor:colorWithWhite_alpha(1, 0.3))
    progress:setProgressTintColor(objc.UIColor:whiteColor())
    progress:setProgress(0)

    local padding = 44
    local y = frame.size.height*2/5
    progress:setFrame{{padding, y},{frame.size.width-padding*2, 22}}

    local downloadingLabel = objc.UILabel:alloc():initWithFrame{{padding, y + 11},{20,20}}
    downloadingLabel:setTextColor(textColor)
    downloadingLabel:setText('Downloading...')
    downloadingLabel:setFont(downloadingLabel:font():fontWithSize(12))
    downloadingLabel:sizeToFit()

    local percentLabel = objc.UILabel:alloc():initWithFrame{{0, y + 11},{20,20}}
    percentLabel:setTextColor(textColor)
    percentLabel:setText('000%')
    percentLabel:setFont(percentLabel:font():fontWithSize(12))
    percentLabel:sizeToFit()
    local x = progress:frame().origin.x + progress:frame().size.width - percentLabel:frame().size.width
    percentLabel:setFrame{{x, percentLabel:frame().origin.y},percentLabel:frame().size}
    percentLabel:setTextAlignment(NSTextAlignmentRight)
    percentLabel:setText('0%')

    self.m = view
    self.progress = progress
    self.percent = percentLabel
    self.downloading = downloadingLabel

    view:addSubview(self.downloading)
    view:addSubview(self.percent)
    view:addSubview(self.progress)

    return self
end

return ns.http
