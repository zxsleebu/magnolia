local cbs = require("libs.callbacks")
local _, class = require("libs.interfaces")()
local ffi = require("libs.protected_ffi")
local websocket_library
require("libs.types")
ffi.cdef[[
    typedef struct {
        char code;
        char data[1024];
        int length;
    } DataStruct;
    __cdecl void* Create(PCSTR);
    __cdecl void Unload();
]]
local websocket_class = class.new({
    connect = { 0, "bool(__thiscall*)(void*)" },
    is_data_available = { 1, "bool(__thiscall*)(void*)" },
    get_data = { 2, "bool(__thiscall*)(void*, DataStruct*)" },
    send = { 3, "void(__thiscall*)(void*, PCSTR)" },
})
local websocket = {
    CONNECTED = 0,
    DATA = 1,
    DISCONNECTED = 2,
    ERROR = 3,
    initialized = false
}
---@class __websocket_t
---@field valid boolean
---@field connected boolean
local websocket_t = {
    --*dirty hack to make autocomplete work
    ws = websocket_class.__functions
}
---@param data string
---@return boolean
websocket_t.send = function(self, data)
    if not self.valid or not self.connected then return false end
    return self.ws:send(data)
end
websocket_t.connect = function(self)
    if not self.valid then return false end
    return self.ws:connect()
end
---@param callback fun(self: __websocket_t, code: number, data: string, length: number)
websocket_t.execute = function(self, callback)
    if not self.valid then return end
    if not self.ws:is_data_available() then return end
    local struct = ffi.new("DataStruct")
    local result = self.ws:get_data(struct)
    if not result then return end
    local code, length = struct.code, struct.length
    local data = ""
    if code == websocket.DATA and length > 0 then
        data = ffi.string(struct.data, math.min(length, 1024))
    elseif code == websocket.CONNECTED and not self.connected then
        self.connected = true
    elseif code == websocket.DISCONNECTED or code == websocket.ERROR then
        self.connected = false
    end
    callback(self, code, data, length)
end

websocket.new = function(url)
    if not websocket_library then
        error("websocket library not initialized")
    end
    local raw_socket = websocket_library.Create(url)
    local socket = setmetatable({
        ws = websocket_class(raw_socket),
        valid = true,
        connected = false,
    }, { __index = websocket_t })
    cbs.add("unload", function()
        socket.connected = false
        socket.valid = false
    end)
    return socket
end
websocket.init = function(lib)
    websocket_library = ffi.load(lib)
    websocket.initialized = true
end
cbs.critical("unload", function ()
    if not websocket_library then return end
    websocket_library.Unload()
end)
return websocket
