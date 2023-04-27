local cbs = require("libs.callbacks")
local _, class = require("libs.interfaces")()
local websockets_lib
require("libs.types")
ffi.cdef[[
    void* Create(const char*, const char*, int);
    typedef struct {
        char code;
        char data[1024];
        int length;
    } DataStruct;
]]
local websocket_class = class.new({
    connect = { 0, "bool(__thiscall*)(void*)" },
    get_data = { 1, "bool(__thiscall*)(void*, DataStruct*)" },
    send = { 2, "void(__thiscall*)(void*, const char*, int)" },
    close = { 3, "void(__thiscall*)(void*)" },
    delete = { 4, "void(__thiscall*)(void*)" },
})
local websocket = {
    CONNECTED = 0,
    DATA = 1,
    DISCONNECTED = 2,
    ERROR = 3
}
---@class __websocket_t
---@field valid boolean
local websocket_t = {
    --*dirty hack to make autocomplete work
    ws = websocket_class.__functions,
}
---@param data string
---@return boolean
websocket_t.send = function(self, data)
    if not self.valid then return false end
    return self.ws:send(data, #data)
end
websocket_t.connect = function(self)
    if not self.valid then return false end
    return self.ws:connect()
end
websocket_t.close = function(self)
    if not self.valid then return false end
    return self.ws:close()
end
---@param callback fun(self: __websocket_t, code: number, data: string, length: number)
websocket_t.execute = function(self, callback)
    if not self.valid then return end
    local struct = ffi.new("DataStruct")
    local result = self.ws:get_data(struct)
    if not result then return end
    local code, length = struct.code, struct.length
    local data = ""
    if length > 0 then
        data = ffi.string(struct.data, math.min(length, 1024))
    end
    if code == websocket.CONNECTED then
        self.connected = true
    elseif code == websocket.DISCONNECTED or code == websocket.ERROR then
        self.connected = false
    end
    pcall(callback, self, code, data, length)
end

websocket.new = function(host, path, port)
    local raw_socket = websockets_lib.Create(host, path, port)
    local socket = setmetatable({
        ws = websocket_class(raw_socket),
        valid = true,
        connected = false,
    }, { __index = websocket_t })
    cbs.add("unload", function()
        socket.connected = false
        socket.valid = false
        socket.ws:close()
    end)
    return socket
end
websocket.init = function(lib)
    websockets_lib = lib
end

return websocket
