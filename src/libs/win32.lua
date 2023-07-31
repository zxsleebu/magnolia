local ffi = require("libs.protected_ffi")
local shell = ffi.load("Shell32")
local kernel32 = ffi.load("Kernel32")
local ucrtbase = ffi.load("ucrtbase")
local errors = require("libs.error_handler")
local interface = require("libs.interfaces")()
require("libs.types")
ffi.cdef[[
    void* __stdcall ShellExecuteA(void*, PCSTR, PCSTR, PCSTR, PCSTR, int);
    int MultiByteToWideChar(UINT, DWORD, PCSTR, int, wchar_t*, int);
    int WideCharToMultiByte(UINT, DWORD, const wchar_t*, int, char*, int, PCSTR, BOOL*);
    wchar_t* _wgetenv(const wchar_t*);
    int VirtualProtect(void*, DWORD, DWORD, DWORD*);
    void* VirtualAlloc(void*, DWORD, DWORD, DWORD);
    typedef struct {
        DWORD dwLowDateTime;
        DWORD dwHighDateTime;
    } FILETIME;
    typedef struct {
        DWORD    dwFileAttributes;
        FILETIME ftCreationTime;
        FILETIME ftLastAccessTime;
        FILETIME ftLastWriteTime;
        DWORD    nFileSizeHigh;
        DWORD    nFileSizeLow;
        DWORD    dwReserved0;
        DWORD    dwReserved1;
        wchar_t  cFileName[260];
        wchar_t  cAlternateFileName[14];
        DWORD    dwFileType;
        DWORD    dwCreatorType;
        WORD     wFinderFlags;
    } WIN32_FIND_DATA;
    void* FindFirstFileA(const char*, WIN32_FIND_DATA*);
    bool FindNextFileA(void* hFindFile, WIN32_FIND_DATA*);
    bool FindClose(void* hFindFile);
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
win32.get_env = function(name)
    local wname = win32.to_wide(name)
    local wvalue = ucrtbase._wgetenv(wname)
    return win32.to_utf8(wvalue)
end
win32.copy = function(dst, src, len)
    ffi.copy(ffi.cast('void*', dst), ffi.cast('const void*', src), len)
end
win32.VirtualProtect = function(addr, size, new_protect, old_protect)
    return ffi.C.VirtualProtect(ffi.cast('void*', addr), size, new_protect, old_protect)
end
win32.VirtualAlloc = function(addr, size, alloctype, protect, free)
    local alloc = ffi.C.VirtualAlloc(addr, size, alloctype, protect)
    return ffi.cast('intptr_t', alloc)
end
local save_name = function (file_data, extension, only_dirs)
    local name = ffi.string(ffi.cast("char*", file_data[0].cFileName))
    if name == "." or name == ".." then return end
    local is_folder = bit.band(file_data[0].dwFileAttributes, 0x10) ~= 0
    if not is_folder and extension then
        local ext = name:sub(-#extension, -1)
        if ext ~= extension then return end
    end
    if only_dirs and is_folder then
        return
    end
    return name, is_folder
end
win32.dir = function(path, only_dirs, extension, recursive)
    local files = {}
    local function add(name, is_folder)
        if not name then return end
        if recursive and is_folder then
            local list = win32.dir(path..name.."\\", false, extension, true)
            if list then
                for i = 1, #list do
                    files[#files+1] = name.."\\"..list[i]
                end
            end
        else
            files[#files+1] = name
        end
    end
    local file_data = ffi.new("WIN32_FIND_DATA[1]")
    local handle = ffi.C.FindFirstFileA(path.."*", file_data)
    if handle == -1 then return end

    local name, is_folder = save_name(file_data, extension, only_dirs)
    add(name, is_folder)
    while kernel32.FindNextFileA(handle, file_data) do
        name, is_folder = save_name(file_data, extension, only_dirs)
        add(name, is_folder)
    end
    kernel32.FindClose(handle)
    return files
end

local vgui2 = interface.new("vgui2", "VGUI_System010", {
    SetClipboardText = {9, "void(__thiscall*)(void*, const char*, int)"},
})
win32.copy_to_clipboard = errors.handler(function(text)
    text = tostring(text)
    vgui2:SetClipboardText(text, #text)
end)
return win32