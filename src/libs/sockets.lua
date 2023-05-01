local json = require("libs.json")

---@class __sockets_t
---@field websocket __websocket_t
---@field encrypt fun(data: string): string
local sockets = {}
sockets.callbacks = {}
---@param type_name string
---@param callback fun(s: __websocket_t, data: table<string, any>)
sockets.add = function(type_name, callback)
    if type_name == "on_socket_init" then
        sockets.callbacks[type_name] = sockets.callbacks[type_name] or {}
        return table.insert(sockets.callbacks[type_name], callback)
    end
    sockets.callbacks[type_name] = callback
end
sockets.init = function(websocket)
    sockets.websocket = websocket
    if sockets.callbacks.on_socket_init then
        for i = 1, #sockets.callbacks.on_socket_init do
            sockets.callbacks.on_socket_init[i](websocket)
        end
    end
end
---@param data table
sockets.send = function(data)
    if not sockets.websocket then return false end
    local encoded = json.encode(data)
    if not encoded then
        error("failed to encode data")
    end
    local encrypted = sockets.encrypt(encoded)
    if not encrypted then
        error("failed to encrypt data")
    end
    return sockets.websocket:send(encrypted)
end

return sockets