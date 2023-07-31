local cbs = require("libs.callbacks")
local set = require("libs.set")
local rage_weapon_groups = {
    "pistols",
    "deagle",
    "revolver",
    "smg",
    "rifle",
    "shotguns",
    "scout",
    "auto",
    "awp",
    "taser",
}
local rage_weapon_groups_set = set(rage_weapon_groups)

---@return string?
ragebot.get_active_weapon_group = function()
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    local weapon = lp:get_weapon()
    if not weapon then return end
    return weapon.group
end
do
    local hitchance_backups = {}
    local hitchance_override_value = nil
    local is_hitchance_overriden = false
    ragebot.override_hitchance = function(hitchance)
        if not ui.is_visible() then
            hitchance_override_value = hitchance
        end
    end
    cbs.create_move(function (cmd)
        if not is_hitchance_overriden then
            for _, group in pairs(rage_weapon_groups) do
                hitchance_backups[group] = ui.get_slider_int("rage_"..group.."_hitchance"):get_value()
            end
        end
        if hitchance_override_value then
            is_hitchance_overriden = true
            local active_weapon_group = ragebot.get_active_weapon_group()
            if active_weapon_group and rage_weapon_groups_set[active_weapon_group] then
                ui.get_slider_int("rage_"..active_weapon_group.."_hitchance"):set_value(hitchance_override_value)
            end
        else
            is_hitchance_overriden = false
            for group, value in pairs(hitchance_backups) do
                ui.get_slider_int("rage_"..group.."_hitchance"):set_value(value)
            end
        end
        hitchance_override_value = nil
    end)
end
do
    local double_tap = ui.get_check_box("rage_doubletap")
    local double_tap_bind = ui.get_key_bind("rage_doubletap_bind")
    local hide_shots = ui.get_check_box("rage_hide_shots")
    local hide_shots_bind = ui.get_key_bind("rage_hide_shots_bind")
    local fake_duck = ui.get_check_box("antihit_fakeduck")
    local fake_duck_bind = ui.get_key_bind("antihit_fakeduck_bind")
    ragebot.is_charged = function()
        if fake_duck:get_value() and fake_duck_bind:is_active() then return false end
        return (double_tap:get_value() and double_tap_bind:is_active()) or (hide_shots:get_value() and hide_shots_bind:is_active())
    end
end
-- do
--     local fakelag_limit = ui.get_slider_int("antihit_fakelag_limit")
--     local fakelag_disablers = ui.get_multi_combo_box("antihit_fakelag_disablers")
--     local fakelag_triggers = ui.get_multi_combo_box("antihit_fakelag_triggers")
--     local fakelag_trigger_limit = ui.get_slider_int("antihit_fakelag_trigger_limit")
--     ragebot.get_current_fakelag = function()

--     end
-- end