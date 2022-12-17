local urlmon = ffi.load("urlmon")
local wininet = ffi.load("wininet")
require("libs.types")
ffi.cdef[[
    DWORD __stdcall URLDownloadToFileA(void*, const char*, const char*, int, int);        
    bool DeleteUrlCacheEntryA(const char*);
]]
local http = {}
http.download = function(url, path)
    local succeed = pcall(wininet.DeleteUrlCacheEntryA, url)
    if succeed == 0 then return false end
    if path == nil then path = os.tmpname() end
    local result = pcall(urlmon.URLDownloadToFileA, nil, url, path, 0, 0)
    if result == 0 then return false end
    return path
end
http.get = function(url)
    local path = os.tmpname()
    local succeed = http.download(url, path)
    if not succeed then return false end
    local file = io.open(path, "rb")
    if not file then return end
    local data = file:read("*all")
    file:close()
    os.remove(path)
    return data
end
return http