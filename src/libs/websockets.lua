local cbs = require("libs.callbacks")
ffi.cdef[[
    typedef void(*callback)(void*, int, char*, int);
    bool Close(void* hWebSocket);
    void* Connect(const char* host, int port, const char* path, callback callback);
    bool Send(void* hWebSocket, const char* data, int length);
]]

local ws = {
    sockets = nil
}

local websocket = {
    ---@class __websocket_t
    ---@field ws ffi.ctype*
    __index = {
        ---@param s __websocket_t
        ---@param data string
        send = function(s, data)
            return ws.sockets.Send(s.ws, data, #data)
        end,
        ---@param s __websocket_t
        close = function(s)
            return ws.sockets.Close(s.ws)
        end,
        execute = function(s)
            for i = 1, #(s.callbacks or {}) do
                local fn = s.callbacks[i]
                if fn then
                    table.remove(s.callbacks, i)
                    local status, result = pcall(fn)
                    if not status then
                        error(result, 0)
                    end
                end
            end
        end
    }
}
local websockets = {}

---@param host string
---@param port number
---@param path string
---@param callback fun(s: __websocket_t, code: number, data: string)
---@param multithreaded boolean|nil
---@return __websocket_t|nil
ws.connect = function(host, port, path, callback, multithreaded)
    jit.off()
    local t = {}
    if not multithreaded then
        t.callbacks = {}
    end
    setmetatable(t, websocket)
    local fn = function(handle, code, data, length)
        jit.off()
        t.ws = handle
        local str = length > 0 and ffi.string(data, length) or ""
        if not multithreaded then
            --create a new thread for each callback to prevent crashes
            t.callbacks[#t.callbacks+1] = function()
                callback(t, code, str)
            end
        else
            pcall(callback, t, code, str)
        end
    end
    local result = ws.sockets.Connect(host, port, path or "", fn)
    if result == nil then return end
    t.ws = result
    websockets[#websockets+1] = t
    return t
end
ws.stop = function()
    for i = 1, #websockets do
        if websockets[i] then
            websockets[i]:close()
        end
    end
end
cbs.add("unload", ws.stop)
return ws
