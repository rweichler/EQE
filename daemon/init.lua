if jit.arch == 'arm64' then
    jit.off()
end

package.path = LUA_PATH..'/?.lua;'..
               LUA_PATH..'/?/init.lua;'..
               LUA_PATH..'/../common/?.lua;'..
               LUA_PATH..'/../common/?/init.lua;'..
               package.path

ffi = require 'ffi'
local dkjson = require 'dkjson'

local uri = 'https://eqe.fm/api/'

-- sesh config stuff

local sesh = require 'sesh'
function GET_SESH()
    return sesh.data
end
UPDATE_SESH = sesh.write

-- should i even scrobble? config stuff

local should_i_spin_path = LUA_PATH..'/../common/config/should_i_spin.lua'
local success, should_spin_local, should_spin_online = pcall(dofile, should_i_spin_path)
if not success then
    should_spin_local = true
    should_spin_online = false
end

function SHOULD_I_SPIN(is_local)
    if is_local then
        return should_spin_local
    else
        return should_spin_online
    end
end

function SET_SHOULD_I_SPIN(is_local, v)
    if is_local then
        should_spin_local = v
    else
        should_spin_online = v
    end
    local f = io.open(should_i_spin_path, 'w')
    f:write('return '..tostring(should_spin_local)..', '..tostring(should_spin_online))
    f:close()
end

function API(cmd, info, cb)
    local url = uri..cmd
    info = info or {}
    info.uri_args = info.uri_args or {}
    info.uri_args.sesh = info.uri_args.sesh or GET_SESH()
    info.uri_args.client_version = require 'config.default.version'
    info.convert = info.convert or 'json'
    return HTTP(url, info, cb)
end

function UPDATE_PRESET(name, path)
    local f = io.open(path, 'r')
    if not f then return end
    local s = dkjson.encode(load(f:read('*all'))())
    f:close()

    API('update_preset', {
        method = 'POST',
        body = s,
        uri_args = {
            name = name,
        }
    }, function(json, status, headers)
        lmfao = json
        lmfaoo = status
    end)
end

history = require 'history'
history.init()

rsp_timeout = 0

local function spin(song, timeout)
    API('spin', {
        uri_args = {
            title = song.title,
            artist = song.artist,
            album = song.album,
            date = song.timestamp,
            app = song.app.name,
            platform = 'iOS',
        },
    }, function(json, status, headers)
        if not json and status == 'The request timed out.' then
            if not timeout then
                rsp_timeout = rsp_timeout + 1
            end
            DISPATCH(5, function()
                spin(song, true)
            end)
        else
            if timeout then
                rsp_timeout = rsp_timeout - 1
            end
            rsp_timeout = nil
            rsp_json = json
            rsp_status = status
            rsp_headers = headers

            if json and json.id then
                history.remote_id(song.id, json.id)
            end
        end
    end)
end
function scrobble(songinfo)
    if not should_spin_local then return end

    local song, newapp = history.add(songinfo)
    newapp = newapp and 'newapp' or nil
    if not song then return newapp end

    if song.appid then
        local app = history.getapp(song.appid)
        if app.enabled == 0 then
            return newapp
        end
    end

    if not should_spin_online then return newapp end

    DISPATCH(history.minimum_duration + 2, function()
        if (song.start and os.time() - song.start >= history.minimum_duration)
            or
            (song.total and song.total >= history.minimum_duration)
        then
            spin(song)
        end
    end)

    return newapp
end

require 'autorun_loader'('daemon')
