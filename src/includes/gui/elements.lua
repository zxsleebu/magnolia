require("libs.entity")
require("libs.ragebot_lib")
local render = require("libs.render")
local col = require("libs.colors")
local input = require("libs.input")
local fonts = require("includes.gui.fonts")
local v2, v3 = require("libs.vectors")()
local shared = require("features.shared")
local cbs = require("libs.callbacks")
local iengine = require("includes.engine")
local anims = require("libs.anims")

gui.tab("Aimbot", "B")
gui.subtab("General")
pcall(function()
    gui.options(gui.checkbox("Jumpscout"), function ()
        gui.slider("Jumpscout hitchance", 40, 100, false, 60)
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
        local max_distance = 350 / (hitchance / 100)
        for _, entity in pairs(entitylist.get_players(0)) do
            if entity:is_alive() and entity:is_hittable_by(lp) then
                local distance = lp:get_origin():dist_to(entity:get_origin())
                if distance > max_distance then
                    return
                end
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
do
    local tracers = gui.options(gui.checkbox("Bullet tracers"), function()
        gui.slider("Time", 1, 10, 1, 4)
    end)
    local impacts = gui.options(gui.checkbox("Bullet impacts"), function()
        gui.slider("Time", 1, 10, 1, 4)
    end)
    cbs.event("bullet_impact", function(event)
        if not impacts:value() then return end
        local lp = entitylist.get_local_player()
        if not lp or not lp:is_alive() then return end
        local userid = lp:get_info().user_id
        if event:get_int("userid", 0) ~= userid then return end
        local pos = v3(event:get_float("x", 0), event:get_float("y", 0), event:get_float("z", 0))
        iengine.add_box_overlay(pos, impacts:get_slider("Time"):value(), col.blue:alpha(127))
    end)
    client.register_callback("shot_fired", function (shot_info)
        if not impacts:value() then return end
        iengine.add_box_overlay(shot_info.aim_point, impacts:get_slider("Time"):value(), col.red:alpha(127))
    end)
    ---@type { from: vec3_t, to: vec3_t, time: number, anims: __anims_mt }[]
    local tracers_list = {}
    cbs.on_shot_fired(function(shot)
        if tracers:value() then
            iengine.add_line_overlay(shot.from, shot.to, tracers:get_slider("Time"):value(), col.white:alpha(255))
        end
        -- tracers_list[#tracers_list+1] = {
        --     from = shot.from,
        --     to = shot.to,
        --     time = globalvars.get_real_time(),
        --     anims = anims.new({
        --         alpha = 255
        --     })
        -- }
    end)
    cbs.add("paint", function (cmd)
        -- if not tracers:value() then return end
        -- local time = tracers:get_slider("Time"):value()
        -- local current_time = globalvars.get_real_time()
        -- for i = 1, #tracers_list do
        --     local tracer = tracers_list[i]
        --     local alpha = tracer.anims.alpha(current_time < tracer.time + time and 255 or 0)
        --     local from, to = iengine.world_to_screen(tracer.from), iengine.world_to_screen(tracer.to)
        --     if from and to then
        --         renderer.line(from, to, col.white:alpha(alpha))
        --     end
        -- end
        -- for i = 1, #tracers_list do
        --     local tracer = tracers_list[i]
        --     if tracer and tracer.anims.alpha() <= 0 then
        --         table.remove(tracers_list, i)
        --     end
        -- end
    end)
end
gui.subtab("Widgets")
gui.subtab("Misc")

gui.tab("Misc", "E")
gui.subtab("General")

gui.checkbox("Autostrafer+"):create_move(function ()
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    if ui.is_visible() then
        return ui.get_check_box("misc_autostrafer"):set_value(true)
    end
    local velocity = lp:get_velocity()
    ui.get_check_box("misc_autostrafer"):set_value(#v2(velocity.x, velocity.y) > 10)
end)