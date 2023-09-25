local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
-- local nixware = require("libs.nixware")
local ffi = require("libs.protected_ffi")
local v2, v3 = require("libs.vectors")()
-- local hooks = require("libs.hooks")
-- local create_move_fn = find_pattern("client.dll", "55 8B EC 83 E4 F8 81 EC ? ? ? ? 8B 45 08 89 0C 24")
-- ffi.cdef[[
--     struct UserCmd {
--         void*       vmt;
--         int         commandNumber;
--         int         tickCount;
--         vector_t    viewangles;
--         vector_t    aimdirection;
--         float       forwardmove;
--         float       sidemove;
--         float       upmove;
--         int         buttons;
--         char        impulse;
--         int         weaponselect;
--         int         weaponsubtype;
--         int         randomSeed;
--         short       mousedx;
--         short       mousedy;
--         bool        hasbeenpredicted;
--         vector_t    viewanglesBackup;
--         int         buttonsBackup;
--     };
-- ]]
-- local hook
require("libs.advanced math")

gui.subtab("Builder")
local is_enabled = gui.checkbox("Enable")
---@alias anti_aim_condition_t "Shared"|"Stand"|"Move"|"Air"|"Air duck"|"Duck"|"Walk"|"Use"
local conditions = {"Shared", "Stand", "Move", "Air", "Air duck", "Duck", "Walk", "Use"}
local current_condition = gui.dropdown("Condition", conditions):master(is_enabled)
local disable_modifiers_on_freestand, freestand_desync ---@type gui_checkbox_t, gui_checkbox_t
local freestand = gui.checkbox("Freestand"):options(function ()
    disable_modifiers_on_freestand = gui.checkbox("Disable modifiers")
    freestand_desync = gui.checkbox("Freestand desync")
end):master(is_enabled):bind()
gui.column()
---@type table<anti_aim_condition_t, { enabled?: gui_checkbox_t, yaw_modifiers: gui_dropdown_t, yaw_offset: gui_slider_t, inverted_yaw_offset: gui_slider_t, desync_modifiers: gui_dropdown_t, disable_choke: gui_checkbox_t, jitter_type: gui_dropdown_t, jitter_range: gui_slider_t, jitter_delay: gui_slider_t, spin_speed: gui_slider_t, spin_range: gui_slider_t, pitch: gui_dropdown_t, pitch_custom: gui_slider_t, desync_delay: gui_slider_t, desync_type: gui_dropdown_t, desync_length: gui_slider_t, inverted_desync_length: gui_slider_t}>
local settings = {}
for i = 1, #conditions do
    ---@type anti_aim_condition_t
    local condition = conditions[i]
    local setting = {}
    local get_name = function(name)
        return name .. " | " .. condition
    end
    local main_master_fn = function()
        return is_enabled:value() and condition == current_condition:value()
    end
    if condition ~= "Shared" then
        setting.enabled = gui.checkbox("Enable " .. condition):master(main_master_fn)
    end
    local master_elements = {}
    if condition ~= "Use" then
        master_elements.yaw = gui.label(get_name("Yaw")):options(function ()
            setting.yaw_modifiers = gui.dropdown("Modifiers", {"At targets", "Inverted offset", "Jitter", "Spin"}, {})
            setting.yaw_offset = gui.slider("Yaw offset", -180, 180, false, 0)
            setting.inverted_yaw_offset = gui.slider("Inverted yaw offset", -180, 180, false, 0):master(function()
                return setting.yaw_modifiers:value("Inverted offset")
            end)
            gui.label("Jitter"):options(function()
                setting.jitter_type = gui.dropdown("Jitter type", {"Center", "Offset", "Random"})
                setting.jitter_range = gui.slider("Jitter range", -90, 90, false, 0)
                setting.jitter_delay = gui.slider("Jitter delay", 0, 10)
            end):master(function()
                return setting.yaw_modifiers:value("Jitter")
            end)
            gui.label("Spin"):options(function ()
                setting.spin_speed = gui.slider("Spin speed", 1, 10)
                setting.spin_range = gui.slider("Spin range", 0, 360)
            end):master(function()
                return setting.yaw_modifiers:value("Spin")
            end)
        end)
    end
    master_elements.desync = gui.label(get_name("Desync")):options(function ()
        setting.desync_type = gui.dropdown("Desync type", {"None", "Static", "Jitter", "Random"})
        setting.desync_modifiers = gui.dropdown("Desync modifiers", {"Disable desync when zero delta"}, {}):master(function()
            return not setting.desync_type:value("None")
        end)
        setting.disable_choke = gui.checkbox("Disable fakelag when zero delta"):master(function()
            return setting.desync_modifiers:value("Disable desync when zero delta")
        end)
        setting.desync_length = gui.slider("Desync length", -60, 60, false, 60):master(function()
            return not setting.desync_type:value("None")
        end)
        setting.inverted_desync_length = gui.slider("Inverted desync length", -60, 60):master(function()
            return not setting.desync_type:value("None")
        end)
        setting.desync_delay = gui.slider("Desync switch delay", 0, 10):master(function()
            return setting.desync_type:value("Jitter")
        end)
    end)
    if condition ~= "Use" then
        master_elements.pitch = gui.label(get_name("Pitch")):options(function ()
            setting.pitch = gui.dropdown("Pitch", {"Off", "Down"}, "Down") --, "Random", "Custom"
            setting.pitch_custom = gui.slider("Custom pitch", -89, 89, false, 0):master(function()
                return setting.pitch:value("Custom")
            end)
        end)
        master_elements.defensive_aa = gui.label(get_name("Defensive AA")):options(function ()

        end)
    end
    local master_fn = function()
        return main_master_fn() and (setting.enabled and setting.enabled:value() or not setting.enabled)
    end
    for k, v in pairs(master_elements) do
        v:master(master_fn)
    end
    settings[condition] = setting
end
local anti_aim = {
    last_target_index = -1,
    last_best_angle = nil,
    target_player_index = -1,
    jitter_update_ticks = 0,
    desync_update_ticks = 0,
    sent_packets_count = 0,
    use_pressed = false
}
local menu_dormant_time = menu.find_slider_float("Dormant time", "ESP/ESP/Enemy")
-- local autopeek_bind = ui.get_key_bind("antihit_autopeek_bind")
---@param at_targets_enabled boolean
local get_target_best_angle = function(at_targets_enabled)
    if globals.choked_commands > 0 then
        anti_aim.target_player_index = anti_aim.last_target_index
        return anti_aim.last_best_angle
    end
    local best_player, best_player_pos = nil, nil
    local best_angle = nil
    local lp = entitylist.get_local_player()
    if not lp then return end
    local viewangles = engine.get_view_angles()
    if at_targets_enabled then
        local interval_per_tick = globals.interval_per_tick
        local max_dormant_ticks = menu_dormant_time:get() * interval_per_tick
        local lowest_fov = 2147483647
        local origin = lp:get_origin() + lp.m_vecVelocity * interval_per_tick
        local viewangles_vec = viewangles:to_vec()
        entitylist.get_entities("CCSPlayer", true, function (enemy)
            if enemy.m_iTeamNum == lp.m_iTeamNum then return end
            if enemy:get_ticks_in_dormant() > max_dormant_ticks then
                return
            end
            if not enemy:is_alive() then return end
            local pos = enemy:get_origin() + enemy.m_vecVelocity * interval_per_tick
            local fov = #(origin:angle_to(pos):to_vec() - viewangles_vec)
            if fov < lowest_fov then
                lowest_fov = fov
                best_player = enemy
                best_player_pos = pos
            end
        end)
        if best_player_pos then
            local difference = origin:angle_to(best_player_pos)
            if difference then
                best_angle = difference.yaw
            end
        end
    end
    anti_aim.last_target_index = -1
    if best_player then
        anti_aim.last_target_index = best_player:get_index()
    end
    anti_aim.target_player_index = anti_aim.last_target_index
    if not best_player or not best_player_pos then
        anti_aim.target_player_index = -1
        -- best_angle = viewangles.yaw
    end
    anti_aim.last_best_angle = best_angle
    return best_angle
end
---@return number?, boolean?
local get_freestand_angle = function()
    if not freestand:value() then return end
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    if anti_aim.target_player_index == -1 then
        get_target_best_angle(true)
    end
    if anti_aim.target_player_index == -1 then
        return
    end
    local targeted_player = entitylist.get(anti_aim.target_player_index)
    if not targeted_player or not targeted_player:is_alive() or targeted_player:is_hittable_by(lp) then return end
    local strength = 35
    local pos, origin = lp.m_vecOrigin + lp.m_vecVelocity * globals.interval_per_tick * 12, lp.m_vecOrigin
    -- pos.z = lp:get_player_hitbox_pos(0).z
    local yaw = anti_aim.last_best_angle
    if yaw == nil then
        yaw = engine.get_view_angles().yaw
    end
    local fractions = {}
    local player_origin = targeted_player.m_vecOrigin
    -- player_origin.z = targeted_player:get_player_hitbox_pos(0).z
    for i = yaw - 90, yaw + 90, 30 do
        if i ~= yaw then
            local rad = math.rad(i)
            local cos, sin = math.cos(rad), math.sin(rad)
            local new_head_pos = pos + v3(strength * cos, strength * sin, 0)
            local dest = origin + v3(256 * cos, 256 * sin, 0)
            local trace1 = engine.trace_line(new_head_pos, player_origin, lp, 0x46004003)
            local trace2 = engine.trace_line(origin, dest, lp, 0x46004003)
            fractions[#fractions+1] = {i, trace1.fraction / 2 + trace2.fraction / 2}
        end
    end
    table.sort(fractions, function(a, b) return a[2] > b[2] end)
    if fractions[1][2] - fractions[#fractions][2] < 0.5 then return end
    if fractions[1][2] < 0.1 then return end
    local is_left_side = fractions[1][1] < yaw
    return fractions[1][1], is_left_side
end
-- local right_yaw_offset_address = nixware.find_pattern("F3 0F 10 47 10 F3 0F 5C C1 F3 0F 11 47 10 E9 ? ? ? ? B8")
-- if right_yaw_offset_address == 0 then
--     error("failed to find internal pattern")
-- end
-- local patch_bytes =     { 0xB8, 0x00, 0x00, 0xB4, 0xC2, 0x66, 0x0F, 0x6E, 0xC0 }
-- local original_bytes =  { 0xF3, 0x0F, 0x10, 0x47, 0x10, 0xF3, 0x0F, 0x5C, 0xC1 }
-- -- local anti_aim_base_yaw = menu.("antihit_antiaim_yaw")
-- nixware.write_memory_bytes(right_yaw_offset_address, patch_bytes)
local yaw_offset = menu.find_slider_int("Yaw offset", "Movement/Anti aim")
local base_yaw = menu.find_combo_box("Base yaw", "Movement/Anti aim")
local accurate_walk_enabled = menu.find_check_box("Accurate walk", "Movement/Movement")
local accurate_walk = menu.find_key_bind("Accurate walk", "Movement/Movement")
local anti_aim_enabled = menu.find_check_box("Enabled", "Movement/Anti aim")
-- local at_targets_enabled = ui.get_check_box("antihit_antiaim_at_targets")
local yaw_jitter = menu.find_slider_int("Yaw modifier offset", "Movement/Anti aim")
local anti_aim_pitch = menu.find_combo_box("Pitch", "Movement/Anti aim")
local desync_length = menu.find_slider_int("Yaw desync length", "Movement/Anti aim")
local menu_desync_type = menu.find_combo_box("Yaw desync", "Movement/Anti aim")
local desync_inverter = menu.find_key_bind("Desync inverter", "Movement/Anti aim")
local fakelag_limit = menu.find_slider_int("Limit", "Movement/Fakelag")
local old_fakelag_limit = fakelag_limit:get()
local restored_fakelag_limit = false
local pitch_settings = {
    Off = 0,
    Down = 1,
}
cbs.create_move(function(cmd)
    if not is_enabled:value() then return end
    yaw_offset:set(180)
    base_yaw:set(1)
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    local condition = lp:get_condition() ---@type anti_aim_condition_t
    local is_walking = accurate_walk_enabled:get() and accurate_walk:is_active()
    if condition == "Move" and is_walking then
        condition = "Walk"
    end
    if bit.band(cmd.buttons, 32) ~= 0 then
        errors.handle(function()
            if anti_aim.use_pressed then
                cmd.buttons = bit.band(cmd.buttons, bit.bnot(32))
            end
            condition = "Use"
            local C4 = entitylist.get_entities("CPlantedC4", true)
            local origin = lp.m_vecOrigin
            if lp:get_weapon().group == "c4" or (C4[1] and C4[1].m_vecOrigin:dist_to(origin) <= 75) then
                return
            end
            local hostages = entitylist.get_entities("CHostage", true)
            if lp.m_hCarriedHostage then return end
            for i = 1, #hostages do
                if hostages[i].m_vecOrigin:dist_to(origin) <= 75 then return end
            end
            anti_aim.use_pressed = true
        end, "anti_aim.check_use_condition")
    else
        anti_aim.use_pressed = false
    end
    local setting = settings[condition]
    if not setting then return end
    if setting.enabled and not setting.enabled:value() then
        condition = "Shared"
        setting = settings[condition]
    end

    anti_aim_enabled:set(true)
    yaw_jitter:set(0)

    local yaw = 0

    if globals.choked_commands == 0 then
        anti_aim.sent_packets_count = anti_aim.sent_packets_count + 1

        if condition ~= "Use" then
            if anti_aim.sent_packets_count % (setting.jitter_delay:value() + 1) == 0 then
                anti_aim.jitter_update_ticks = anti_aim.jitter_update_ticks + 1
            end
        end

        if anti_aim.sent_packets_count % (setting.desync_delay:value() + 1) == 0 then
            anti_aim.desync_update_ticks = anti_aim.desync_update_ticks + 1
        end
    end

    local desync_inverted = false
    local current_desync = setting.desync_length:value()
    local desync_type = setting.desync_type:value()
    if desync_type == "Jitter" then
        if anti_aim.desync_update_ticks % 2 == 1 then
            desync_inverted = true
        end
    elseif desync_type == "Static" then

    end

    if desync_inverted then
        current_desync = setting.inverted_desync_length:value()
    end

    local disable_desync_on_zero_delta = setting.desync_modifiers:value("Disable desync when zero delta")
    local disable_choke = disable_desync_on_zero_delta and setting.disable_choke:value()

    menu_desync_type:set(not (desync_type == "None" or (disable_desync_on_zero_delta and current_desync == 0)) and 1 or 0)

    if disable_choke and current_desync == 0 then
        fakelag_limit:set(0)
        restored_fakelag_limit = false
    else
        if not restored_fakelag_limit then
            fakelag_limit:set(old_fakelag_limit)
            restored_fakelag_limit = true
        end
        old_fakelag_limit = fakelag_limit:get()
    end

    desync_length:set(math.abs(current_desync))
    desync_inverter:set_type(current_desync > 0 and 1 or 0)
    desync_inverter:set_key(0)

    if condition == "Use" then
        anti_aim_pitch:set(0)
        yaw_offset:set(0)
        yaw_offset:set(math.round(engine.get_view_angles().yaw))
        return
    end


    local jitter_type, jitter_range = setting.jitter_type:value(), setting.jitter_range:value()
    local jitter_angle = jitter_range

    local at_targets_setting = setting.yaw_modifiers:value("At targets")
    local pitch_setting = setting.pitch:value()
    local pitch = pitch_settings[pitch_setting]
    if pitch then
        anti_aim_pitch:set(pitch)
    end
    if desync_inverted and setting.yaw_modifiers:value("Inverted offset") then
        yaw = yaw + setting.inverted_yaw_offset:value()
    else
        yaw = yaw + setting.yaw_offset:value()
    end

    if setting.yaw_modifiers:value("Jitter") then
        if jitter_type == "Center" then
            if anti_aim.jitter_update_ticks % 2 == 1 then
                jitter_angle = -jitter_angle
            end
            yaw = yaw + jitter_angle / 2
        elseif jitter_type == "Offset" then
            if anti_aim.jitter_update_ticks % 2 == 1 then
                jitter_angle = 0
            end
            yaw = yaw + jitter_angle
        end
    end


    local at_targets_angle = get_target_best_angle(at_targets_setting)

    local freestand_angle, left_side_freestand
    if condition ~= "Use" then
        freestand_angle, left_side_freestand = get_freestand_angle()
    end
    if freestand_angle ~= nil then
        if disable_modifiers_on_freestand:value() then
            yaw = freestand_angle
        else
            yaw = yaw + freestand_angle
        end
        if freestand_desync:value() then
            menu_desync_type:set(1)
            desync_length:set(60)
            desync_inverter:set_type(left_side_freestand and 1 or 0)
        end
    else
        if at_targets_angle ~= nil then
            yaw = yaw + at_targets_angle
        else
            yaw = yaw + engine.get_view_angles().yaw
        end
    end

    yaw_offset:set(math.round(yaw + 180))
end, "anti_aim.create_move")
    -- return original(this, cmd)
-- hook = hooks.jmp2.new("int(__thiscall*)(void* this, struct UserCmd* a2)", create_move_hk, create_move_fn)
-- client.register_callback("unload", function()
--     if not hook then return end
--     hook:unhook()
-- end)