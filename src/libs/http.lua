local http_lib = require("libs.http_lib")
require("libs.types")
local http = {}
---@param url string
---@param path? string
-- http.download = function(url, path)
--     local succeed = pcall(wininet.DeleteUrlCacheEntryA, url)
--     if succeed == 0 then return false end
--     if path == nil then path = os.tmpname() end
--     local result = pcall(urlmon.URLDownloadToFileA, nil, url, path, 0, 0)
--     if result == 0 then return false end
--     return path
-- end
http.download = function (url, path, callback)
    if path == nil then path = os.tmpname() end
    http_lib.request("get", url, {}, function(success, response)
        if not success or not response.body then error("couldn't download a file") end
        local file = io.open(path, "wb")
        if not file then return end
        file:write(response.body)
        file:close()
        callback(path)
    end)
end
http.get = function(url, callback)
    http_lib.request("get", url, {}, function(success, response)
        if not success or not response.body then return end
        callback(response.body)
    end)
end
return http