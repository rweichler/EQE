local sqlite = require 'sqlite'
local legacy = require 'history.legacy'

local history = {}

local log
if eqe then
    ffi.cdef[[
    void eqe_syslog(const char *);
    ]]
    log = function(s)
        C.eqe_syslog(s)
    end
else
    log = function() end
end



local esc = sqlite.esc

history.minimum_duration = 30 -- minimum amount of time for a song to count as a play
history.db_path = '/var/tweak/com.r333d.eqe/db/history.db'
function history.add(info)
    local rate = tonumber(info.MPNowPlayingInfoPropertyPlaybackRate)
    if not rate then return end
    if not info.title then return end
    local paused = rate == 0

    local nowplaying = history.nowplaying
    local function done()
        if not nowplaying then return end
        if nowplaying.start then
            nowplaying.total = nowplaying.total + os.time() - nowplaying.start
            nowplaying.start = nil
        end
        history.write(nowplaying)
    end

    if paused then
        done()
    else -- play
        local cur = {
            title = info.title,
            album = info.albumTitle,
            artist = info.artist,
            app = info.app,
            timestamp = os.time(),
        }
        if not nowplaying or not(nowplaying.title == cur.title and nowplaying.album == cur.album and nowplaying.artist == cur.artist) then
            done()
            cur.total = 0
            cur.start = os.time()
            local last = history.last()
            cur.id = tonumber((last and last.id or 0) + 1)
            local newapp = history.write(cur)
            history.nowplaying = cur
            return cur, newapp
        else
            nowplaying.start = nowplaying.start or os.time()
        end

    end
end

function history.exec(query, should_cache)
    return history.db:exec(query, should_cache)
end

function history.init()
    local firstrun
    do
        local f = io.open(history.db_path, 'r')
        firstrun = not f
        if f then
            f:close()
        end
    end
    if firstrun then
        history.db = sqlite.open(history.db_path)
        history.db.atomic = true
        for k,v in pairs(legacy.current) do
            history.exec(v)
        end
    end
    history.db = history.db or sqlite.open(history.db_path)
    history.db.atomic = true
    legacy.fix(history.db)
end

local function count(tablename)
    return history.db:int('SELECT id FROM '..tablename..' ORDER BY id DESC LIMIT 1', true) or 0
end

function history.last()
    local rows = history.exec('SELECT id FROM history ORDER BY id DESC LIMIT 1', true)
    if rows then
        return rows[1]
    end
end

function history.count()
    return count('history')
end

function history.get(id)
    return history.exec('SELECT * FROM history WHERE id='..id)[1]
end

function history.getapp(id)
    return history.exec('SELECT * FROM app WHERE id='..id)[1]
end

function history.enable_app(arg)
    local filter
    if type(arg) == 'string' then
        filter = 'bundle='..esc(arg)
    elseif type(arg) == 'number' then
        filter = 'id='..arg
    else
        error('invalid type: '..type(arg))
    end
    return history.exec('UPDATE app SET enabled=1 WHERE '..filter)
end

local function get_appid(app)
    local row = history.exec('SELECT * FROM app WHERE bundle='..esc(app.bundle))[1]
    if not row then
        local enabled = require 'config.default.whitelist'[app.bundle]
        local id = count('app') + 1
        history.exec('INSERT INTO app VALUES('..id..', '..esc(app.name)..', '..esc(app.bundle)..', '..esc(app.icon)..', '..(enabled and 1 or 0)..')')
        return id, enabled == nil
    else
        if app.icon and not(app.icon == row.icon) then
            history.exec([[
            UPDATE app
            SET icon=]]..esc(app.icon)..[[
            WHERE id=]]..row.id
            , true)
        end
        return row.id
    end
end

function history.delete(id)
    history.exec([[
    UPDATE history
    SET deleted=1
    WHERE id=]]..id)
end

function history.write(song)
    if not song.wrote then
        song.wrote = true
        local appid, newapp = get_appid(song.app)
        song.appid = appid
        if song.deleted == nil and (newapp or history.getapp(appid).enabled == 0) then
            song.deleted = true
        end
        history.exec('INSERT INTO history VALUES('..song.id..', '..appid..', '..song.timestamp..', '..song.total..', '..esc(song.title)..', '..esc(song.artist)..', '..esc(song.album)..', '..(song.deleted and 1 or 0)..', NULL)', true)
        return newapp
    else
        history.exec([[
        UPDATE history
        SET duration=]]..song.total..[[
        WHERE id=]]..song.id)
    end
end

-- update remoteid
function history.remote_id(id, remoteid)
    history.exec([[
    UPDATE history
    SET remoteid=]]..remoteid..[[
    WHERE id=]]..id)
end

return history
