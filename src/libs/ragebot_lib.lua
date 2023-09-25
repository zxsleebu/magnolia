local cbs = require("libs.callbacks")
local set = require("libs.set")
local drag = require("libs.drag")
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

local hitchance_sliders = {}

for i = 1, #rage_weapon_groups do
    local group = rage_weapon_groups[i]
    hitchance_sliders[group] = menu.find_slider_int("Hit chance", "Ragebot/Target/"..group)
end

local ragebot = {}

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
        if menu.is_visible() and drag.is_menu_hovered() then return end
        hitchance_override_value = hitchance
    end
    cbs.create_move(function (cmd)
        if not is_hitchance_overriden then
            for _, group in pairs(rage_weapon_groups) do
                hitchance_backups[group] = hitchance_sliders[group]:get()
            end
        end
        if hitchance_override_value then
            is_hitchance_overriden = true
            local active_weapon_group = ragebot.get_active_weapon_group()
            if active_weapon_group and rage_weapon_groups_set[active_weapon_group] then
                hitchance_sliders[active_weapon_group]:set(hitchance_override_value)
            end
        else
            is_hitchance_overriden = false
            for group, value in pairs(hitchance_backups) do
                hitchance_sliders[group]:set(value)
            end
        end
        hitchance_override_value = nil
    end)
end
do
    local double_tap = menu.find_check_box("Double tap [  ]", "Ragebot/Globals")
    local double_tap_bind = menu.find_key_bind("Double tap [  ]", "Ragebot/Globals")
    local hide_shots = menu.find_check_box("Hide shots", "Ragebot/Globals")
    local hide_shots_bind = menu.find_key_bind("Hide shots", "Ragebot/Globals")
    local fake_duck = menu.find_check_box("Fake duck", "Ragebot/Movement")
    local fake_duck_bind = menu.find_key_bind("Fake duck", "Ragebot/Movement")
    ragebot.is_charged = function()
        if fake_duck:get() and fake_duck_bind:is_active() then return false end
        return (double_tap:get() and double_tap_bind:is_active()) or (hide_shots:get() and hide_shots_bind:is_active())
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

return ragebot