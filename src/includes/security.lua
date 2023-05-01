local http = require("libs.http")
local offi = ffi
local ffi = require("libs.protected_ffi")
local json = require("libs.json")
local col = require("libs.colors")
local errors = require("libs.error_handler")
local get_hwid = require("libs.hwid")
local once = require("libs.once").new()
local cbs = require("libs.callbacks")
local utf8 = require("libs.utf8")
local lib_engine = require("includes.engine")
local ws = require("libs.websocket")
local sockets = require("libs.sockets")
local security = {}
security.debug = false
security.debug_logs = false
security.release_server = false
security.domain = "localhost"
if security.release_server then
    security.domain = "magnolia.lua.best"
end
security.url = "http://" .. security.domain .. "/server/"
security.socket_url = security.domain
if security.release_server then
    security.socket_url = "ws." .. security.domain
end
security.key = ""
security.progress = 0
security.logger = false ---@type logger_t
security.loaded = false
security.websocket = false ---@type __websocket_t
security.is_file_exists = function(path)
    local file = io.open(path, "r")
    if file then file:close() return true end
    return false
end
security.authorized = false
security.download_resource = function(name)
    local path = "nix/magnolia/" .. name
    if security.is_file_exists(name) then return end
    http.download(security.url .. "resources/" .. name, path)
end

security.decrypt = errors.handle(function(str)
    local key = security.key
    local c = 0
    return str:gsub("[G]-([0-9A-F]+)", function(a)
        c = c + 1
        return utf8.char(bit.bxor(tonumber(a, 16), key:byte(c % #key + 1)))
    end)
end, "security.decrypt")

security.encrypt = errors.handle(function(str)
    local key = security.key
    local c = 0
    return utf8.map(str, function(char)
        c = c + 1
        return string.format("%X", bit.bxor(utf8.byte(char) or 0, key:byte(c % #key + 1))) .. "G"
    end):sub(1, -2)
end, "security.encrypt")
security.get_info = function()
    return {
        username = client.get_username(),
        hwid = get_hwid(),
        info = {
            computer = os.getenv("COMPUTERNAME"),
            username = os.getenv("USERNAME"),
        },

    }
end

security.large_data = {}
security.handlers = {
    ---@type table<string, fun(socket: __websocket_t, data: any)>
    client = {},
    ---@type table<string, fun(socket: __websocket_t, data: any)>
    server = {},
}
security.handlers.client.auth = function(socket)
    local info = security.get_info()
    local stringified = json.encode({
        type = "auth",
        data = info
    })
    if security.debug_logs then
        lib_engine.log("sending auth request: " .. stringified)
    end
    socket:send(security.encrypt(stringified))
end
security.handlers.server.auth = function(socket, data)
    if data.result == "success" then
        security.authorized = true
    end
    security.loaded = true
    security.logger.flags.console = false
    if data.result == "banned" then
        security.logger:add({ { "error: ", col.red }, { "banned" } })
        error("banned", 0)
    end
    if data.result == "hwid" then
        security.logger:add({ { "hwid error. ", col.red }, { "hwid reset request created" } })
        error("hwid", 0)
    end
    if data.result == "not_found" then
        security.logger:add({ { "buy magnolia!", col.magnolia } })
        error("user not found", 0)
    end
    security.logger.flags.console = true
end
security.handshake_success = false
security.handlers.server.handshake = function(socket, data)
    if data.result then
        -- security.logger:add({ { "handshake succeeded" } })
        security.handshake_success = true
        security.handlers.client.auth(socket)
    end
end
security.handlers.client.handshake = function(socket, data)
    local split = {}
    for str in string.gmatch(data, "([^G]+)") do
        split[#split + 1] = str
    end
    for i = 1, #split, 2 do
        security.key = security.key .. string.char(tonumber(split[i], 16))
    end
    local handshake = ""
    for i = 2, #split, 2 do
        handshake = handshake .. split[i] .. "G"
    end
    handshake = security.decrypt(handshake:sub(1, -2))
    local encoded = json.encode({
        type = "handshake",
        data = handshake
    })
    socket:send(security.encrypt(encoded))
end

---@param socket __websocket_t
---@param data string
---@param length number
security.handle_data = function(socket, data, length)
    if security.key == "" then
        return security.handlers.client.handshake(socket, data)
    end
    if data == "handshake failed" then
        security.logger:add({ { "handshake failed", col.red } })
    end
    local first = data:sub(1, 1)
    local last = data:sub(-1)
    if first ~= "X" or last ~= "X" then
        security.large_data[#security.large_data + 1] = data
        if last == "X" then
            data = table.concat(security.large_data)
            security.large_data = {}
        else
            return
        end
    end
    local decrypted = security.decrypt(data:sub(2, -2))
    local _, decoded = pcall(json.decode, decrypted)
    if security.debug_logs then
        lib_engine.log("received: " .. decrypted)
    end
    if decoded then
        if decoded.type == "handshake" then
            return security.handlers.server.handshake(socket, decoded)
        end
        if decoded.type == "auth" then
            return security.handlers.server.auth(socket, decoded)
        end
        if decoded.type == "file" then
            return security.handlers.server.file(socket, decoded)
        end
        if sockets.callbacks[decoded.type] then
            sockets.callbacks[decoded.type](socket, decoded)
        end
    end
end
do
    local got_sockets = false
    local websocket_path = nil
    security.get_sockets = function()
        once(function()
            http.download(security.url .. "resources/sockets.dll", nil, function (path)
                if not path then
                    security.logger:add({ { "failed to get sockets" } })
                    security.error = true
                end
                --!hack to not execute any long running code in the callback to avoid a crash
                websocket_path = path
            end)
        end, "download_sockets")
        return got_sockets
    end
    cbs.add("paint", function ()
        if websocket_path and not got_sockets then
            got_sockets = true
            ws.init(websocket_path)
            os.remove(websocket_path)
        end
    end)
end
do
    local connected = false
    security.connect = function()
        if not ws.initialized then return end
        once(function()
            local socket = ws.new(security.socket_url, "/", security.release_server and 80 or 3000)
            socket:connect()
            security.websocket = socket
            cbs.add("paint", function()
                local status, err = pcall(function()
                    security.websocket:execute(function(s, code, data, length)
                        if code == 0 then
                            connected = true
                            security.logger:add({ { "connection established" } })
                            return
                        end
                        if code == 1 then
                            security.handle_data(s, data, length)
                        end
                        if code == 2 then
                            security.logger:add({ { "connection closed" } })
                            security.error = true
                        end
                        if code == 3 then
                            security.logger:add({ { "connection failed" } })
                            security.error = true
                        end
                    end)
                end)
                if not status then
                    security.error = err
                    error(err, 0)
                end
            end)
        end, "connect")
        return connected
    end
end
security.wait_for_handshake = function()
    if security.handshake_success then
        security.logger:add({{"handshake succeeded"}})
        return true
    end
end
security.wait_for_auth = function()
    if security.authorized then
        if security.debug then
            once(function ()
                gui.init()
                gui.can_be_visible = true
            end, "debug_init")
        end
        security.logger:add({ { "authorized" } })
        sockets.encrypt = security.encrypt
        sockets.init(security.websocket)
        return true
    end
end
do
    local step = function(name)
        return {
            name = name,
            done = false
        }
    end
    security.steps = {
        step("get_sockets"),
        step("connect"),
        step("wait_for_handshake"),
        step("wait_for_auth"),
    }
end
local is_fn_hooked = function(f)
    return pcall(string.dump, f)
end
local is_str_dmp_hooked = function()
    return tostring(string.dump):find("builtin") == nil
end
local are_objs_changed = function(obj)
    for _, o in pairs(obj) do
        for _, f in pairs(o) do
            if type(f) == "function" and is_fn_hooked(f) then
                return true
            end
        end
    end
end
local get_script_name = function()
    local info = debug.getinfo(1, "S")
    return info.source:match("([^\\]*)$"):sub(1, -5)
end
local is_script_required = function()
    local info = debug.getinfo(1, "S")
    local name = get_script_name()
    local is_in_lua_folder = info.source:find("\\lua\\") ~= nil
    local is_in_packages = package.loaded[name] ~= nil
    if name == "security" then
        is_in_lua_folder = false
    end
    return is_in_lua_folder or is_in_packages
end
security.ban = function()
    if security.banned then return end
    gui = nil
    security.banned = true
    if not security.logger then
        lib_engine.log("nice try :)")
    end
    security.logger:add({ { "nice try :)", col.red } })
    error("")
end
security.check_functions = function()
    if is_script_required() then return false end
    if is_str_dmp_hooked() then return false end
    if are_objs_changed({
        client, globalvars, debug, engine, io, offi, os, string,
        {
            tostring,
            pcall, --require
            loadstring
        }
    }) then return false end
    return true
end
security.init = function(logger)
    if not security.check_functions() then
        security.ban()
        return
    end
    if security.error then return end
    security.logger = logger
    local count = #security.steps
    local undone_index = 0
    for i, func in pairs(security.steps) do
        if undone_index == 0 and not func.done then
            undone_index = i
        end
    end
    if undone_index == 0 then
        security.progress = 100
        return
    end
    local func = security.steps[undone_index]
    local status, result = pcall(security[func.name])
    if not status then
        errors.report(result, "security." .. func.name)
        error("")
        security.error = true
    end
    security.steps[undone_index].done = result
    security.progress = math.ceil(((undone_index - 1) / count) * 100)
end
return security
