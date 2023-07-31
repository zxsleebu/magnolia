-- local interface, class = require("libs.interfaces")()
local cbs = require("libs.callbacks")
local hooks = require("libs.hooks")
local ffi = require("libs.protected_ffi")
local errors = require("libs.error_handler")
require("libs.types")
-- local nixware = require("libs.nixware")
-- ffi.cdef[[
--     typedef struct {
--     	vector_t origin;
--     	vector_t angles; 
--         char pad[4];
--     	void* renderable;
--     	const model_t* model;
--     	const void* model_to_world;
--     	const void* lightning_offset;
--     	const vector_t* lightning_origin;
--     	int flags;
--     	int entity_index;
--     	int skin;
--     	int body;
--     	int hitboxset;
--     	WORD instance;
--     } ModelRenderInfo_t;
-- ]]

local elements = {
    ---@type gui_dropdown_t
    walk_legs = nil,
    ---@type gui_dropdown_t
    air_legs = nil,
}

local function animbreaker()
    local lp = entitylist.get_local_player()
    local in_air = not lp:is_on_ground()
    if not elements.walk_legs or not elements.air_legs then
        return
    end
    local walk_legs, air_legs = elements.walk_legs:value(), elements.air_legs:value()
    local MOVEMENT_MOVE = lp:get_animlayer(6)
    if walk_legs == "Slide" then
        lp:set_poseparam(0, -180, -179)
    end
    if #lp.m_vecVelocity > 3 and (in_air and (air_legs == "Walking") or (not in_air and walk_legs == "Walking")) then
        MOVEMENT_MOVE.weight = 1
        lp:set_poseparam(7, -180, -179) --BODY_YAW
    end
    if air_legs == "Static" then
        lp:set_poseparam(6, 0.9, 1)
    end

    -- lp:get_animlayer(12).weight = 2.5
end

local ready_to_unhook = true
-- local offset = client.find_pattern("client.dll", "? ? ? ? ? F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B")

-- local CCSPlayer = hooks.vmt.new(ffi.cast("int*",
-- (client.find_pattern("client.dll", "55 8B EC 83 E4 F8 83 EC 18 56 57 8B F9 89 7C 24 0C") or error("wrong ccsplayer sig")) + 0x47))
-- local update_client_side_animations_orig
-- local update_client_side_animations_hk = function(this)
--     ready_to_unhook = false
--     local lp = entitylist.get_local_player()
--     local is_lp = false
--     errors.handle(function()
--         if not lp then return end
--         is_lp = this == ffi.cast("void*", lp[0])
--         if not is_lp then return end
--         print("hello")
--         lp:set_poseparam(0, -180, -179)
--         lp:set_poseparam(6, 0.9, 1)
--     end, "update_client_side_animations.pre_hook")
--     errors.handle(function()
--         if not is_lp then return end
--         lp:restore_poseparam()
--     end, "update_client_side_animations.post_hook")
--     ready_to_unhook = true
--     return update_client_side_animations_orig(this)
-- end
-- update_client_side_animations_orig = CCSPlayer:hookMethod("void(__thiscall*)(void*)", update_client_side_animations_hk, 224)


-- local IVEngineModel = hooks.vmt.new(se.create_interface("engine.dll", "VEngineModel016"))
-- local draw_model_execute_orig
-- ---@param info { renderable: any, model: any, origin: any, angles: any, flags: number, entity_index: number, skin: number, body: number, hitboxset: number, instance: number }
-- local draw_model_execute_hk = function(this, ctx, state, info, custom_bone_to_world)
--     local lp = entitylist.get_local_player()
--     errors.handle(function()
--         if not lp then return end
--         if lp:get_index() ~= info.entity_index then return end
--         lp:set_poseparam(0, -180, -179)
--         lp:set_poseparam(6, 0.9, 1)
--     end, "draw_model_execute_pre_hk")
--     ready_to_unhook = false
--     local ret_value = draw_model_execute_orig(this, ctx, state, info, custom_bone_to_world)
--     errors.handle(function()
--         if not lp then return end
--         lp:restore_poseparam()
--     end, "draw_model_execute_pre_hk")
--     ready_to_unhook = true
--     return ret_value
-- end
-- draw_model_execute_orig = IVEngineModel:hookMethod("void(__thiscall*)(void*, void*, void*, const ModelRenderInfo_t&, void*)", draw_model_execute_hk, 21)

-- local setup_bones_addr = client.find_pattern("client.dll", "? ? ? ? ? F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B") --SetupBones 55 8B EC 83 E4 F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B
-- if setup_bones_addr == 0 then return end
-- local setup_bones_jmp_addr = hooks.jmp2.rel_jmp(setup_bones_addr)
-- if not setup_bones_addr then return end

local setup_bones_addr = client.find_pattern("client.dll", "55 8B EC 57 8B F9 8B ? ? ? ? ? 8B 01 8B ? ? ? ? ? FF")
if setup_bones_addr == 0 then error("couldn't find setup_bones") end

local setup_bones_hk = function(original, ccsplayer, edx, bone_to_world_out, max_bones, bone_mask, current_time)
    ready_to_unhook = false
    local lp = entitylist.get_local_player()
    local is_lp = false
    errors.handle(function ()
        if not lp or not lp:is_alive() then return end
        is_lp = ccsplayer == ffi.cast("void*", lp[0])
        if not is_lp then return end
        animbreaker()
    end, "setup_bones.pre_hook")
    local result = original(ccsplayer, edx, bone_to_world_out, max_bones, bone_mask, current_time)
    errors.handle(function ()
        if not is_lp then return end
        lp:restore_poseparam()
    end, "setup_bones.post_hook")
    ready_to_unhook = true
    return result
end

local setup_bones_orig = hooks.jmp2.new("bool(__fastcall*)(void*, void*, void*, int, int, float)", setup_bones_hk, setup_bones_addr)

-- local hook_setup = false
-- local IClientRenderable_vmt
-- cbs.paint(function()
--     if IClientRenderable_vmt or hook_setup then return end
--     local lp = entitylist.get_local_player()
--     if not lp or not lp:is_alive() then return end
--     local client_renderable = lp:get_class():GetClientRenderable()
--     if not client_renderable then return end
--     -- local vmt = ffi.cast("void***", client_renderable)
--     -- if not vmt then return end
--     -- local setup_bones_native = vmt[0][13]
--     -- print(tostring(setup_bones_native))
--     -- if not nixware.is_in_range(setup_bones_native) then return end
--     -- iengine.log("setup bones initialized")
--     hook_setup = true
--     IClientRenderable_vmt = hooks.vmt.new(client_renderable)
--     setup_bones_orig = IClientRenderable_vmt:hookMethod("bool(__thiscall*)(int, void*, int, int, float)", setup_bones_hk, 13)
-- end)

-- cbs.frame_stage(function()
--     local lp = entitylist.get_local_player()
--     if not lp or not lp:is_alive() then return end
--     
--     
--     
--     
--     
-- end)

cbs.unload(function()
    local lp = entitylist.get_local_player()
    if lp then
        lp:restore_poseparam()
    end
    while not ready_to_unhook do
        print("waiting till unhook is possible")
    end

    setup_bones_orig:unhook()
    -- CCSPlayer:unHookAll()
    -- IVEngineModel:unHookAll()
end)

return elements