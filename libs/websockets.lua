jit.off()
collectgarbage("stop")
local ffi = require("ffi")
local sockets = client and ffi.load("lua/libs/sockets") or ffi.load("libs/sockets")
local cbs = require("libs.callbacks")
ffi.cdef[[
    typedef void(*callback)(void*, int, char*, int);
    bool Close(void* hWebSocket);
    void* Connect(const char* host, int port, const char* path, callback callback);
    bool Send(void* hWebSocket, const char* data, int length);
]]

local websocket = {
    ---@class __websocket_t
    ---@field ws ffi.ctype*
    __index = {
        ---@param self __websocket_t
        ---@param data string
        send = function(self, data)
            return sockets.Send(self.ws, data, #data)
        end,
        ---@param self __websocket_t
        close = function(self)
            return sockets.Close(self.ws)
        end
    }
}
local websockets = {}
local ws = {
    ---comment
    ---@param host string
    ---@param port number
    ---@param path string
    ---@param callback fun(s: __websocket_t, code: number, data: ffi.ctype*, length: number)
    ---@return __websocket_t
    connect = function(host, port, path, callback)
        local t = {}
        setmetatable(t, websocket)
        local fn = function(handle, code, data, length)
            t.ws = handle
            pcall(callback, t, code, ffi.string(data, length))
        end
        t.ws = sockets.Connect(host, port, path or "", fn)
        websockets[#websockets+1] = t
        return t
    end,
    stop = function()
        for i = 1, #websockets do
            websockets[i]:close()
        end
    end
}
cbs.add("unload", ws.stop)
local s = ws.connect("localhost", 3000, "/", function(s, code, data)
    if code == 0 then
        s:send("Hello from Lua!")
    end
    if code == 1 then
        print("RECEIVED: " .. data)
    end
end)
jit.off()