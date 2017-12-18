local ffi = require 'ffi'
-- Codes -----------------------------------------------------------------------
local sqlconstants = {} -- SQLITE_* and OPEN_* declarations.
local codes = {
  [0] = "OK", "ERROR", "INTERNAL", "PERM", "ABORT", "BUSY", "LOCKED", "NOMEM", 
  "READONLY", "INTERRUPT", "IOERR", "CORRUPT", "NOTFOUND", "FULL", "CANTOPEN", 
  "PROTOCOL", "EMPTY", "SCHEMA", "TOOBIG", "CONSTRAINT", "MISMATCH", "MISUSE", 
  "NOLFS", "AUTH", "FORMAT", "RANGE", "NOTADB", [100] = "ROW", [101] = "DONE"
} -- From 0 to 26.

do
  local types = { "INTEGER", "FLOAT", "TEXT", "BLOB", "NULL" } -- From 1 to 5.

  local opens = {
    READONLY =        0x00000001;
    READWRITE =       0x00000002;
    CREATE =          0x00000004;
    DELETEONCLOSE =   0x00000008;
    EXCLUSIVE =       0x00000010;
    AUTOPROXY =       0x00000020;
    URI =             0x00000040;
    MAIN_DB =         0x00000100;
    TEMP_DB =         0x00000200;
    TRANSIENT_DB =    0x00000400;
    MAIN_JOURNAL =    0x00000800;
    TEMP_JOURNAL =    0x00001000;
    SUBJOURNAL =      0x00002000;
    MASTER_JOURNAL =  0x00004000;
    NOMUTEX =         0x00008000;
    FULLMUTEX =       0x00010000;
    SHAREDCACHE =     0x00020000;
    PRIVATECACHE =    0x00040000;
    WAL =             0x00080000;
  }

  local t = sqlconstants
  local pre = "static const int32_t SQLITE_"  
  for i=0,26    do t[#t+1] = pre..codes[i].."="..i..";\n" end
  for i=100,101 do t[#t+1] = pre..codes[i].."="..i..";\n" end  
  for i=1,5     do t[#t+1] = pre..types[i].."="..i..";\n" end  
  pre = pre.."OPEN_"
  for k,v in pairs(opens) do t[#t+1] = pre..k.."="..bit.tobit(v)..";\n" end  
end

-- Cdef ------------------------------------------------------------------------
-- SQLITE_*, OPEN_*
ffi.cdef(table.concat(sqlconstants))
ffi.cdef[[
// Typedefs.
typedef struct sqlite3 sqlite3;
typedef struct sqlite3_stmt sqlite3_stmt;
typedef void (*sqlite3_destructor_type)(void*);
typedef struct sqlite3_context sqlite3_context;
typedef struct Mem sqlite3_value;

// Get informative error message.
const char *sqlite3_errmsg(sqlite3*);

// Connection.
int sqlite3_open_v2(const char *filename, sqlite3 **ppDb, int flags,
  const char *zVfs);
int sqlite3_close(sqlite3*);
int sqlite3_busy_timeout(sqlite3*, int ms);

// Statement.
int sqlite3_prepare_v2(sqlite3 *conn, const char *zSql, int nByte, 
  sqlite3_stmt **ppStmt, const char **pzTail);
int sqlite3_step(sqlite3_stmt*);
int sqlite3_reset(sqlite3_stmt *pStmt);
int sqlite3_finalize(sqlite3_stmt *pStmt);

// Extra functions for SELECT.
int sqlite3_column_count(sqlite3_stmt *pStmt);
const char *sqlite3_column_name(sqlite3_stmt*, int N);
int sqlite3_column_type(sqlite3_stmt*, int iCol);

// Get value from SELECT.
int sqlite3_column_int(sqlite3_stmt*, int iCol);
int64_t sqlite3_column_int64(sqlite3_stmt*, int iCol);
double sqlite3_column_double(sqlite3_stmt*, int iCol);
int sqlite3_column_bytes(sqlite3_stmt*, int iCol);
const unsigned char *sqlite3_column_text(sqlite3_stmt*, int iCol);
const void *sqlite3_column_blob(sqlite3_stmt*, int iCol);

// Set value in bind.
int sqlite3_bind_int64(sqlite3_stmt*, int, int64_t);
int sqlite3_bind_double(sqlite3_stmt*, int, double);
int sqlite3_bind_null(sqlite3_stmt*, int);
int sqlite3_bind_text(sqlite3_stmt*, int, const char*, int n, void(*)(void*));
int sqlite3_bind_blob(sqlite3_stmt*, int, const void*, int n, void(*)(void*));

// Clear bindings.
int sqlite3_clear_bindings(sqlite3_stmt*);

// Get value in callbacks.
int sqlite3_value_type(sqlite3_value*);
int64_t sqlite3_value_int64(sqlite3_value*);
double sqlite3_value_double(sqlite3_value*);
int sqlite3_value_bytes(sqlite3_value*);
const unsigned char *sqlite3_value_text(sqlite3_value*); //Not used.
const void *sqlite3_value_blob(sqlite3_value*);

// Set value in callbacks.
void sqlite3_result_error(sqlite3_context*, const char*, int);
void sqlite3_result_int64(sqlite3_context*, int64_t);
void sqlite3_result_double(sqlite3_context*, double);
void sqlite3_result_null(sqlite3_context*);
void sqlite3_result_text(sqlite3_context*, const char*, int, void(*)(void*));
void sqlite3_result_blob(sqlite3_context*, const void*, int, void(*)(void*));

// Persistency of data in callbacks (here just a pointer for tagging).
void *sqlite3_aggregate_context(sqlite3_context*, int nBytes);

// Typedefs for callbacks.
typedef void (*ljsqlite3_cbstep)(sqlite3_context*,int,sqlite3_value**);
typedef void (*ljsqlite3_cbfinal)(sqlite3_context*);

// Register callbacks.
int sqlite3_create_function(
  sqlite3 *conn,
  const char *zFunctionName,
  int nArg,
  int eTextRep,
  void *pApp,
  void (*xFunc)(sqlite3_context*,int,sqlite3_value**),
  void (*xStep)(sqlite3_context*,int,sqlite3_value**),
  void (*xFinal)(sqlite3_context*)
);
]]
local lib = ffi.load('sqlite3')
local open_modes = {
  r = lib.SQLITE_OPEN_READONLY,
  rw = lib.SQLITE_OPEN_READWRITE,
  rwc = bit.bor(lib.SQLITE_OPEN_READWRITE, lib.SQLITE_OPEN_CREATE)
}

local sql = {}
sql.mt = {
    __index = sql,
    __tostring = function(t)
        if t.conn then
            return 'sqlite: '..t.path
        else
            return 'sqlite (dead): '..t.path
        end
    end,
}
sql.ct = {
    conn = ffi.new('sqlite3*[1]'),
    stmt = ffi.new('sqlite3_stmt*[1]'),
}

function sql.new(path, mode)
    local self = setmetatable({}, sql.mt)
    mode = assert(open_modes[mode or 'rwc'])
    local code = lib.sqlite3_open_v2(path, sql.ct.conn, mode, nil)
    self.path = path
    self.conn = sql.ct.conn[0]
    self:check(code)
    self.stmt_cache = {}
    return self
end
sql.open = sql.new

function sql:close()
    assert(self.conn)
    for _,stmt in pairs(self.stmt_cache) do
        self:check(lib.sqlite3_finalize(stmt))
    end
    self.stmt_cache = {}
    self:check(lib.sqlite3_close(self.conn))
    self.conn = nil
end

function sql:check(code)
    if not(code == lib.SQLITE_OK) then
        error(ffi.string(lib.sqlite3_errmsg(self.conn)))
    end
end

function sql.esc(v)
    if v == nil then
        return 'NULL'
    else
        return "'"..string.gsub(v, "'", "''").."'"
    end
end

local function wrap(f)
    return function(self, query, should_cache)
        assert(self.conn)

        if self.atomic then
            self:lock()
        end

        local stmt = self.stmt_cache[query]
        if not stmt then
            self:check(lib.sqlite3_prepare_v2(self.conn, query, #query, sql.ct.stmt, nil))
            stmt = sql.ct.stmt[0]
        end

        local result = f(self, stmt)

        if should_cache then
            self:check(lib.sqlite3_reset(stmt))
            self.stmt_cache[query] = stmt
        else
            self:check(lib.sqlite3_finalize(stmt))
            self.stmt_cache[query] = nil
        end

        if self.atomic then
            self:unlock()
        end

        return result
    end
end

local eval = {}
eval[lib.SQLITE_INTEGER] = function(stmt, i)
    local i64 = lib.sqlite3_column_int64(stmt, i)

    local num = tonumber(i64)
    if num == i64 then
        -- return a regular number if we can
        return num
    else
        return i64
    end
end
eval[lib.SQLITE_FLOAT] = function(stmt, i)
    return lib.sqlite3_column_double(stmt, i)
end
eval[lib.SQLITE_TEXT] = function(stmt, i)
    return ffi.string(lib.sqlite3_column_text(stmt, i))
end
eval[lib.SQLITE_NULL] = function(stmt, i)
    return nil
end
local function step(stmt)
    local code = lib.sqlite3_step(stmt)
    if code == lib.SQLITE_DONE then
        return nil
    end
    assert(code == lib.SQLITE_ROW, codes[code])
    local row = {}
    for i=0,lib.sqlite3_column_count(stmt)-1 do
        local k = lib.sqlite3_column_name(stmt, i)
        local t = lib.sqlite3_column_type(stmt, i)
        row[ffi.string(k)] = eval[t](stmt, i)
    end
    return row
end
sql.exec = wrap(function(self, stmt)
    local result = {}
    local i = 0
    while true do
        local row = step(stmt)
        if not row then
            break
        end
        i = i + 1
        result[i] = row
    end

    return result
end)

sql.int = wrap(function(self, stmt)
    local code = lib.sqlite3_step(stmt)
    if code == lib.SQLITE_DONE then
        return nil
    end
    assert(code == lib.SQLITE_ROW)
    return lib.sqlite3_column_int(stmt, 0)
end)

sql.float = wrap(function(self, stmt)
    local code = lib.sqlite3_step(stmt)
    if code == lib.SQLITE_DONE then
        return nil
    end
    assert(code == lib.SQLITE_ROW)
    return lib.sqlite3_column_double(stmt, 0)
end)

sql.text = wrap(function(self, stmt)
    local code = lib.sqlite3_step(stmt)
    if code == lib.SQLITE_DONE then
        return nil
    end
    assert(code == lib.SQLITE_ROW)
    return ffi.string(lib.sqlite3_column_text(stmt, 0))
end)



local flock
function sql:lock()
    if self.lock_count then
        self.lock_count = self.lock_count + 1
        return
    end
    if not self.lockfd then
        flock = require 'flock'
        self.lockfd = flock.new(self.lockpath or self.path..'.lock')
    end
    flock.lock(self.lockfd)
    self.lock_count = (self.lock_count or 0) + 1
end

function sql:unlock()
    if not self.lock_count then
        error('not locked')
    elseif self.lock_count == 1 then
        flock.unlock(self.lockfd)
        self.lock_count = nil
    else
        self.lock_count = self.lock_count - 1
    end
end


return sql
