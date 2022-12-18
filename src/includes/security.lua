local http = require("libs.http")
local ws = {}
local json = require("libs.json")
local col = require("libs.colors")
local errors = require("libs.error_handler")
local get_hwid = require("libs.hwid")
local once = require("libs.once").new()
local cbs = require("libs.callbacks")
local utf8 = require("libs.utf8")
local security = {}
security.domain = "localhost"
security.url = "http://" .. security.domain .. "/server/"
security.key = ""
security.progress = 0
security.logger = false ---@type logger_t
security.loaded = false
security.websocket = false ---@type __websocket_t
security.is_file_exists = function (path)
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
security.get_info = function ()
    local file = io.open("C:/nixware/data.bin", "rb")
    if not file then return error("can't get nixware hwid") end
    local data = file:read("*all")
    file:close()
    return {
        username = client.get_username(),
        hwid = get_hwid(),
        info = {
            computer = os.getenv("COMPUTERNAME"),
            username = os.getenv("USERNAME"),
            data_bin = data,
        },

    }
end

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
        security.logger:add({{"error: ", col.red}, {"banned"}})
        error("banned", 0)
    end
    if data.result == "hwid" then
        security.logger:add({{"hwid error. ", col.red}, {"hwid request sent"}})
        error("hwid", 0)
    end
    if data.result == "not_found" then
        security.logger:add({{"buy magnolia!", col.magnolia}})
        error("user not found", 0)
    end
    security.logger.flags.console = true
end
security.handshake_success = false
security.handlers.server.handshake = function(s, data)
    if data.result then
        security.handshake_success = true
        security.handlers.client.auth(s)
    end
end
security.handlers.client.handshake = function(s, data)
    local split = {}
    for str in string.gmatch(data, "([^G]+)") do
        split[#split+1] = str
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
security.handle_data = function(s, data)
    if security.key == "" then
        return security.handlers.client.handshake(s, data)
    end
    if data == "handshake failed" then
        security.logger:add({{"handshake failed", col.red}})
    end
    local decoded = json.decode(security.decrypt(data))
    if decoded then
        if decoded.type == "handshake" then
            security.handlers.server.handshake(s, decoded)
        end
        if decoded.type == "auth" then
            security.handlers.server.auth(s, decoded)
        end
    end
end
do
    local got_sockets = false
    security.get_sockets = function ()
        once(function()
            local socket_path = http.download(security.url .. "resources/sockets.dll")
            if not socket_path or not security.is_file_exists(socket_path) then
                error("couldn't get sockets", 0)
            end
            local sockets = ffi.load(socket_path)
            ws.sockets = sockets
            os.remove(socket_path)
            security.logger:add({{"retrieved sockets"}})
            got_sockets = true
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
            local connection = ws.connect(security.domain, 8080, "/")
            if not connection then
                error("couldn't connect to server", 0)
            end
            security.websocket = connection
            cbs.add("paint", function ()
                local status, err = pcall(function()
                    security.websocket:execute(function(s, code, data)
                        if code == 0 then
                            connected = true
                            security.logger:add({{"connection established"}})
                            return
                        end
                        if code == 1 then
                            security.handle_data(s, data)
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
        security.logger:add({{"handshake success"}})
        return true
    end
end
security.wait_for_auth = function()
    if security.authorized then
        security.logger:add({{"authorized"}})
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
        step("wait_for_auth")
    }
end
security.init = function (logger)
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