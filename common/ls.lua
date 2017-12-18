local ffi = require 'ffi'
local C = ffi.C

ffi.cdef[[
struct dirent{
    uint64_t d_ino;
    uint64_t d_seekoff;
    uint16_t d_reclen;
    uint16_t d_namlen;
    uint8_t d_type;
    char d_name[1024];
};
typedef void DIR;

DIR *opendir(const char *);
int closedir(DIR *dirp);
struct dirent *readdir(DIR *);
]]

return function (directory)
    dir = C.opendir(directory)
    if dir == ffi.NULL then return end
    local i = 0
    local t = {}
    local ent = C.readdir(dir)
    while not(ent == ffi.NULL) do
        local name = ffi.string(ent.d_name)
        if not(name == '.' or name == '..') then
            i = i + 1
            t[i] = ffi.string(ent.d_name)
        end
        ent = C.readdir(dir)
    end
    C.closedir(dir)
    return t
end
