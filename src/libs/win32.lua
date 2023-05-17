local ffi = require("libs.protected_ffi")
local shell = ffi.load("Shell32")
require("libs.types")
ffi.cdef[[
    void* __stdcall ShellExecuteA(void*, PCSTR, PCSTR, PCSTR, PCSTR, int);
    int MultiByteToWideChar(UINT, DWORD, PCSTR, int, wchar_t*, int);
    int WideCharToMultiByte(UINT, DWORD, const wchar_t*, int, char*, int, PCSTR, BOOL*);
]]
local win32 = {}
win32.open_url = function(url)
    shell.ShellExecuteA(nil, "open", url, nil, nil, 1)
end
win32.to_wide = function(str)
    local len = ffi.C.MultiByteToWideChar(65001, 0, str, -1, nil, 0)
    local buf = ffi.new("wchar_t[?]", len)
    ffi.C.MultiByteToWideChar(65001, 0, str, -1, buf, len)
    return buf
end
win32.to_utf8 = function(wstr)
    local len = ffi.C.WideCharToMultiByte(65001, 0, wstr, -1, nil, 0, nil, nil)
    local str = ffi.new("char[?]", len)
    ffi.C.WideCharToMultiByte(65001, 0, wstr, -1, str, len, nil, nil)
    return ffi.string(str)
end
return win32