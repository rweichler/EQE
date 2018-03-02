local flock = {}
local ffi = require 'ffi'
local bit = require 'bit'
local C = ffi.C
ffi.cdef[[
int flock(int fd, int operation);
typedef uint16_t mode_t;
int access(const char *path, int amode);
int open(const char *path, int oflags, mode_t mode);
int close(int fd);
int chmod(const char *path, mode_t mode);

typedef uint32_t uid_t;
typedef uint32_t gid_t;
int chown(const char *path, uid_t uid, gid_t gid);
]]
local F_OK = 0
local LOCK_EX = 2
local LOCK_UN = 8
local O_RDONLY = 0x0000
local O_RDWR = 0x0002
local O_APPEND = 0x0008
local O_CREAT = 0x0200

function flock.new(path)
    if C.access(path, F_OK) == -1 then
        -- create the lockfile if it doesnt exist
        local fd = C.open(path, O_CREAT, tonumber(666, 8))
        if fd == -1 then
            error('couldnt create lockfile')
        end
        C.close(fd)
        C.chmod(path, tonumber(400, 8))
        C.chown(path, 501, 501)
    end
    local fd = C.open(path, O_RDONLY, tonumber(666, 8))
    if fd == -1 then
        error('couldnt open lockfile')
    end
    return fd
end

function flock.lock(fd)
    return C.flock(fd, LOCK_EX)
end

function flock.unlock(fd)
    return C.flock(fd, LOCK_UN)
end

return flock
