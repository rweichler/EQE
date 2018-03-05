if jit.arch == 'arm64' then
    jit.off()
end
package.path = LUA_PATH..'/?.lua;'..
               LUA_PATH..'/?/init.lua;'..
               LUA_PATH..'/../common/?.lua;'..
               LUA_PATH..'/../common/?/init.lua;'..
               package.path

pcall(require, 'autorun')
require 'constants'
ffi = require 'ffi'
C = ffi.C
bit = require 'bit'
objc = require 'objc'

local str_esc = require 'str_esc'
function LOG_IN(login)
    LOGIN = login

    local session_id = login and login.session_id or nil
    _G.sesh.data = session_id
    local function defer()
        if not(LOGIN == login) then return end

        local success, err = pcall(IPCD, 'UPDATE_SESH('..str_esc(session_id)..')')
        if not success then
            if err == "couldn't establish a connection" then
                DISPATCH(1, defer)
            else
                error(err)
            end
        end
    end
    defer()
end

_G.weakt = setmetatable({}, {__mode = 'v'})

require 'util'
require 'cdef'

local old_http = HTTP
function HTTP(url, requestinfo, cb, progress_cb)
    if type(requestinfo) == 'function' then
        progress_cb = cb
        cb = requestinfo
        requestinfo = {}
    end
    requestinfo.uri_args = requestinfo.uri_args or {}
    requestinfo.uri_args.sesh = requestinfo.uri_args.sesh or _G.sesh.data
    requestinfo.uri_args.client_version = require 'config.default.version'
    old_http(url, requestinfo, function(data, status_or_err, response_or_nil)
        if not data then
            local err = status_or_err
            cb(nil, err)
        else
            local status = status_or_err
            local response = response_or_nil
            if type(data) == 'userdata' then
                data = ffi.cast('id', data)
            end
            if data == ffi.NULL then
                data = nil
            end
            cb(data, status, ffi.cast('id', response))
        end
    end, progress_cb)
end

C.objc_setUncaughtExceptionHandler(function(exception, context)
    local s = objc.tolua(exception.reason)
    s = s..'\nobjc stack:'
    local symbols = exception:callStackSymbols()
    for i=0,tonumber(symbols:count())-1 do
        s = s..'\n'..objc.tolua(symbols:objectAtIndex(i))
    end
    error(s)
end)

function Cmd(cmd, f)
    C.pipeit('/usr/libexec/eqe_setuid /usr/bin/env '..cmd, f)
end

function HOOK(t, k, hook)
    local orig = t[k]
    if not(type(orig) == 'function') then
        error('invalid type')
    end
    t[k] = function(...)
        return hook(orig, ...)
    end
end

local count = 0
function objc.GenerateClass(super, ...)
    super = super or 'NSObject'
    count = count + 1
    local name = 'EQEAPP_'..count..super

    if ... then
        objc.class(name, super..'<'..table.concat({...}, ',')..'>')
    else
         objc.class(name, super)
    end

    return objc[name]
end
local key = ffi.new('int[1]')
function objc.ref(obj, set)
    -- associated objects should be objc
    -- objects. but this works, so w/e
    assert(set)
    local ref = REF(set, true)
    local v = ffi.cast('int *', C.malloc(ffi.sizeof('int')))
    v[0] = ref
    C.objc_setAssociatedObject(obj, key, ffi.cast('id', v), C.OBJC_ASSOCIATION_ASSIGN)
end
function objc.unref(obj)
    local v = ffi.cast('int *', C.objc_getAssociatedObject(obj, key))
    if not v then error('obj not found') end
    REF(v[0], false)
    C.objc_setAssociatedObject(obj, key, nil, C.OBJC_ASSOCIATION_ASSIGN)
    C.free(v)
end

function objc.getref(obj)
    local v = ffi.cast('int *', C.objc_getAssociatedObject(obj, key))
    return v and REF(v[0], nil) or nil
end

local vc_class = objc.GenerateClass('UIViewController')
local function dealloc(m)
    local self = objc.getref(m)
    for _,v in pairs(self.i) do
        local type = type(v)
        if type == 'cdata' then
            v:release()
        elseif type == 'table' and v.m then
            v.m:release()
        end
    end
    if self.dealloc then
        self:dealloc()
    end
    objc.unref(m)
    objc.callsuper(m, 'dealloc')
end
dealloc = ffi.cast('IMP', ffi.cast('void (*)(id, SEL)', dealloc))
C.class_replaceMethod(vc_class, objc.SEL('dealloc'), dealloc, ffi.arch == 'arm64' and 'v16@0:8' or 'v8@0:4')

local function viewDidLoad(m)
    local self = objc.getref(m)
    return self.on_load(m)
end
viewDidLoad = ffi.cast('IMP', ffi.cast('void (*)(id, SEL)', viewDidLoad))
C.class_replaceMethod(vc_class, objc.SEL('viewDidLoad'), viewDidLoad, ffi.arch == 'arm64' and 'v16@0:8' or 'v8@0:4')

function VIEWCONTROLLER(callback, title)
    local self = {}
    self.i = {}
    self.m = vc_class:alloc():init()
    self.on_load = callback
    self.m:setTitle(title or '')
    objc.ref(self.m, self)
    self.m:autorelease()
    return self.m
end

Object = require 'object'

ui = {}
require 'ui.table'
require 'ui.filtertable'
require 'ui.cell'
require 'ui.searchbar'
require 'ui.button'
require 'ui.textbox'
require 'ui.scroll'

ns = {}
require 'ns.target'
require 'ns.http'

objc.class('AppDelegate', 'UIResponder')

objc.addmethod(objc.AppDelegate, 'application:didFinishLaunchingWithOptions:', function(self, app, options)
    local path = '/var/tweak/com.r333d.eqe/db/apperror.log'
    local f = io.open(path, 'r')
    if f then
        local s = f:read('*all')
        require('page.error')(s)
        f:close()
        os.remove(path)
    else
        objc.STPPaymentConfiguration:sharedConfiguration():setPublishableKey("pk_test_BqPbWdIJi1H3RDYYbrMVLC7M")
        require 'main'
    end
    return true
end, ffi.arch == 'arm64' and 'B32@0:8@16@24' or 'B16@0:4@8@12')

ON_APP_RELAUNCH = {}

objc.addmethod(objc.AppDelegate, 'applicationDidBecomeActive:', function(self, app)
    if Page then
        if Page.eqe.view then
            Page.eqe.view:update()
            Page.eqe.view:onAppRelaunch()
        end
    end
    for k,v in pairs(ON_APP_RELAUNCH) do
        v()
    end
end, ffi.arch == 'arm64' and 'v24@0:8@16' or 'v12@0:4@8')

DONT_RETAIN = true
local argc, argv = ...
return C.UIApplicationMain(argc, argv, nil, objc.toobj('AppDelegate'))
