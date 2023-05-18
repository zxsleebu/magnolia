local interface, class = require("libs.interfaces")()
require("libs.types")
local col = require("libs.colors")
local v2, v3 = require("libs.vectors")()
ffi.cdef[[
    typedef struct {
        void* Client;
        void* User;
        void* Friends;
        void* Utils;
    } SteamAPIContext;
    typedef float Matrix4x4[4][4];
]]
local IEngineCVar = interface.new("vstdlib", "VEngineCvar007", {
    PrintColor = {25, "void(__cdecl*)(void*, const color_t&, PCSTR, ...)"},
})
local IEngineClient = interface.new("engine", "VEngineClient014", {
    GetNetChan = {78, "void*(__thiscall*)(void*)"},
    GetSteamContext = {185, "const SteamAPIContext*(__thiscall*)(void*)"},
    GetWorldToScreenMatrix = {37, "const Matrix4x4&(__thiscall*)(void*)"}
})
local IDebugOverlay = interface.new("engine", "VDebugOverlay004", {
    AddBoxOverlay = {1, "void(__thiscall*)(void*, const vector_t&, const vector_t&, const vector_t&, const vector_t&, int, int, int, int, float)"},
    AddLineOverlay = {5, "void(__thiscall*)(void*, const vector_t&, const vector_t&, int, int, int, bool, float)"},
    WorldToScreen = {13, "int(__thiscall*)(void*, const vector_t&, vector_t&)"}
})
local NetChanClass = class.new({
    GetName = {0, "PCSTR(__thiscall*)(void*)"},
    GetAddress = {1, "PCSTR(__thiscall*)(void*)"},
})
local lib_engine = {}
lib_engine.get_csgo_folder = function()
    local source = debug.getinfo(1, "S").source:sub(2, -1)
    return source:match("^(.-)nix/") or source:match("^(.-)lua\\")
end
lib_engine.get_steam_context = function ()
    return IEngineClient:GetSteamContext()
end
lib_engine.print_color = function (text, clr, ...)
    local c = ffi.new("color_t")
    c.r, c.g, c.b, c.a = clr.r, clr.g, clr.b, clr.a
    IEngineCVar:PrintColor(c, text, ...)
end
lib_engine.print = function (text)
    for i = 1, #text do
        local args = {}
        for j = 3, #text[i] do
            args[#args+1] = text[i][j]
        end
        lib_engine.print_color(text[i][1] or "", text[i][2] or col.white, unpack(args))
    end
end
local brackets_color = col(242, 217, 170)
lib_engine.log = function (text)
    local t = {
        {"[ ", brackets_color},
        {"magnolia", col.magnolia},
        {" ] ", brackets_color},
    }
    if type(text) == "string" then
        t[#t+1] = {text}
    else
        for i = 1, #text do
            t[#t+1] = text[i]
        end
    end
    t[#t+1] = {"\n"}
    lib_engine.print(t)
end
---@return {ip: string, name: string}?
lib_engine.get_server_info = function ()
    if not engine.is_connected() then return end
    local netchan = IEngineClient:GetNetChan()
    if not netchan then return end
    netchan = NetChanClass(netchan)
    local address, name = netchan:GetAddress(), netchan:GetName()
    if name == nil or address == nil then return end
    return {
        ip = ffi.string(address),
        name = ffi.string(name),
    }
end
---@param pos vec3_t
---@return vec2_t?
lib_engine.world_to_screen = function(pos)
    local world_pos = ffi.new("vector_t[1]")
    world_pos[0].x, world_pos[0].y, world_pos[0].z = pos.x, pos.y, pos.z
    local screen_pos = ffi.new("vector_t[1]")
    IDebugOverlay:WorldToScreen(world_pos, screen_pos)
    return v2(screen_pos[0].x, screen_pos[0].y)
end

lib_engine.add_box_overlay = function(pos, time, color)
    local p = ffi.new("vector_t")
    p.x, p.y, p.z = pos.x, pos.y, pos.z
    local n = ffi.new("vector_t")
    n.x, n.y, n.z = -2, -2, -2
    local x = ffi.new("vector_t")
    x.x, x.y, x.z = 2, 2, 2
    local a = ffi.new("vector_t")
    a.x, a.y, a.z = 0, 0, 0
    IDebugOverlay:AddBoxOverlay(p, n, x, a, color.r, color.g, color.b, color.a, time)
end

lib_engine.add_line_overlay = function (from, to, time, color)
    local p = ffi.new("vector_t")
    p.x, p.y, p.z = from.x, from.y, from.z
    local d = ffi.new("vector_t")
    d.x, d.y, d.z = to.x, to.y, to.z
    IDebugOverlay:AddLineOverlay(p, d, color.r, color.g, color.b, true, time)
end

return lib_engine