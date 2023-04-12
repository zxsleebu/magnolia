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
    cbs.add("create_move", function (cmd)
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