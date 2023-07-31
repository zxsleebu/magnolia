local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local nixware = require("libs.nixware")
local ffi = require("libs.protected_ffi")
local hooks = require("libs.hooks")
local create_move_fn = client.find_pattern("client.dll", "55 8B EC 83 E4 F8 81 EC ? ? ? ? 8B 45 08 89 0C 24")
ffi.cdef[[
    struct UserCmd {
        void*       vmt;
        int         commandNumber;
        int         tickCount;
        vector_t    viewangles;
        vector_t    aimdirection;
        float       forwardmove;
        float       sidemove;
        float       upmove;
        int         buttons;
        char        impulse;
        int         weaponselect;
        int         weaponsubtype;
        int         randomSeed;
        short       mousedx;
        short       mousedy;
        bool        hasbeenpredicted;
        vector_t    viewanglesBackup;
        int         buttonsBackup;
    };
]]
local hook
require("libs.advanced math")

gui.subtab("Builder")
local is_enabled = gui.checkbox("Enable")
---@alias anti_aim_condition_t "Shared"|"Stand"|"Move"|"Air"|"Air duck"|"Duck"|"Walk"|"Use"
local conditions = {"Shared", "Stand", "Move", "Air", "Air duck", "Duck", "Walk", "Use"}
local current_condition = gui.dropdown("Condition", conditions):master(is_enabled)
gui.column()
---@type table<anti_aim_condition_t, { enabled?: gui_checkbox_t, yaw_modifiers: gui_dropdown_t, yaw_offset: gui_slider_t, max_dormant_time: gui_slider_t, yaw_inverted: gui_slider_t, jitter_type: gui_dropdown_t, jitter_range: gui_slider_t, jitter_delay: gui_slider_t, spin_speed: gui_slider_t, spin_range: gui_slider_t, pitch: gui_dropdown_t, pitch_custom: gui_slider_t, desync_delay: gui_slider_t, desync_type: gui_dropdown_t, desync_length: gui_slider_t, inverted_desync_length: gui_slider_t}>
local settings = {}
for i = 1, #conditions do
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
    master_elements.yaw = gui.label(get_name("Yaw")):options(function ()
        setting.yaw_modifiers = gui.dropdown("Modifiers", {"At targets", "Inverted offset", "Jitter", "Spin"}, {})
        setting.yaw_offset = gui.slider("Yaw offset", -180, 180, false, 0)
        setting.yaw_inverted = gui.slider("Inverted yaw offset", -180, 180, false, 0):master(function()
            return setting.yaw_modifiers:value("Inverted offset")
        end)
        setting.max_dormant_time = gui.slider("Max time in dormant", 0, 10, true, 3):master(function()
            return setting.yaw_modifiers:value("At targets")
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
    master_elements.desync = gui.label(get_name("Desync")):options(function ()
        setting.desync_type = gui.dropdown("Desync type", {"Static", "Jitter", "Random"})
        setting.desync_length = gui.slider("Desync length", -60, 60, false, 60)
        setting.inverted_desync_length = gui.slider("Inverted desync length", -60, 60)
        setting.desync_delay = gui.slider("Desync switch delay", 0, 10):master(function()
            return setting.desync_type:value("Jitter")
        end)
    end)
    master_elements.pitch = gui.label(get_name("Pitch")):options(function ()
        setting.pitch = gui.dropdown("Pitch", {"Off", "Down", "Up", "Zero", "Random", "Custom"}, "Down")
        setting.pitch_custom = gui.slider("Custom pitch", -89, 89, false, 0):master(function()
            return setting.pitch:value("Custom")
        end)
    end)
    master_elements.defensive_aa = gui.label(get_name("Defensive AA")):options(function ()

    end)
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
    exploit_uncharged = false,
    next_jitter_update = 0,
    jitter_inverted = false,
    next_desync_update = 0,
    desync_inverted = false,
}
---@param max_dormant_time number
---@param at_targets_enabled boolean
local get_best_angle = function(max_dormant_time, at_targets_enabled)
    if clientstate.get_choked_commands() > 0 then
        anti_aim.target_player_index = anti_aim.last_target_index
        return anti_aim.last_best_angle
    end
    local best_player, best_player_pos = nil, nil
    local best_angle = 0
    local lp = entitylist.get_local_player()
    local viewangles = engine.get_view_angles()
    if at_targets_enabled then
        local lowest_fov = 2147483647
        local interval_per_tick = globalvars.get_interval_per_tick()
        local origin = lp.m_vecOrigin + lp.m_vecVelocity * interval_per_tick
        local viewangles_vec = viewangles:to_vec()
        local max_dormant_ticks = max_dormant_time / interval_per_tick
        for _, enemy in pairs(entitylist.get_players(0)) do
            errors.handle(function ()
                if enemy:get_ticks_in_dormant() > max_dormant_ticks then
                    return
                end
                local pos = enemy.m_vecOrigin + enemy.m_vecVelocity * interval_per_tick
                local fov = #(origin:angle_to(pos):to_vec() - viewangles_vec)
                if fov < lowest_fov then
                    lowest_fov = fov
                    best_player = enemy
                    best_player_pos = pos
                end
            end, "anti_aim.get_target_angle.for_loop")
        end
        if best_player_pos then
            local difference = origin:angle_to(best_player_pos)
            if difference then
                best_angle = difference.yaw
            end
        end
    end
    anti_aim.last_target_index = best_player and best_player:get_index() or -1
    anti_aim.target_player_index = anti_aim.last_target_index
    if not best_player or not best_player_pos then
        anti_aim.target_player_index = nil
        best_angle = viewangles.yaw
    end
    anti_aim.last_best_angle = best_angle
    return best_angle
end
local right_yaw_offset_address = nixware.find_pattern("F3 0F 10 47 10 F3 0F 5C C1 F3 0F 11 47 10 E9 ? ? ? ? B8")
if right_yaw_offset_address == 0 then
    error("failed to find internal pattern")
end
local patch_bytes =     { 0xB8, 0x00, 0x00, 0xB4, 0xC2, 0x66, 0x0F, 0x6E, 0xC0 }
local original_bytes =  { 0xF3, 0x0F, 0x10, 0x47, 0x10, 0xF3, 0x0F, 0x5C, 0xC1 }
local anti_aim_base_yaw = ui.get_combo_box("antihit_antiaim_yaw")
nixware.write_memory_bytes(right_yaw_offset_address, patch_bytes)
cbs.unload(function()
    nixware.write_memory_bytes(right_yaw_offset_address, original_bytes)
    anti_aim_base_yaw:set_value(1)
end)
local internal_yaw_offset = ffi.cast("float*", right_yaw_offset_address + 1)
local set_yaw = function(yaw)
    anti_aim_base_yaw:set_value(3)
    nixware.write_memory_callback(right_yaw_offset_address + 1, 4, function ()
        ffi.copy(internal_yaw_offset, ffi.new("float[1]", math.normalize_yaw(yaw)), 4)
    end)
end
local accurate_walk_enabled = ui.get_check_box("antihit_accurate_walk")
local accurate_walk = ui.get_key_bind("antihit_accurate_walk_bind")
local anti_aim_enabled = ui.get_check_box("antihit_antiaim_enable")
local at_targets_enabled = ui.get_check_box("antihit_antiaim_at_targets")
local yaw_jitter = ui.get_slider_int("antihit_antiaim_yaw_jitter")
local anti_aim_pitch = ui.get_combo_box("antihit_antiaim_pitch")
local desync_length = ui.get_slider_int("antihit_antiaim_desync_length")
local menu_desync_type = ui.get_combo_box("antihit_antiaim_desync_type")
local desync_inverter = ui.get_key_bind("antihit_antiaim_flip_bind")
local pitch_settings = {
    Off = 0,
    Down = 1,
    Zero = 2,
    Up = 3,
    Custom = 0,
    Random = 0,
}
local create_move_hk = function(original, this, cmd)
    errors.handle(function()
        if not is_enabled:value() then return end
        set_yaw(180)
        local lp = entitylist.get_local_player()
        if not lp or not lp:is_alive() then return end
        local condition = lp:get_condition() ---@type anti_aim_condition_t
        local is_walking = accurate_walk_enabled:get_value() and accurate_walk:is_active()
        if condition == "Move" and is_walking then
            condition = "Walk"
        end
        if bit.band(cmd.buttons, 32) ~= 0 then
            condition = "Use"
        end
        local setting = settings[condition]
        if not setting then return end
        if setting.enabled and not setting.enabled:value() then
            condition = "Shared"
            setting = settings[condition]
        end

        cmd.buttons = bit.band(cmd.buttons, bit.bnot(32))

        anti_aim_enabled:set_value(true)
        yaw_jitter:set_value(0)
        at_targets_enabled:set_value(false)

        local at_targets_setting = setting.yaw_modifiers:value("At targets")
        local yaw = get_best_angle(setting.max_dormant_time:value(), at_targets_setting) + setting.yaw_offset:value() + 180

        local pitch_setting = setting.pitch:value()
        local pitch = pitch_settings[pitch_setting]
        if pitch then
            anti_aim_pitch:set_value(pitch)
        end
        if pitch_setting == "Custom" then
            anti_aim_pitch:set_value(0)
            pitch = setting.pitch_custom:value()
            cmd.viewangles.pitch = pitch
        end

        local jitter_type, jitter_range, jitter_delay = setting.jitter_type:value(), setting.jitter_range:value(), setting.jitter_delay:value()
        local choked = clientstate.get_choked_commands()
        local jitter_angle = jitter_range
        local desync_type = setting.desync_type:value()
        if choked ~= 0 then
            if anti_aim.next_jitter_update <= 0 then
                anti_aim.next_jitter_update = jitter_delay
                anti_aim.jitter_inverted = not anti_aim.jitter_inverted
            else
                anti_aim.next_jitter_update = anti_aim.next_jitter_update - 1
            end
            if anti_aim.jitter_inverted then
                jitter_angle = -jitter_angle
            end

            if desync_type == "Jitter" then
                if anti_aim.next_desync_update <= 0 then
                    anti_aim.next_desync_update = setting.desync_delay:value()
                    anti_aim.desync_inverted = not anti_aim.desync_inverted
                else
                    anti_aim.next_desync_update = anti_aim.next_desync_update - 1
                end
            else
                anti_aim.desync_inverted = false
            end
            local current_desync = anti_aim.desync_inverted and setting.inverted_desync_length:value() or setting.desync_length:value()
            desync_length:set_value(math.abs(current_desync))
            menu_desync_type:set_value(0)
            desync_inverter:set_type(current_desync > 0 and 1 or 0)
            desync_inverter:set_key(0)
        end

        if jitter_type == "Center" then
            yaw = yaw + jitter_angle / 2
        end

        local is_charged = ragebot.is_charged()
        if is_charged then
            anti_aim.exploit_uncharged = false
        elseif not anti_aim.exploit_uncharged then
            anti_aim.exploit_uncharged = true
            at_targets_enabled:set_value(setting.yaw_modifiers:value("At targets"))
        end

        set_yaw(yaw)
    end, "anti_aim.create_move_hk")
    return original(this, cmd)
end
hook = hooks.jmp2.new("int(__thiscall*)(void* this, struct UserCmd* a2)", create_move_hk, create_move_fn)
client.register_callback("unload", function()
    hook:unhook()
end)