require("libs.entity")
require("libs.ragebot_lib")
local render = require("libs.render")
local col = require("libs.colors")
local input = require("libs.input")
local fonts = require("includes.gui.fonts")
local v2, v3 = require("libs.vectors")()

gui.tab("Aimbot", "B")
gui.subtab("General")
pcall(function()
    gui.options(gui.checkbox("Jumpscout"), function ()
        gui.slider("Jumpscout hitchance", 40, 100, false, 50)
        gui.checkbox("Autostop in air")
    end):create_move(function (cmd, el)
        ui.get_key_bind("antihit_accurate_walk_bind"):set_type(1)
        local lp = entitylist.get_local_player()
        if not lp or not lp:is_alive() or lp:is_on_ground() then return end
        if lp:get_weapon().group ~= "scout" then return end
        local hitchance = el:get_slider("Jumpscout hitchance"):value()
        ragebot.override_hitchance(hitchance)
        local autostop = el:get_checkbox("Autostop in air"):value()
        if not autostop or input.is_key_pressed(32) then return end
        if not lp:can_shoot() then return end
        -- local velocity = #lp:get_velocity()
        local max_distance = 350 / (hitchance / 100)
        for _, entity in pairs(entitylist.get_players(0)) do
            if entity:is_alive() and entity:is_hittable_by(lp) then
                local distance = lp:get_origin():dist_to(entity:get_origin())
                if distance > max_distance then
                    return
                end
                -- if velocity < 100 then
                --     cmd.forwardmove = 0
                --     cmd.sidemove = 0
                -- end
                ui.get_key_bind("antihit_accurate_walk_bind"):set_type(0)
                ui.get_check_box("antihit_accurate_walk"):set_value(true)
                return
            end
        end
    end)
end)
gui.checkbox("Hitbox override")
gui.column()
gui.checkbox("HP conditions")

gui.subtab("Exploits")
gui.checkbox("Ideal tick")
gui.checkbox("Improve speed")
gui.checkbox("Auto teleport")
gui.subtab("Misc")
gui.tab("Anti-Aim", "C")
gui.subtab("General")
gui.subtab("Builder")
gui.tab("Visuals", "D")
gui.subtab("Players")
gui.subtab("World")
gui.subtab("Local")
gui.subtab("Widgets")
gui.subtab("Misc")

gui.tab("Misc", "E")
gui.subtab("General")
gui.checkbox("Autostrafer+"):create_move(function ()
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    ui.get_check_box("misc_autostrafer"):set_value(#lp:get_velocity() > 10)
end)