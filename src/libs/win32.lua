local ffi = require("libs.protected_ffi")
local shell = ffi.load("Shell32")
ffi.cdef[[
    void* __stdcall ShellExecuteA(void*, const char*, const char*, const char*, const char*, int);
]]
local win32 = {}
win32.open_url = function(url)
    shell.ShellExecuteA(nil, "open", url, nil, nil, 1)
end
return win32