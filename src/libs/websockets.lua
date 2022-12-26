local cbs = require("libs.callbacks")
require("libs.types")
ffi.cdef[[
    bool Close(void*);
    void* Connect(const char*, int, const char*);
    bool Send(void*, const char*, int);
    typedef struct {
        int code;
        char data[1024];
        int length;
    } CallbackData;
    CallbackData* GetData(void*);
    BOOL VirtualFree(void*, SIZE_T, DWORD);
]]
local callback_data_size = ffi.sizeof("CallbackData")

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
        ---@param callback fun(s: __websocket_t, code: number, data: string)
        execute = function(s, callback)
            local callback_data = ws.sockets.GetData(s.ws)
            if callback_data == nil then return end
            local code = callback_data.code
            local data = ""
            if callback_data.length > 0 then
                data = ffi.string(callback_data.data, callback_data.length)
            end
            pcall(callback, s, code, data)
            ffi.C.VirtualFree(callback_data, callback_data_size, 0x8000)
        end
    }
}
local websockets = {}

---@param host string
---@param port number
---@param path string
---@return __websocket_t|nil
ws.connect = function(host, port, path)
    local t = {}
    setmetatable(t, websocket)
    t.ws = ws.sockets.Connect(host, port, path or "")
    if t.ws == nil then return end
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
