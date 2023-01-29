local http = require("libs.http")
local offi = ffi
local ffi = require("libs.protected_ffi")
local threads = require("libs.threads")
local ws = {}
local json = require("libs.json")
local col = require("libs.colors")
local errors = require("libs.error_handler")
local get_hwid = require("libs.hwid")
local once = require("libs.once").new()
local cbs = require("libs.callbacks")
local utf8 = require("libs.utf8")
local lib_engine = require("includes.engine")
local security = {}
security.debug = true
security.release_server = true
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

security.decrypt = function(str)
    local key = security.key
    local c = 0
    return str:gsub("[G]-([0-9A-F]+)", function(a)
        c = c + 1
        return utf8.char(bit.bxor(tonumber(a, 16), key:byte(c % #key + 1)))
    end)
end

security.encrypt = function(str)
    local key = security.key
    local c = 0
    return utf8.map(str, function(char)
        c = c + 1
        return string.format("%X", bit.bxor(utf8.byte(char) or 0, key:byte(c % #key + 1))) .. "G"
    end):sub(1, -2)
end
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
    client = {},
    server = {},
}
security.handlers.client.auth = function(s)
    local info = security.get_info()
    s:send(security.encrypt(json.encode({
        type = "auth",
        data = info
    })))
end
security.handlers.server.auth = function(_, data)
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
        security.logger:add({ { "hwid error. ", col.red }, { "hwid request sent" } })
        error("hwid", 0)
    end
    if data.result == "not_found" then
        security.logger:add({ { "buy magnolia!", col.magnolia } })
        error("user not found", 0)
    end
    security.logger.flags.console = true
end
security.handshake_success = false
security.handlers.server.handshake = function(s, data)
    if data.result then
        security.logger:add({ { "handshake succeeded" } })
        security.handshake_success = true
        security.handlers.client.auth(s)
    end
end
security.handlers.client.handshake = function(s, data)
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
    local encrypted = security.encrypt(encoded)
    s:send(encrypted)
end

---@param s __websocket_t
---@param data string
---@param length number
security.handle_data = function(s, data, length)
    if security.key == "" then
        return security.handlers.client.handshake(s, data)
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
    lib_engine.log("received: " .. decrypted)
    if decoded then
        if decoded.type == "handshake" then
            security.handlers.server.handshake(s, decoded)
        end
        if decoded.type == "auth" then
            security.handlers.server.auth(s, decoded)
        end
        if decoded.type == "file" then
            security.handlers.server.file(s, decoded)
        end
    end
end
do
    local got_sockets = false
    security.get_sockets = function()
        once(function()
            -- threads.new(function ()
                http.download(security.url .. "resources/sockets.dll", nil, function (path)
                    local sockets = ffi.load(path)
                    ws.sockets = sockets
                    os.remove(path)
                    security.logger:add({ { "retrieved sockets" } })
                    got_sockets = true
                end)
            -- end)
        end, "download_sockets")
        return got_sockets
    end
end
do
    local connected = false
    security.connect = function()
        once(function()
            jit.off()
            collectgarbage("stop")
            local sockets = ws.sockets
            ws = require("libs.websockets")
            ws.sockets = sockets
            local connection = ws.connect(security.socket_url, security.release_server and 80 or 3000, "/")
            if not connection then
                error("couldn't connect to server", 0)
            end
            security.websocket = connection
            cbs.add("paint", function()
                local status, err = pcall(function()
                    security.websocket:execute(function(s, code, data, length)
                        -- if security.debug then
                        lib_engine.log("code: " .. code .. " data: " .. data .. " length: " .. length)
                        -- end
                        if code == 0 then
                            connected = true
                            security.logger:add({ { "connection established" } })
                            return
                        end
                        if code == 1 then
                            security.handle_data(s, data, length)
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
        -- security.logger:add({{"handshake succeeded"}})
        return true
    end
end
security.wait_for_auth = function()
    if security.authorized then
        security.logger:add({ { "authorized" } })
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
                -- print(o_name .. "." .. f_name .. " is hooked")
                return true
            end
        end
    end
end
security.ban = function()
    if not security.logger then
        error("nice try :)")
    end
    security.logger:add({ { "nice try :)", col.red } })
    error("")
end
security.check_functions = function()
    if is_str_dmp_hooked() then return false end
    if are_objs_changed({
        client, globalvars, debug, engine, io, offi, os,
        {
            tostring,
            string.find,
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
