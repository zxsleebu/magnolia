local json = require("libs.json");
local json_parse = json.parse or json.decode
local json_stringify = json.stringify or json.encode

local cbs = require("libs.callbacks")

local find_sig = function(mdlname, pattern, typename, offset, deref_count)
    local raw_match = find_pattern(mdlname, pattern) or error("signature not found", 2)
    local match = ffi.cast("uintptr_t", raw_match)

    if offset ~= nil and offset ~= 0 then
        match = match + offset
    end

    if deref_count ~= nil then
        for i = 1, deref_count do
            match = ffi.cast("uintptr_t*", match)[0]
            if match == nil then
                return error("signature not found")
            end
        end
    end

    return ffi.cast(typename, match)
end

local register_call_result, register_callback_steam
do
    if not pcall(ffi.sizeof, "SteamAPICall_t") then
        ffi.cdef [[
            typedef uint64_t SteamAPICall_t;
        ]]
    end

    local SteamAPI_callback_base_vtbl = ffi.typeof([[
        struct {
            void(__thiscall *run1)(void*, void*, bool, uint64_t);
            void(__thiscall *run2)(void*, void*);
            int(__thiscall *get_size)(void*);
        }
    ]])

    local SteamAPI_callback_base      = ffi.typeof([[
        struct {
            $ *vtbl;
            uint8_t flags;
            int id;
            uint64_t api_call_handle;
            $ vtbl_storage[1];
        }
    ]], SteamAPI_callback_base_vtbl, SteamAPI_callback_base_vtbl)

    local SteamAPI_RegisterCallResult, SteamAPI_UnregisterCallResult
    local SteamAPI_RegisterCallback, SteamAPI_UnregisterCallback

    local callback_base               = SteamAPI_callback_base
    local sizeof_callback_base        = ffi.sizeof(callback_base)
    local callback_base_array         = ffi.typeof("$[1]", SteamAPI_callback_base)
    local callback_base_ptr           = ffi.typeof("$*", SteamAPI_callback_base)
    local api_call_handlers           = {}
    local pending_call_results        = {}
    local registered_callbacks        = {}

    local function pointer_key(p)
        return tostring(tonumber(ffi.cast("uintptr_t", p)))
    end

    local function callback_base_run_common(self, param, io_failure)
        self.api_call_handle = 0

        local key = pointer_key(self)
        local handler = api_call_handlers[key]
        if handler ~= nil then
            xpcall(handler, print, param, io_failure)
        end

        if pending_call_results[key] ~= nil then
            api_call_handlers[key] = nil
            pending_call_results[key] = nil
        end
    end

    local function callback_base_run1(self, param, io_failure, api_call_handle)
        if api_call_handle == self.api_call_handle then
            callback_base_run_common(self, param, io_failure)
        end
    end

    local function callback_base_run2(self, param)
        callback_base_run_common(self, param, false)
    end

    local function callback_base_get_size(self)
        return sizeof_callback_base
    end

    local callback_base_run1_ct = ffi.cast(ffi.typeof("void(__thiscall*)($*, void*, bool, uint64_t)", SteamAPI_callback_base), callback_base_run1)
    local callback_base_run2_ct = ffi.cast(ffi.typeof("void(__thiscall*)($*, void*)", SteamAPI_callback_base), callback_base_run2)
    local callback_base_get_size_ct = ffi.cast(ffi.typeof("int(__thiscall*)($*)", SteamAPI_callback_base), callback_base_get_size)

    SteamAPI_RegisterCallResult = find_sig("steam_api.dll", "55 8B EC 83 3D ? ? ? ? ? 7E ? 68 ? ? ? ? FF 15 ? ? ? ? 5D C3 FF 75 ? C7 05 ? ? ? ? ? ? ? ? FF 75 ? FF 75 ?", ffi.typeof("void(__cdecl*)($*, uint64_t)", SteamAPI_callback_base))
    SteamAPI_UnregisterCallResult = find_sig("steam_api.dll", "55 8B EC FF 75 ? FF 75 ? FF 75 ? E8 ? ? ? ?", ffi.typeof("void(__cdecl*)($*, uint64_t)", SteamAPI_callback_base))

    SteamAPI_RegisterCallback = find_sig("steam_api.dll", "55 8B EC 83 3D ? ? ? ? ? 7E ? 68 ? ? ? ? FF 15 ? ? ? ? 5D C3 C7 05 ? ? ? ? ? ? ? ?", ffi.typeof("void(__cdecl*)($*, int)", SteamAPI_callback_base))
    SteamAPI_UnregisterCallback = find_sig("steam_api.dll", "E9 ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? 55 8B EC", ffi.typeof("void(__cdecl*)($*)", SteamAPI_callback_base))

    if SteamAPI_RegisterCallback == nil or SteamAPI_UnregisterCallback == nil then
        error("failed to find steam callback functions")
    end

    if SteamAPI_RegisterCallResult == nil or SteamAPI_UnregisterCallResult == nil then
        error("failed to find steam call result functions")
    end

    function register_call_result(api_call_handle, handler, id)
        if api_call_handle ~= 0 then
            local instance_storage = callback_base_array()
            local instance = ffi.cast(callback_base_ptr, instance_storage)

            instance.vtbl_storage[0].run1 = callback_base_run1_ct
            instance.vtbl_storage[0].run2 = callback_base_run2_ct
            instance.vtbl_storage[0].get_size = callback_base_get_size_ct
            instance.vtbl = instance.vtbl_storage
            instance.api_call_handle = api_call_handle
            instance.id = id

            local key = pointer_key(instance)
            api_call_handlers[key] = handler
            pending_call_results[key] = instance_storage

            SteamAPI_RegisterCallResult(instance, api_call_handle)

            return instance
        end
    end

    function register_callback_steam(id, handler)
        if registered_callbacks[id] == nil then
            local instance_storage = callback_base_array()
            local instance = ffi.cast(callback_base_ptr, instance_storage)

            instance.vtbl_storage[0].run1 = callback_base_run1_ct
            instance.vtbl_storage[0].run2 = callback_base_run2_ct
            instance.vtbl_storage[0].get_size = callback_base_get_size_ct
            instance.vtbl = instance.vtbl_storage
            instance.api_call_handle = 0
            instance.id = id

            local key = pointer_key(instance)
            api_call_handlers[key] = handler
            registered_callbacks[id] = instance_storage

            SteamAPI_RegisterCallback(instance, id)
        end
    end

    local function call_result_cancel(self)
        if self.api_call_handle ~= 0 then
            SteamAPI_UnregisterCallResult(self, self.api_call_handle)
            self.api_call_handle = 0

            local key = pointer_key(self)
            api_call_handlers[key] = nil
            pending_call_results[key] = nil
        end
    end

    pcall(ffi.metatype, callback_base, {
        __gc = call_result_cancel,
        __index = {
            cancel = call_result_cancel
        }
    })

    cbs.critical("unload", function()
        for _, value in pairs(pending_call_results) do
            local instance = ffi.cast(callback_base_ptr, value)
            call_result_cancel(instance)
        end

        for _, value in pairs(registered_callbacks) do
            local instance = ffi.cast(callback_base_ptr, value)
            SteamAPI_UnregisterCallback(instance)
        end
    end)
end

if not pcall(ffi.sizeof, "http_HHTMLBrowser") then
    ffi.cdef [[
        typedef uint32_t http_HHTMLBrowser;

        struct http_ISteamHTMLSurfaceVtbl {
            bool(__thiscall *ISteamHTMLSurface)(uintptr_t);
            uintptr_t pad1[2];
            SteamAPICall_t(__thiscall *CreateBrowser)(uintptr_t, const char*, const char*);
            void(__thiscall *RemoveBrowser)(uintptr_t, http_HHTMLBrowser);
            void(__thiscall *LoadURL)(uintptr_t, http_HHTMLBrowser, const char*, const char*);
            uintptr_t pad2[6];
            void(__thiscall *ExecuteJavascript)(uintptr_t, http_HHTMLBrowser, const char*);
            uintptr_t pad3[22];
            void(__thiscall *AllowStartRequest)(uintptr_t, http_HHTMLBrowser, bool);
            void(__thiscall *JSDialogResponse)(uintptr_t, http_HHTMLBrowser, bool);
            uintptr_t pad4;
        };
    ]]
end

local CALLBACK_HTML_BrowserReady_t = 4501

local CALLBACK_HTML_StartRequest_t = 4503
local CALLBACK_HTML_URLChanged_t = 4505
local CALLBACK_HTML_ChangedTitle_t = 4508
local CALLBACK_HTML_JSAlert_t = 4514

local function find_isteamhtmlsurface()
    local steam_client_context = find_sig("client.dll", "B9 ? ? ? ? E8 ? ? ? ? 83 3D ? ? ? ? ? 0F 84", "uintptr_t", 1, 1)
    local steamhtmlsurface = ffi.cast("uintptr_t*", steam_client_context)[18]

    if steamhtmlsurface == 0 then
        return error("find_isteamhtmlsurface failed")
    end

    local vmt = ffi.cast("struct http_ISteamHTMLSurfaceVtbl**", steamhtmlsurface)[0]
    if vmt == nil then
        return error("find_isteamhtmlsurface failed")
    end

    return steamhtmlsurface, vmt
end

local function func_bind(func, arg)
    return function(...)
        return func(arg, ...)
    end
end

local HTML_BrowserReady_t_ptr = ffi.typeof([[
struct {
    http_HHTMLBrowser unBrowserHandle;
} *
]])

local HTML_StartRequest_t_ptr = ffi.typeof([[
struct {
    http_HHTMLBrowser unBrowserHandle;
    const char* pchURL;
    const char* pchTarget;
    const char* pchPostData;
    bool bIsRedirect;
} *
]])

local HTML_JSAlert_t_ptr = ffi.typeof([[
struct {
    http_HHTMLBrowser unBrowserHandle;
    const char* pchMessage;
} *
]])


local HTML_ChangedTitle_t_ptr = ffi.typeof([[
struct {
    http_HHTMLBrowser unBrowserHandle;
    const char* pchTitle;
} *
]])

local HTML_URLChanged_t_ptr = ffi.typeof([[
struct {
    http_HHTMLBrowser unBrowserHandle;
    const char* pchURL;
    const char* pchPostData;
    bool bIsRedirect;
    const char* pchPageTitle;
    bool bNewNavigation;
} *
]])

local steam_htmlsurface, steam_htmlsurface_vtable = find_isteamhtmlsurface()

if not steam_htmlsurface_vtable then
    return error("failed to find ISteamHTMLSurface")
end

local native_ISteamHTMLSurface_CreateBrowser = func_bind(steam_htmlsurface_vtable.CreateBrowser, steam_htmlsurface)
local native_ISteamHTMLSurface_RemoveBrowser = func_bind(steam_htmlsurface_vtable.RemoveBrowser, steam_htmlsurface)
local native_ISteamHTMLSurface_LoadURL = func_bind(steam_htmlsurface_vtable.LoadURL, steam_htmlsurface)
local native_ISteamHTMLSurface_ExecuteJavascript = func_bind(steam_htmlsurface_vtable.ExecuteJavascript, steam_htmlsurface)
local native_ISteamHTMLSurface_AllowStartRequest = func_bind(steam_htmlsurface_vtable.AllowStartRequest, steam_htmlsurface)
local native_ISteamHTMLSurface_JSDialogResponse = func_bind(steam_htmlsurface_vtable.JSDialogResponse, steam_htmlsurface)
local browser_handle

local handlers = {}
local Client = {
    send = function(message)
        if browser_handle ~= nil then
            native_ISteamHTMLSurface_ExecuteJavascript(browser_handle, string.format("Client.receive(%s)", json_stringify(message)))
        end
    end,
    receive = function(message)
        message = json_parse(message)

        if handlers[message.type] ~= nil then
            handlers[message.type](message)
        end
    end,
    register_handler = function(type, callback)
        handlers[type] = callback
    end
}

local rpc_functions = {}
local RPCServer = {
    register = function(name, callback)
        rpc_functions[name] = callback
    end
}

Client.register_handler("rpc", function(message)
    if rpc_functions[message.method] then
        local resp = {
            type = "rpc_resp",
            id = message.id
        }

        local success, ret = pcall(rpc_functions[message.method], unpack(message.params or {}))

        if success then
            resp.result = ret
        else
            resp.error = ret
        end

        Client.send(resp)
    end
end)

local pending_rpc_callbacks, rpc_index = {}, 0
local RPCClient = {
    call = function(method, callback, ...)
        rpc_index = rpc_index + 1

        local message = {
            type = "rpc",
            method = method,
            id = rpc_index
        }

        local args = { ... }

        if #args > 0 then
            message.params = args
        end

        pending_rpc_callbacks[rpc_index] = callback
        Client.send(message)
    end
}

Client.register_handler("rpc_resp", function(resp)
    if pending_rpc_callbacks[resp.id] ~= nil then
        if resp.error ~= nil then
            xpcall(pending_rpc_callbacks[resp.id], print, resp.error)
        else
            xpcall(pending_rpc_callbacks[resp.id], print, nil, resp.result)
        end
    end
end)

local function setup_browser(browser_ready_callback)
    local js_string = [[
        // communication with client
        var Client = (function(){
            var handlers = {}
            var _SendMessage = function(message) {
                var json = JSON.stringify(message)

                // console.log(`sending ${json}`)

                if(json.length > 10200) {
                    // alert has a size limit, so we need to use document.location.hash - should be rare since it has its own rate limiting too
                    var ensureChangeChar = document.location.hash[1] == "h" ? "H" : "h"

                    // setting location causes a HTML_ChangedTitle_t event (even if the title didnt actually change) so we set it to an empty string here and avoid that
                    document.title = ""
                    document.location.hash = ensureChangeChar + json

                    // console.log("used hash with ensureChangeChar " + JSON.stringify(ensureChangeChar))
                } else if(json.length > 4090) {
                    // alert has no rate limit but is rather slow (and limited to 10240 chars), so only use it if its required
                    alert(json)
                    // console.log("used alert")
                } else {
                    // title has an even smaller size limit (4096), but its the fastest
                    var ensureChangeChar = document.title[0] == "t" ? "T" : "t"
                    document.title = ensureChangeChar + json
                    // console.log("used title with ensureChangeChar " + JSON.stringify(ensureChangeChar) + " because title is " + JSON.stringify(document.title))
                }
            }

            var _RegisterHandler = function(type, callback) {
                handlers[type] = callback
            }

            var _ReceiveMessage = function(message) {
                if(handlers[message.type]) {
                    handlers[message.type](message)
                }
            }

            return {
                send: _SendMessage,
                register_handler: _RegisterHandler,
                receive: _ReceiveMessage
            }
        })()

        var RPCServer = (function(){
            var rpc_functions = {}

            // internal func to handle incoming RPC messages
            var _RPCHandler = function(message) {
                if(rpc_functions[message.method]) {
                    var resp = {
                        type: "rpc_resp",
                        id: message.id
                    }

                    try {
                        var params = message.params || []

                        resp.result = rpc_functions[message.method](...params)
                    } catch (e) {
                        resp.error = e.toString()
                    }

                    Client.send(resp)
                }
            }
            Client.register_handler("rpc", _RPCHandler)

            var _RegisterRPCFunction = function(name, callback) {
                rpc_functions[name] = callback
            }

            return {
                register: _RegisterRPCFunction
            }
        })()

        RPCServer.register("add", function(a, b){
            return a + b
        })

        var RPCClient = (function(){
            var index = 0
            var pending_requests = {}

            var _RPCRespHandler = function(message) {
                if(pending_requests[message.id]) {
                    if(message.error) {
                        pending_requests[message.id].reject(message.error)
                    } else {
                        pending_requests[message.id].resolve(message.result)
                    }
                    pending_requests[message.id] = null
                }
            }
            Client.register_handler("rpc_resp", _RPCRespHandler)

            var _Call = async function(method, params) {
                index += 1
                var req = {
                    type: "rpc",
                    method: method,
                    id: index
                }

                if(params) {
                    req.params = params
                }

                var result = new Promise((resolve, reject) => {
                    pending_requests[index] = {resolve: resolve, reject: reject}
                })

                Client.send(req)

                return result
            }

            return {
                call: _Call
            }
        })()

        // websocket implementation
        var ws_api = (function(){
            var open_websockets = []
            var socket_index = 0

            var _OnOpen = function(index, e) {
                RPCClient.call("ws_open", [index, {extensions: e.target.extensions, protocol: e.target.protocol}])
            }

            var _OnMessage = function(index, e) {
                RPCClient.call("ws_message", [index, e.data])
            }

            var _OnClose = function(index, e) {
                RPCClient.call("ws_closed", [index, e.code, e.reason, e.wasClean])
                open_websockets[index] = null
            }

            var _OnError = function(index, error) {
                RPCClient.call("ws_error", [index])
            }

            RPCServer.register("ws_create", function(url, protocols){
                var index = socket_index++
                console.log(`creating websocket with index ${index}`)
                var socket = (typeof protocols != "undefined") ? (new WebSocket(url, protocols)) : (new WebSocket(url))

                socket.onopen = _OnOpen.bind(null, index)
                socket.onmessage = _OnMessage.bind(null, index)
                socket.onclose = _OnClose.bind(null, index)
                socket.onerror = _OnError.bind(null, index)

                open_websockets[index] = socket

                return index
            })

            RPCServer.register("ws_send", function(index, data){
                if(open_websockets[index]) {
                    console.log("sending ", data)
                    open_websockets[index].send(data)
                }
            })

            RPCServer.register("ws_close", function(index, code, reason){
                if(open_websockets[index]) {
                    open_websockets[index].close(code, reason)
                }
            })
        })()

        RPCClient.call("browser_ready")
    ]]

    local js_loaded = false

    local function browser_ready(param)
        if param == nil then
            return
        end

        local data = ffi.cast(HTML_BrowserReady_t_ptr, param)

        if data.unBrowserHandle == nil then
            return
        end

        browser_handle = data.unBrowserHandle

        native_ISteamHTMLSurface_LoadURL(browser_handle, "about:blank", "")
    end

    register_callback_steam(CALLBACK_HTML_StartRequest_t, function(param)
        if param == nil then return end

        local data = ffi.cast(HTML_StartRequest_t_ptr, param)

        if data.unBrowserHandle == browser_handle then
            native_ISteamHTMLSurface_AllowStartRequest(browser_handle, true)
        end
    end)

    register_callback_steam(CALLBACK_HTML_JSAlert_t, function(param)
        if param == nil then return end

        local data = ffi.cast(HTML_JSAlert_t_ptr, param)

        if data.unBrowserHandle == browser_handle and data.pchMessage ~= nil then
            local message = ffi.string(data.pchMessage)

            Client.receive(message)
            native_ISteamHTMLSurface_JSDialogResponse(browser_handle, false)
        end
    end)

    register_callback_steam(CALLBACK_HTML_ChangedTitle_t, function(param)
        if param == nil then return end

        local data = ffi.cast(HTML_ChangedTitle_t_ptr, param)

        if data.unBrowserHandle == browser_handle and data.pchTitle ~= nil then
            local message = ffi.string(data.pchTitle)

            if js_loaded then
                message = message:gsub("^about:blank#", "")

                local first_char = message:sub(1, 1)

                if first_char == "t" or first_char == "T" then
                    Client.receive(message:sub(2, -1))
                end
            else
                if message == "about:blank" then
                    native_ISteamHTMLSurface_ExecuteJavascript(browser_handle, js_string)

                    js_loaded = true

                    if browser_ready_callback ~= nil then
                        xpcall(browser_ready_callback, print)
                    end
                end
            end
        end
    end)

    register_callback_steam(CALLBACK_HTML_URLChanged_t, function(param)
        if param == nil then return end

        local data = ffi.cast(HTML_URLChanged_t_ptr, param)

        if data.unBrowserHandle == browser_handle and data.bNewNavigation == false and data.bIsRedirect == false and data.pchURL ~= nil then
            local pchURL = ffi.string(data.pchURL)

            if js_loaded then
                local sub = pchURL:sub(1, 13)

                if sub == "about:blank#h" or sub == "about:blank#H" then
                    Client.receive(pchURL:sub(14, -1))
                end
            end
        end
    end)

    local call_handle = native_ISteamHTMLSurface_CreateBrowser(nil, nil)
    register_call_result(call_handle, browser_ready, CALLBACK_HTML_BrowserReady_t)

    cbs.critical("unload", function()
        if browser_handle ~= nil then
            native_ISteamHTMLSurface_RemoveBrowser(browser_handle)
            browser_handle = nil
        end
    end)
end

local open_websockets, open_websockets_data = {}, setmetatable({}, { __mode = "k" })

local function ws_rpc_callback(self, err)
    if err ~= nil then
        local ws_data = open_websockets_data[self]

        if ws_data ~= nil and ws_data.callback_error ~= nil then
            xpcall(ws_data.callback_error, print, self, err)
        end
    end
end

local websocket_mt = {
    __metatable = false
}
---@class websocket_t
websocket_mt.__index = {
    ---@param self websocket_t
    ---@param code number
    ---@param reason string
    close = function(self, code, reason)
        local ws_data = open_websockets_data[self]

        if ws_data == nil then return end   -- invalid websocket
        if not ws_data.open then return end -- websocket not open

        RPCClient.call("ws_close", func_bind(ws_rpc_callback, self), ws_data.index, code, reason)
    end,
    ---@param self websocket_t
    ---@param data any
    send = function(self, data)
        local ws_data = open_websockets_data[self]

        if ws_data == nil then return end   -- invalid websocket
        if not ws_data.open then return end -- websocket not open

        RPCClient.call("ws_send", func_bind(ws_rpc_callback, self), ws_data.index, tostring(data))
    end
}

RPCServer.register("ws_open", function(index, event)
    local ws = open_websockets[index]
    local ws_data = open_websockets_data[ws]

    if ws_data ~= nil then
        ws.open = true
        ws_data.open = true

        ws.protocol = event.protocol
        ws.extensions = event.extensions

        if ws_data.callback_open ~= nil then
            xpcall(ws_data.callback_open, print, ws)
        end
    end
end)

RPCServer.register("ws_message", function(index, data)
    local ws = open_websockets[index]
    local ws_data = open_websockets_data[ws]

    if ws_data ~= nil then
        if ws_data.callback_message ~= nil then
            xpcall(ws_data.callback_message, print, ws, data)
        end
    end
end)

RPCServer.register("ws_closed", function(index, code, reason, was_clean)
    local ws = open_websockets[index]
    local ws_data = open_websockets_data[ws]

    if ws_data ~= nil then
        ws.open = false
        ws_data.open = false
        if ws_data.callback_close ~= nil then
            xpcall(ws_data.callback_close, print, ws, code, reason, was_clean)
        end

        open_websockets[index] = nil
        open_websockets_data[ws] = nil
    end
end)

RPCServer.register("ws_error", function(index)
    local ws = open_websockets[index]
    local ws_data = open_websockets_data[ws]

    if ws_data ~= nil then
        if ws_data.callback_error ~= nil then
            xpcall(ws_data.callback_error, print, ws)
        end
    end
end)

local browser_ready_state, pending_websockets = 0, {}

local function create_websocket_impl(websocket, url, protocols, callbacks)
    local callback_error = callbacks.error

    open_websockets_data[websocket] = {
        open = false,
        callback_open = callbacks.open,
        callback_error = callback_error,
        callback_message = callbacks.message,
        callback_close = callbacks.close
    }

    RPCClient.call("ws_create", function(err, index)
        if err then
            if callback_error ~= nil then
                xpcall(callback_error, print, websocket, err)
            end

            open_websockets_data[websocket] = nil

            return
        end

        open_websockets[index] = websocket
        open_websockets_data[websocket].index = index
    end, url, protocols)
end

---@alias __websocket_callback fun(self: websocket_t, data: any)
---@alias __websocket_callback_table { open?: __websocket_callback, error?: __websocket_callback, message?: __websocket_callback, close?: __websocket_callback }
---@param url string
---@param options { protocols?: string[]|string }|__websocket_callback_table
---@param callbacks? __websocket_callback_table
---@return websocket_t?
local function create_websocket(url, options, callbacks)
    if callbacks == nil then
        callbacks = options
        options = nil
    end

    if type(url) ~= "string" then
        return error("Invalid url, has to be a string")
    end

    if type(callbacks) ~= "table" then
        return error("Invalid callbacks, has to be a table")
    elseif callbacks.open == nil or type(callbacks.open) ~= "function" then
        return error("Invalid callbacks, open callback has to be registered")
    elseif callbacks.open == nil and callbacks.error == nil and callbacks.message == nil and callbacks.close == nil then
        return error("Invalid callbacks, at least one callback has to be registered")
    elseif (callbacks.error ~= nil and type(callbacks.error) ~= "function") or (callbacks.message ~= nil and type(callbacks.message) ~= "function") or (callbacks.close ~= nil and type(callbacks.close) ~= "function") then
        return error("Invalid callbacks, all callbacks have to be functions")
    end

    local protocols

    if type(options) == "table" then
        if type(options.protocols) == "string" then
            protocols = options.protocols
        elseif type(options.protocols) == "table" and #options.protocols > 0 then
            for i = 1, #options.protocols do
                if type(options.protocols[i]) ~= "string" then
                    return error("Invalid options.protocols, has to be an array of strings")
                end
            end
            protocols = options.protocols
        elseif options.protocols ~= nil then
            return error("Invalid options.protocols, has to be a string or array")
        end
    elseif options ~= nil then
        return error("Invalid options, has to be a table")
    end

    if browser_ready_state == 0 then
        browser_ready_state = 1

        setup_browser(function()
            browser_ready_state = 2

            for i = 1, #pending_websockets do
                local pending_websocket = pending_websockets[i]
                xpcall(create_websocket_impl, print, pending_websocket.websocket, pending_websocket.url, pending_websocket.protocols, pending_websocket.callbacks)
            end
            pending_websockets = nil
        end)
    end

    local websocket = setmetatable({
        url = url,
        open = false
    }, websocket_mt)

    if browser_ready_state ~= 2 then
        table.insert(pending_websockets, { websocket = websocket, url = url, protocols = protocols, callbacks = callbacks })
    else
        create_websocket_impl(websocket, url, protocols, callbacks)
    end

    return websocket
end

return {
    connect = create_websocket
}