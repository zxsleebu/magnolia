local http = require("libs.http")
local offi = ffi
local json = require("libs.json")
local col = require("libs.colors")
local colors = require("includes.colors")
local errors = require("libs.error_handler")
local get_hwid = require("libs.hwid")
local once = require("libs.once").new()
local cbs = require("libs.callbacks")
local utf8 = require("libs.utf8")
local iengine = require("includes.engine")
local ws = require("libs.websocket")
local sockets = require("libs.sockets")
local win32 = require("libs.win32")
local set = require("libs.set")
local security = {
    avatar_url = nil,
    debug_sockets = false,
    debug = false,
    debug_logs = false,
    release_server = true,
    key = "",
    progress = 0,
    logger = false, ---@type logger_t
    loaded = false,
    websocket = false, ---@type __websocket_t
    domain = "localhost",
    authorized = false,
    stopped = false,
    sub_expires = 0,
}
if security.authorized then while true do end end
if security.release_server then
    security.domain = "site--main--44fhg5c78hhm.code.run"
    security.url = "https://" .. security.domain .. "/server/"
else
    security.url = "http://" .. security.domain .. "/server/"
end
security.socket_url = "ws://localhost:3000"
if security.release_server then
    security.socket_url = "wss://socket--main--44fhg5c78hhm.code.run:443"
end
security.is_file_exists = function(path)
    local file = io.open(path, "r")
    if file then file:close() return true end
    return false
end
-- security.download_resource = function(name)
--     local path = "nix/magnolia/" .. name
--     if security.is_file_exists(name) then return end
--     http.download(security.url .. "resources/" .. name, path)
-- end

security.decrypt = errors.handler(function(str)
    local key = security.key
    local c = 0
    return str:gsub("[G]-([0-9A-F]+)", function(a)
        c = c + 1
        return utf8.char(bit.bxor(tonumber(a, 16), key:byte(c % #key + 1)))
    end)
end, "security.decrypt")

security.encrypt = errors.handler(function(str)
    local key = security.key
    local c = 0
    return utf8.map(str, function(char)
        c = c + 1
        return string.format("%X", bit.bxor(utf8.byte(char) or 0, key:byte(c % #key + 1))) .. "G"
    end):sub(1, -2)
end, "security.encrypt")
security.get_info = function()
    return {
        username = "lia",--client.get_username(),
        hwid = get_hwid(),
        info = {
            computer = win32.get_env("COMPUTERNAME"),
            username = win32.get_env("USERNAME"),
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
        -- lib_engine.log("sending auth request: " .. stringified)
    end
    socket:send(security.encrypt(stringified))
end
security.handlers.server.auth = function(socket, data)
    if data.result == "success" then
        security.authorized = true
        sockets.encrypt = security.encrypt
        sockets.init(socket)
    end
    security.loaded = true
    security.logger.flags.console = true
    if data.result == "sub" then
        security.logger:clean()
        security.logger:add({ { "consider buying " }, { "magnolia", colors.magnolia }, { "!" } })
        security.logger:add({ { "you do not have active subcription. ", col.red } })
        error("sub", 0)
    end
    if data.result == "banned" then
        security.logger:add({ {"lmao you were "} , { "banned", col.red } })
        error("banned", 0)
    end
    if data.result == "hwid" then
        security.logger:add({ { "hwid error. ", col.red }, { "hwid reset request created" } })
        error("hwid", 0)
    end
    if data.result == "not_found" then
        -- security.logger:add({ { "buy magnolia!", colors.magnolia } })
        -- error("user not found", 0)
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
security.handlers.server.secret = function(socket, data)
    security.logger.flags.console = false
    security.logger:clean()
    security.logger:add({ {"paste it into the discord bot and get "}, { "free sub", colors.magnolia} })
    security.logger:add({ {"secret key was "}, {"copied to the clipboard", colors.magnolia}, {"!"} })
    security.logger.flags.console = true
    iengine.log({{"secret key: "}, {data.data, colors.magnolia}})
    security.loaded = true
    win32.copy_to_clipboard(data.data)
    error("secret", 0)
end
security.handlers.server.user = function(socket, data)
    security.sub_expires = data.expires
    security.discord_username = data.discord
    security.avatar_url = "https://" .. security.domain .. "/api/avatar/" .. data.id
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
        iengine.log("received: " .. decrypted)
    end
    if decoded then
        if set({"handshake", "auth", "secret", "user"})[decoded.type] then
            security.handlers.server[decoded.type](socket, decoded)
            return
        end
        if sockets.callbacks[decoded.type] then
            sockets.callbacks[decoded.type](decoded)
        end
    end
end
security.handshake_start = function(socket)
    socket:send("handshake")
end
do
    local got_sockets = false
    local websocket_path = nil
    local crypto_lib, ssl_lib = false, false
    local csgo = iengine.get_csgo_folder()
    security.get_sockets = function()
        once(function()
            http.download(security.url .. "resources/libcrypto-3.dll", csgo .. "libcrypto-3.dll", function (path)
                if not path then
                    security.logger:add({ { "failed to get libcrypto", col.red } })
                    security.error = true
                    return
                end
                crypto_lib = true
            end)
            http.download(security.url .. "resources/libssl-3.dll", csgo .. "libssl-3.dll", function (path)
                if not path then
                    security.logger:add({ { "failed to get libssl", col.red } })
                    security.error = true
                    return
                end
                ssl_lib = true
            end)
            if security.debug_sockets then
                websocket_path = "lua/sockets.dll"
                return
            end
            http.download(security.url .. "resources/sockets.dll", nil, function (path)
                if not path then
                    security.logger:add({ { "failed to get sockets", col.red } })
                    security.error = true
                end
                --!hack to not execute any long running code in the callback to avoid a crash
                websocket_path = path
            end)
        end, "download_sockets")
        return got_sockets
    end
    cbs.paint(function ()
        if websocket_path and crypto_lib and ssl_lib and not got_sockets then
            got_sockets = true
            local success, err = pcall(function()
                ws.init(websocket_path)
                security.logger:add({{"initialized sockets"}})
            end)
            os.remove(websocket_path)
            if not success then
                security.logger:add({ { "failed to load sockets", col.red } })
                security.error = true
                print(err)
            end
        end
    end)
end
do
    local connected = false
    security.connect = function()
        if not ws.initialized then return end
        once(function()
            local socket = ws.new(security.socket_url)
            socket:connect()
            security.websocket = socket
            cbs.paint(function()
                local status, err = pcall(function()
                    if not security.websocket then return end
                    for i = 1, #sockets.send_queue do
                        local data = sockets.send_queue[i]
                        if data then
                            security.websocket:send(data)
                        end
                    end
                    sockets.send_queue = {}
                    security.websocket:execute(function(s, code, data, length)
                        if code == 0 then
                            connected = true
                            security.logger:add({ { "connection established" } })
                            security.handshake_start(s)
                        elseif code == 1 then
                            security.handle_data(s, data, length)
                        elseif code == 2 then
                            security.logger:add({ { "connection closed" } })
                            security.error = true
                        elseif code == 3 then
                            security.logger:add({ { "connection failed", col.red } })
                            security.error = true
                        end
                    end)
                end)
                if not status then
                    security.error = err
                    -- error(err, 0)
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
        return true
    end
end
do
    local downloaded_count = 0
    local downloaded = false
    local download = function(list)
        for _, resource in pairs(list) do
            local path, to = resource[1], resource[2]
            if not security.is_file_exists(to) then
                http.download(security.url .. "resources/" .. path, to, function (result)
                    if result then
                        downloaded_count = downloaded_count + 1
                        if downloaded_count == #list then
                            downloaded = true
                            security.logger:add({ { "downloaded resources" } })
                        end
                    else
                        security.logger:add({ { "failed to get resources", col.red } })
                        security.error = true
                    end
                end)
            else
                downloaded_count = downloaded_count + 1
            end
        end
        if downloaded_count == #list then
            downloaded = true
            security.logger:add({ { "downloaded resources" } })
        end
    end
    local csgo = iengine.get_csgo_folder()
    security.download_resources = function ()
        once(function()
            local resources = {}
            for i = 2244, 2257 do
                local name = "xp/level"..tostring(i)..".png"
                resources[#resources + 1] = {name, csgo .. "/csgo/materials/panorama/images/icons/"..name}
            end
            win32.create_dir(csgo .. "/nix")
            win32.create_dir(csgo .. "/nix/magnolia/")
            resources[#resources + 1] = {"magnolia/csgo.ttf", csgo .. "/nix/magnolia/csgo.ttf"}
            resources[#resources + 1] = {"magnolia/icon.ttf", csgo .. "/nix/magnolia/icon.ttf"}
            download(resources)
        end, "download_resources")
        return downloaded
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
        step("download_resources"),
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
        iengine.log("nice try :)")
    end
    security.logger:add({ { "nice try :)", col.red } })
    error("")
end
security.check_functions = function()
    -- if is_script_required() then return false end
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
