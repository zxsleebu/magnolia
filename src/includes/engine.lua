local interface, class = require("libs.interfaces")()
require("libs.types")
local col = require("libs.colors")
local colors = require("includes.colors")
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
-- local IEngineCVar = interface.new("vstdlib", "VEngineCvar007", {
--     PrintColor = {25, "void(__cdecl*)(void*, const color_t&, PCSTR, ...)"},
-- })
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
    SendNetMsg = {40, "bool(__thiscall*)(void*, void*, bool, bool)"}
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
    print(string.format(text .. "\0", ...), clr)
    -- IEngineCVar:PrintColor(c, text, ...)
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
        {"magnolia", colors.magnolia},
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
lib_engine.get_net_chan = function()
    if not globals.is_connected then return end
    local netchan = IEngineClient:GetNetChan()
    if not netchan then return end
    netchan = NetChanClass(netchan)
    return netchan
end
---@return {ip: string, name: string}?
lib_engine.get_server_info = function ()
    if not globals.is_connected then return end
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
lib_engine.send_net_msg = function(msg)
    local netchan = lib_engine.get_net_chan()
    if not netchan then return end
    netchan:SendNetMsg(msg, false, true)
end
---@param pos vec3_t
---@return vec2_t?
lib_engine.world_to_screen = function(pos)
    local world_pos = ffi.new("vector_t[1]", pos:C())
    local screen_pos = ffi.new("vector_t[1]")
    IDebugOverlay:WorldToScreen(world_pos, screen_pos)
    return v2(screen_pos[0])
end

---@param pos vec3_t
---@param time number
---@param color color_t
lib_engine.add_box_overlay = function(pos, time, color)
    IDebugOverlay:AddBoxOverlay(pos:C(), v3(-2, -2, -2):C(), v3(2, 2, 2):C(), v3(0, 0, 0):C(), color.r, color.g, color.b, color.a, time)
end

---@param from vec3_t
---@param to vec3_t
---@param time number
---@param color color_t
lib_engine.add_line_overlay = function (from, to, time, color)
    IDebugOverlay:AddLineOverlay(from:C(), to:C(), color.r, color.g, color.b, true, time)
end
lib_engine.hitgroups = {
    generic = 0,
    head = 1,
    chest = 2,
    stomach = 3,
    left_arm = 4,
    right_arm = 5,
    left_leg = 6,
    right_leg = 7,
    gear = 8
}
lib_engine.hitboxes = {
    head = 0,
    neck = 1,
    pelvis = 2,
    belly = 3,
    thorax = 4,
    lower_chest = 5,
    upper_chest = 6,
    right_thigh = 7,
    left_thigh = 8,
    right_calf = 9,
    left_calf = 10,
    right_foot = 11,
    left_foot = 12,
    right_hand = 13,
    left_hand = 14,
    right_upper_arm = 15,
    right_forearm = 16,
    left_upper_arm = 17,
    left_forearm = 18,
    max = 19
}
do
    local hitboxes = {
        [lib_engine.hitboxes.head] = "head",
        [lib_engine.hitboxes.neck] = "neck",
        [lib_engine.hitboxes.pelvis] = "pelvis",
        [lib_engine.hitboxes.belly] = "belly",
        [lib_engine.hitboxes.thorax] = "thorax",
        [lib_engine.hitboxes.lower_chest] = "lower chest",
        [lib_engine.hitboxes.upper_chest] = "upper chest",
        [lib_engine.hitboxes.right_thigh] = "right thigh",
        [lib_engine.hitboxes.left_thigh] = "left thigh",
        [lib_engine.hitboxes.right_calf] = "right calf",
        [lib_engine.hitboxes.left_calf] = "left calf",
        [lib_engine.hitboxes.right_foot] = "right foot",
        [lib_engine.hitboxes.left_foot] = "left foot",
        [lib_engine.hitboxes.right_hand] = "right hand",
        [lib_engine.hitboxes.left_hand] = "left hand",
        [lib_engine.hitboxes.right_upper_arm] = "right upper arm",
        [lib_engine.hitboxes.right_forearm] = "right forearm",
        [lib_engine.hitboxes.left_upper_arm] = "left upper arm",
        [lib_engine.hitboxes.left_forearm] = "left forearm",
        [lib_engine.hitboxes.max] = "max",
    }
    ---@param index number
    ---@return "head"|"neck"|"pelvis"|"belly"|"thorax"|"lower chest"|"upper chest"|"right thigh"|"left thigh"|"right calf"|"left calf"|"right foot"|"left foot"|"right hand"|"left hand"|"right upper arm"|"right forearm"|"left upper arm"|"left forearm"|"max"
    lib_engine.get_hitbox_name = function(index)
        return hitboxes[index]
    end
    local hitgroups = {
        [lib_engine.hitgroups.generic] = "generic",
        [lib_engine.hitgroups.head] = "head",
        [lib_engine.hitgroups.chest] = "chest",
        [lib_engine.hitgroups.stomach] = "stomach",
        [lib_engine.hitgroups.left_arm] = "left arm",
        [lib_engine.hitgroups.right_arm] = "right arm",
        [lib_engine.hitgroups.left_leg] = "left leg",
        [lib_engine.hitgroups.right_leg] = "right leg",
        [lib_engine.hitgroups.gear] = "gear",
    }
    ---@param index number
    ---@return "generic"|"head"|"chest"|"stomach"|"left arm"|"right arm"|"left leg"|"right leg"|"gear"
    lib_engine.get_hitgroup_name = function (index)
        return hitgroups[index]
    end
    local hitgroup_to_hitbox = {
        [lib_engine.hitgroups.generic] = lib_engine.hitboxes.lower_chest,
        [lib_engine.hitgroups.head] = lib_engine.hitboxes.head,
        [lib_engine.hitgroups.chest] = lib_engine.hitboxes.lower_chest,
        [lib_engine.hitgroups.stomach] = lib_engine.hitboxes.belly,
        [lib_engine.hitgroups.left_arm] = lib_engine.hitboxes.left_upper_arm,
        [lib_engine.hitgroups.right_arm] = lib_engine.hitboxes.right_upper_arm,
        [lib_engine.hitgroups.left_leg] = lib_engine.hitboxes.left_thigh,
        [lib_engine.hitgroups.right_leg] = lib_engine.hitboxes.right_thigh,
        [lib_engine.hitgroups.gear] = lib_engine.hitboxes.lower_chest
    }
    lib_engine.hitgroup_to_hitbox = function(i)
        return hitgroup_to_hitbox[i] or 5
    end
    local hitbox_to_hitgroup = {
        [lib_engine.hitboxes.head] = lib_engine.hitgroups.head,
        [lib_engine.hitboxes.neck] = lib_engine.hitgroups.chest,
        [lib_engine.hitboxes.pelvis] = lib_engine.hitgroups.stomach,
        [lib_engine.hitboxes.belly] = lib_engine.hitgroups.stomach,
        [lib_engine.hitboxes.thorax] = lib_engine.hitgroups.stomach,
        [lib_engine.hitboxes.lower_chest] = lib_engine.hitgroups.chest,
        [lib_engine.hitboxes.upper_chest] = lib_engine.hitgroups.chest,
        [lib_engine.hitboxes.right_thigh] = lib_engine.hitgroups.right_leg,
        [lib_engine.hitboxes.left_thigh] = lib_engine.hitgroups.left_leg,
        [lib_engine.hitboxes.right_calf] = lib_engine.hitgroups.right_leg,
        [lib_engine.hitboxes.left_calf] = lib_engine.hitgroups.left_leg,
        [lib_engine.hitboxes.right_foot] = lib_engine.hitgroups.right_leg,
        [lib_engine.hitboxes.left_foot] = lib_engine.hitgroups.left_leg,
        [lib_engine.hitboxes.right_hand] = lib_engine.hitgroups.right_arm,
        [lib_engine.hitboxes.left_hand] = lib_engine.hitgroups.left_arm,
        [lib_engine.hitboxes.right_upper_arm] = lib_engine.hitgroups.right_arm,
        [lib_engine.hitboxes.right_forearm] = lib_engine.hitgroups.right_arm,
        [lib_engine.hitboxes.left_upper_arm] = lib_engine.hitgroups.left_arm,
        [lib_engine.hitboxes.left_forearm] = lib_engine.hitgroups.left_arm,
        [lib_engine.hitboxes.max] = 0,
    }
    lib_engine.hitbox_to_hitgroup = function(i)
        return hitbox_to_hitgroup[i] or 0
    end
end
lib_engine.time_to_ticks = function(time)
    return math.floor(time / globals.interval_per_tick + 0.5)
end
lib_engine.ticks_to_time = function(ticks)
    return ticks * globals.interval_per_tick
end
return lib_engine