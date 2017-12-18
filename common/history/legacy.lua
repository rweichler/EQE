-- update old tables to be compatible with our code!
local legacy = {}

local function recreate(sql, table_name, f)
    sql:exec'PRAGMA foreign_keys=off'
    sql:exec'BEGIN TRANSACTION'
    sql:exec('ALTER TABLE '..table_name..' RENAME TO tmp')
    f()
    sql:exec'COMMIT'
    sql:exec'PRAGMA foreign_keys=on'
    sql:exec'DROP TABLE tmp'
end

local lookup = {
    history = {
        ['CREATE TABLE history(id INTEGER, appid INTEGER, time INTEGER, duration INTEGER, title TEXT, artist TEXT, album TEXT, deleted INTEGER DEFAULT 0)'] = function(sql)
            recreate(sql, 'history', function()
                sql:exec[[CREATE TABLE history(id INTEGER, appid INTEGER, time INTEGER, duration INTEGER, title TEXT, artist TEXT, album TEXT, deleted INTEGER)]]
                sql:exec[[INSERT INTO history ("id", "appid", "time", "duration", "title", "artist", "album", "deleted")
                  SELECT "id", "appid", "time", "duration", "title", "artist", "album", "deleted"
                  FROM tmp]]
            end)
        end,
        ['CREATE TABLE history(id INTEGER, appid INTEGER, time INTEGER, duration INTEGER, title TEXT, artist TEXT, album TEXT, deleted INTEGER)'] = function(sql)
            recreate(sql, 'history', function()
                sql:exec(legacy.current.history)
                sql:exec[[INSERT INTO history ("id", "appid", "time", "duration", "title", "artist", "album", "deleted")
                  SELECT "id", "appid", "time", "duration", "title", "artist", "album", "deleted"
                  FROM tmp]]
            end)
        end,
    },
    app = {
        ['CREATE TABLE app(id INTEGER, name TEXT, bundle TEXT, icon TEXT)'] = function(sql)
            recreate(sql, 'app', function()
                sql:exec(legacy.current.app)
                sql:exec[[INSERT INTO app ("id", "name", "bundle", "icon", "enabled")
                    SELECT "id", "name", "bundle", "icon", 1
                    FROM tmp]]
            end)
        end,
    },
}


legacy.current = {
    history = 'CREATE TABLE history(id BIGINT, appid INTEGER, time BIGINT, duration INTEGER, title TEXT, artist TEXT, album TEXT, deleted INT2, remoteid BIGINT)',
    app = 'CREATE TABLE app(id INTEGER, name TEXT, bundle TEXT, icon TEXT, enabled INT2)',
}

local esc = require 'sqlite'.esc
function legacy.fix(sql)
    sql:lock()
    for table_name,queries in pairs(lookup) do
        repeat
            local query = sql:text('SELECT sql FROM sqlite_master WHERE name='..esc(table_name))
            local f = queries[query]
            if f then
                f(sql)
            elseif not legacy.current[table_name] == query then
                error("invalid database schema for "..table_name..", your shit's all fucked up: "..query)
            end
        until not f
    end
    sql:unlock()
end


return legacy
