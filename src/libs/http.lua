local http_lib = require("libs.http_lib")
require("libs.types")
local http = {}
---@param url string
---@param path? string
---@param callback fun(path: string)
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
---@param url string
---@param callback fun(body: string)
http.get = function(url, callback)
    http_lib.request("get", url, {}, function(success, response)
        if not success or not response.body then return end
        callback(response.body)
    end)
end
return http