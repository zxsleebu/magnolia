require("libs.entity")

-- require("libs.ragebot_lib")
-- local ffi = require("libs.protected_ffi")
-- local render = require("libs.render")
local col = require("libs.colors")
local input = require("libs.input")
local fonts = require("includes.gui.fonts")
local v2, v3 = require("libs.vectors")()
local cbs = require("libs.callbacks")
-- local iengine = require("includes.engine")
local anims = require("libs.anims")
local hooks = require("libs.hooks")
local set = require("libs.set")
local colors = require("includes.colors")
local errors = require("libs.error_handler")
local drag = require("libs.drag")
local delay = require("libs.delay")
-- require("features.create_move_hk")
-- require("features.revealer")

-- local shared = require("features.shared")

require("features.grenade_prediction")

gui.tab("Aimbot", "B")
gui.subtab("General")
do
    gui.checkbox("Jumpscout"):options(function ()
        gui.slider("Jumpscout hitchance", 40, 100, false, 60)
        gui.checkbox("Autostop in air")
    end):create_move(function (cmd, el)
        -- ui.get_key_bind("antihit_accurate_walk_bind"):set_type(1)
        -- local lp = entitylist.get_local_player()
        -- if not lp or not lp:is_alive() or lp:is_on_ground() then return end
        -- local weapon = lp:get_weapon()
        -- if not weapon then return end
        -- if weapon.group ~= "scout" then return end
        -- local hitchance = el:get_slider("Jumpscout hitchance"):value()
        -- ragebot.override_hitchance(hitchance)
        -- local autostop = el:get_checkbox("Autostop in air"):value()
        -- if not autostop or input.is_key_pressed(32) then return end
        -- if not lp:can_shoot() then return end
        -- local max_distance = 350 / (hitchance / 100)
        -- for _, entity in pairs(entitylist.get_players(0)) do
        --     if entity:is_alive() and entity:is_hittable_by(lp) then
        --         local distance = lp.m_vecOrigin:dist_to(entity.m_vecOrigin)
        --         if distance > max_distance then
        --             return
        --         end
        --         ui.get_key_bind("antihit_accurate_walk_bind"):set_type(0)
        --         ui.get_check_box("antihit_accurate_walk"):set_value(true)
        --         return
        --     end
        -- end
    end)
end
do
    local hitbox_overrides, safe_points ---@type gui_dropdown_t, gui_dropdown_t
    local override_damage, damage_value ---@type gui_checkbox_t, gui_slider_t
    gui.checkbox("Condition on lethal"):options(function ()
        hitbox_overrides = gui.dropdown("Hitbox overrides", {"Disable head", "Disable limbs"}, {})
        safe_points = gui.dropdown("Safe points", {"Same", "Default", "Prefer", "Force"})
        override_damage = gui.checkbox("Override min damage")
        damage_value = gui.slider("Min damage HP + ?", 0, 20):master(override_damage)
    end):create_move(function(cmd)
        -- local lp = entitylist.get_local_player()
        -- if not lp or not lp:is_alive() then return end
        -- local weapon = lp:get_weapon()
        -- if not weapon then return end
        -- local disable_head = hitbox_overrides:value("Disable head")
        -- local disable_limbs = hitbox_overrides:value("Disable limbs")
        -- local safe_point = safe_points:value()
        -- local safe_point_value = 0
        -- if safe_point == "Prefer" then
        --     safe_point_value = 1
        -- elseif safe_point == "Force" then
        --     safe_point_value = 2
        -- end
        -- local override = override_damage:value()
        -- local mindmg = damage_value:value()
        -- for _, enemy in pairs(entitylist.get_players(0)) do
        --     if enemy:is_alive() then
        --         local index = enemy:get_index()
        --         local stomach_damage = enemy:get_max_damage(lp, iengine.hitgroups.stomach, weapon)
        --         local leg_damage = enemy:get_max_damage(lp, iengine.hitgroups.left_leg, weapon)
        --         local health = enemy.m_iHealth
        --         if stomach_damage > health or leg_damage > health then
        --             if disable_head then
        --                 ragebot.override_hitscan(index, iengine.hitboxes.head, false)
        --             end
        --             if disable_limbs then
        --                 ragebot.override_hitscan(index, iengine.hitboxes.left_leg, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.right_leg, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.left_foot, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.right_foot, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.left_hand, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.right_hand, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.left_upper_arm, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.right_upper_arm, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.left_forearm, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.right_forearm, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.left_thigh, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.right_thigh, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.left_calf, false)
        --                 ragebot.override_hitscan(index, iengine.hitboxes.right_calf, false)
        --             end
        --             if safe_point ~= "Same" then
        --                 ragebot.override_safe_point(index, safe_point_value)
        --             end
        --             if override then
        --                 ragebot.override_min_damage(index, health + mindmg)
        --             end
        --         end
        --     end
        -- end
    end)
end
-- gui.checkbox("Test"):bind()
gui.column()
-- gui.checkbox("Hitbox override")
-- gui.checkbox("HP conditions")

gui.subtab("Exploits")
-- gui.checkbox("Ideal tick")
-- gui.checkbox("Improve speed")
-- gui.checkbox("Auto teleport")
gui.subtab("Misc")
gui.tab("Anti-Aim", "C")
gui.subtab("General")
require("features.antiaim")

gui.tab("Visuals", "D")
gui.subtab("Players")
gui.subtab("World")
do
    -- local beams = require("features.beams")
    -- local tracers = gui.checkbox("Bullet tracers"):options(function()
    --     gui.slider("Time", 1, 10, 1, 4)
    -- end):update(function(el)
    --     -- ui.get_check_box("visuals_esp_local_enable"):set_value(el:value())
    --     -- ui.get_check_box("visuals_esp_local_tracers"):set_value(el:value())
    -- end)
    -- local impacts = gui.checkbox("Bullet impacts"):options(function()
    --     gui.slider("Time", 1, 10, 1, 4)
    -- end)
    -- gui.column()
    -- beams.add_callback(function(info)
    --     if info.life == 2.5 then
    --         local from = v3(info.start_pos.x, info.start_pos.y, info.start_pos.z + 3)
    --         local to = v3(info.end_pos.x, info.end_pos.y, info.end_pos.z)
    --         if tracers:value() then
    --             iengine.add_line_overlay(from, to, tracers:get_slider("Time"):value(), col.white:alpha(255))
    --             info.renderable = false
    --         end
    --     end
    -- end)
    -- cbs.event("bullet_impact", function(event)
        -- if not impacts:value() then return end
        -- local lp = entitylist.get_local_player()
        -- if not lp or not lp:is_alive() then return end
        -- local userid = lp:get_info().user_id
        -- if event:get_int("userid", 0) ~= userid then return end
        -- local pos = v3(event:get_float("x", 0), event:get_float("y", 0), event:get_float("z", 0))
        -- iengine.add_box_overlay(pos, impacts:get_slider("Time"):value(), col.blue:alpha(127))
    -- end)
    -- register_callback("shot_fired", function (shot_info)
    --     if not impacts:value() then return end
    --     iengine.add_box_overlay(shot_info.aim_point, impacts:get_slider("Time"):value(), col.red:alpha(127))
    -- end)
    
    -- ---@type { from: vec3_t, to: vec3_t, time: number, anims: __anims_mt }[]
    -- local tracers_list = {}
    -- cbs.on_shot_fired(function(shot)
    --     -- tracers_list[#tracers_list+1] = {
    --     --     from = shot.from,
    --     --     to = shot.to,
    --     --     time = globalvars.get_real_time(),
    --     --     anims = anims.new({
    --     --         alpha = 255
    --     --     })
    --     -- }
    -- end)
    -- cbs.paint(function (cmd)
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
    -- end)
    -- gui.checkbox("Move lean"):callback("frame_stage_notify", function (stage, el)
    --     local lp = entitylist.get_local_player()
    --     if not lp or not lp:is_alive() then return end
    --     local animlayer = lp:get_animlayer(12)
    --     --get address of animlayer.weight
    --     -- print(tostring(animlayer))
    --     if not animlayer then return end
    --     -- animlayer.weight = 1 
    -- end)
    -- local offset = find_pattern("client.dll", "? ? ? ? F8 81 ? ? ? ? ? 53 56 8B F1 57 89 74 24 1C")
    -- local offset = find_pattern("client.dll", "? ? ? ? ? F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B")
    -- if offset ~= 0 then
    --     print("found")
    --     local bytes = ffi.cast("unsigned char*", offset)
    --     local new_bytes = ffi.new("uint8_t[?]", 5, {0x55, 0x8B, 0xEC, 0x83, 0xE4})
    --     local old_protect = ffi.new("DWORD[1]")
    --     win32.VirtualProtect(bytes, 5, 0x40, old_protect)
    --     win32.copy(bytes, new_bytes, 5)
    --     win32.VirtualProtect(bytes, 5, old_protect[0], old_protect)
    --     local hook
    --     local hk_setupbones = function(this, out, max, mask, time)
    --         -- if ecx then

    --         -- end
    --         print("hello")
    --         return hook(this, out, max, mask, time)
    --     end
    --     hook = hooks.jmp.new("bool(__thiscall*)(void* this, void* out, int max, int mask, float time)", hk_setupbones, offset)
    --     client.register_callback("unload", function()
    --         hook.stop()
    --     end)
    -- end
end
gui.subtab("Local")
require("features.model_changer")


require("features.animbreaker")

gui.column()


gui.subtab("Widgets")
do
    local logs = gui.checkbox("Ragebot logs"):options(function ()
        gui.checkbox("Under crosshair"):options(function ()
            -- gui.dropdown("Type", {"Text", "Box"})
            gui.dropdown("Sort", {"Newest at top", "Oldest at top"})
            -- gui.dropdown("Appear position", {"Top", "Bottom"})
        end)
    end)
    local unfiltred_other_events = {}
    ---@type { short_text: table, text: table, time: number, color: color_t, anims: { alpha: __anim_mt, active: __anim_mt } }[]
    local events = {}
    ---@param pos vec2_t
    ---@param size vec2_t
    ---@param color color_t
    ---@param alpha number
    ---@param active_anim number
    local render_container = function(pos, size, color, alpha, active_anim)
        pos, size = pos:round(), size:round()
        local radius = 5
        local accent_color = color:alpha(alpha)
        local active_color = accent_color:salpha(active_anim / 2 + 127)
        render.box_shadow(pos, pos + size, active_color, radius)
        render.rounded_rect(pos, pos + size, col.black:alpha(alpha / 1.25), radius, true)
        local margin = 20
        render.circle(pos + v2(radius, radius), radius + 0.1, accent_color, 190, 270, false)
        render.circle(pos + size - v2(radius + 1, radius + 1), radius + 0.1, accent_color, 10, 90, false)
        local width = margin + (size.x - margin) * active_anim / 255
        do
            local from = pos + v2(radius + 1, 0)
            render.rect_filled_fade(from, from + v2(width, 1), accent_color, accent_color:alpha(0), accent_color:alpha(0), accent_color)
        end
        do
            local from = pos + size - v2(radius, 0)
            render.rect_filled_fade(from, from - v2(width, 1), accent_color, accent_color:alpha(0), accent_color:alpha(0), accent_color)
        end
        do
            local from = pos + v2(0, radius)
            render.rect_filled_fade(from, from + v2(1, size.y - radius * 2 - 1), accent_color, accent_color, accent_color:alpha(0), accent_color:alpha(0))
        end
        do
            local from = pos + v2(size.x - 1, radius + 1)
            render.rect_filled_fade(from, from + v2(1, size.y - radius * 2 - 1), accent_color:alpha(0), accent_color:alpha(0), accent_color, accent_color)
        end
    end
    local logs_drag = drag.new("rage_logs", v2(0.5, 0.6), true)
    local preview_events = { }
    do
        local create_preview = function(text, color)
            return {
                short_text = text,
                anims = anims.new({
                    alpha = 255,
                    active = 255
                }),
                color = color
            }
        end
        preview_events = {
            create_preview({
                {"lia", col.white},
                {" stomach ", colors.magnolia},
                {"-", col.white},
                {"78", colors.magnolia},
            }, colors.magnolia),
            create_preview({
                {"lia", col.white},
                {" head ", col.red},
                {"[", col.white},
                {"spread", col.red},
                {"]", col.white},
            }, col.red),
            create_preview({
                {"lia", col.white},
                {" head ", col.green},
                {"-", col.white},
                {"112", col.green},
            }, col.green),
        }
    end
    -- local under_crosshair = logs:get_options("Under crosshair"):paint(function (el)
    --     local drag_size = v2(250, 100)
    --     local pos, highlight = logs_drag:run(drag.hover_fn(drag_size, true), function (pos, alpha)
    --         drag.highlight(pos - v2(drag_size.x / 2, 0), drag_size, alpha)
    --     end)
    --     local preview = ui.is_visible()
    --     local event_list = preview and preview_events or events
    --     -- render.dot(pos, col.red, 10)
    --     -- local type = el:get_dropdown("Type")
    --     local sort = el:get_dropdown("Sort")
    --     local reverse_sort = sort:value() ~= "Newest at top"
    --     local start_i = reverse_sort and 1 or #event_list
    --     local end_i = not reverse_sort and 1 or #event_list
    --     local loop_step = reverse_sort and 1 or -1
    --     local y = 0
    --     for i = start_i, end_i, loop_step do
    --         local event = event_list[i]
    --         if event then
    --             local alpha = event.anims.alpha()
    --             local active_anim = event.anims.active()
    --             local text_size = render.multi_text_size(event.short_text, fonts.gamesense) + v2(20, 0)
    --             render_container(pos + v2(-text_size.x / 2, y), v2(text_size.x, 26), event.color, alpha, active_anim)
    --             render.multi_color_text(event.short_text, fonts.gamesense, pos + v2(0, y + 7), render.flags.X_ALIGN + render.flags.SHADOW, alpha)

    --             y = y + math.round(30 * alpha / 255)
    --         end
    --     end
    --     highlight()
    -- end)
    -- cbs.paint(function ()
    --     local realtime = globalvars.get_real_time()
    --     local timeout = 2
    --     for i = 1, #events do
    --         local event = events[i]
    --         if event then
    --             local fading_out = #events - i > 9 or event.time + timeout < realtime
    --             event.anims.active(math.clamp(event.time + timeout - realtime, 0, timeout) / timeout * 255)
    --             local alpha = event.anims.alpha(not fading_out and 255 or 0)
    --             if alpha <= 0 then
    --                 table.remove(events, i)
    --             end
    --         end
    --     end
    -- end)
    local human_readable = {
        hegrenade = "explosion",
        smokegrenade = "grenade punch (lol)",
        inferno = "fire",
        decoy = "decoy punch or explosion (lol)",
        flashbang = "flashbang punch (lol)",
        taser = "taser",
        knife = "knife",
        molotov = "molotov punch (lol)"
    }
    -- cbs.event("player_hurt", function (event)
    --     local lp = entitylist.get_local_player()
    --     if entitylist.get_entity_by_userid(event:get_int("attacker", 0)) ~= lp then return end
    --     local killed = event:get_int("health", 0) < 1
    --     local uid = event:get_int("userid", 0)
    --     local entity = entitylist.get_entity_by_userid(uid)
    --     if not entity then return end
    --     if entity == lp then return end
    --     local color = colors.magnolia
    --     if killed then color = col.green end
    --     local weapon = event:get_string("weapon", "")
    --     local human_readable_weapon = human_readable[weapon]
    --     if not human_readable_weapon then return end
    --     local dmg = event:get_int("dmg_health", 0)
    --     local entity_name = entity:get_info().name
    --     local short_text = {
    --         {entity_name, col.white},
    --         {" -", color},
    --         {tostring(dmg), color},
    --     }
    --     local tickcount = globalvars.get_tick_count()
    --     unfiltred_other_events[tickcount] = unfiltred_other_events[tickcount] or {}
    --     unfiltred_other_events[tickcount][uid] = unfiltred_other_events[tickcount][uid] or {}
    --     if unfiltred_other_events[tickcount][uid][weapon] then
    --         unfiltred_other_events[tickcount][uid][weapon].dmg = unfiltred_other_events[tickcount][uid][weapon].dmg + dmg
    --         if killed then
    --             unfiltred_other_events[tickcount][uid][weapon].killed = true
    --         end
    --     else
    --         unfiltred_other_events[tickcount][uid][weapon] = {
    --             entity = event:get_int("userid", 0),
    --             type = weapon,
    --             short_text = short_text,
    --             time = globalvars.get_real_time(),
    --             tickcount = tickcount,
    --             dmg = dmg,
    --             killed = killed,
    --             color = color,
    --         }
    --     end
    -- end)
    -- cbs.frame_stage(function(stage)
    --     if stage ~= 5 then return end
    --     if not logs:value() then return end
    --     for _, entities in pairs(unfiltred_other_events) do
    --         for _, types in pairs(entities) do
    --             for _, event in pairs(types) do
    --                 local entity_name = entitylist.get_entity_by_userid(event.entity):get_info().name
    --                 local human_readable_weapon = human_readable[event.type]
    --                 local color = colors.magnolia
    --                 if event.killed then color = col.green end
    --                 local text = {
    --                     {event.killed and "killed " or "hit ", col.white},
    --                     {entity_name, color},
    --                     {" for ", col.white},
    --                     {tostring(event.dmg), color},
    --                     {" with ", col.white},
    --                     {human_readable_weapon, color},
    --                 }
    --                 local short_text = {
    --                     {entity_name, col.white},
    --                     {" -", col.white},
    --                     {tostring(event.dmg), color},
    --                 }
    --                 events[#events+1] = {
    --                     short_text = short_text,
    --                     text = text,
    --                     time = globalvars.get_real_time(),
    --                     anims = anims.new({
    --                         alpha = 0,
    --                         active = 255,
    --                     }),
    --                     color = color,
    --                 }
    --                 iengine.log(text)
    --             end
    --         end
    --     end
    --     unfiltred_other_events = {}
    -- end)
    local prepend_info = function (info, text, color)
        if #info > 0 then
            text[#text + 1] = {" ["}
            for i = 1, #info do
                text[#text + 1] = {info[i], color}
                if i ~= #info then
                    text[#text + 1] = {" | "}
                end
            end
            text[#text + 1] = {"]"}
        end
        return text
    end
    local percent_symbol = loadstring("return '⁒'")()
    -- ---@param shot_info shot_info_t
    -- client.register_callback("shot_fired", errors.handler(function (shot_info)
    --     if shot_info.manual then return end
    --     local entity = entitylist.get(shot_info.target_index)
    --     local name = entity:get_info().name
    --     local additional_info = {}
    --     local short_text, text
    --     local color
    --     if shot_info.result ~= "hit" then
    --         local target_hitbox = iengine.get_hitbox_name(shot_info.hitbox)
    --         ---@type string
    --         local reason = shot_info.result
    --         if reason == "unk" then
    --             reason = "?"
    --         elseif reason == "spread" then
    --             additional_info[#additional_info + 1] = tostring(shot_info.hitchance) .. percent_symbol
    --         elseif reason == "desync" then
    --             reason = "resolver"
    --             if shot_info.safe_point then
    --                 additional_info[#additional_info + 1] = "safe"
    --             end
    --         end
    --         additional_info[#additional_info + 1] = tostring(shot_info.client_damage) .. "dmg"
    --         additional_info[#additional_info + 1] = tostring(shot_info.backtrack) .. "t"
    --         color = col.red
    --         text = {
    --             {"missed ", col.white},
    --             {name, color},
    --             {"'s ", col.white},
    --             {target_hitbox, color},
    --             {" due to ", col.white},
    --             {reason, color}
    --         }
    --         short_text = {
    --             {name, col.white},
    --             {" ", col.white},
    --             {target_hitbox, color},
    --             {" [", col.white},
    --             {reason,color},
    --             {"]", col.white}
    --         }
    --         text = prepend_info(additional_info, text)
    --         iengine.log(text)
    --     else
    --         if shot_info.server_hitgroup == 0 then return end
    --         local mismatch_info = {}
    --         local killed = entity.m_iHealth < 1
    --         color = killed and col.green or colors.magnolia
    --         local client_hitgroup = iengine.hitbox_to_hitgroup(shot_info.hitbox)
    --         local damage_mismatch = not killed and (shot_info.client_damage - shot_info.server_damage > 3)
    --         local hitgroup_mismatch = client_hitgroup ~= shot_info.server_hitgroup
    --         if damage_mismatch then
    --             mismatch_info[#mismatch_info + 1] = tostring(shot_info.client_damage) .. " dmg"
    --         end
    --         if hitgroup_mismatch then
    --             mismatch_info[#mismatch_info + 1] = iengine.get_hitgroup_name(client_hitgroup)
    --         end
    --         if damage_mismatch or hitgroup_mismatch then
    --             additional_info[#additional_info + 1] = tostring(shot_info.hitchance) .. percent_symbol
    --             if shot_info.safe_point then
    --                 additional_info[#additional_info + 1] = "safe"
    --             end
    --         end
    --         local server_hitgroup = iengine.get_hitgroup_name(shot_info.server_hitgroup)
    --         additional_info[#additional_info + 1] = tostring(shot_info.backtrack) .. "t"
    --         text = {
    --             {killed and "killed " or "hit ", col.white},
    --             {name, color},
    --             {" in ", col.white},
    --             {server_hitgroup, color},
    --             {" for ", col.white},
    --             {tostring(shot_info.server_damage), color},
    --         }
    --         text = prepend_info(additional_info, text)
    --         if #mismatch_info > 0 then
    --             text[#text+1] = {" mismatch:", col.red}
    --             text = prepend_info(mismatch_info, text, col.red)
    --         end
    --         short_text = {
    --             {name, col.white},
    --             {" ", col.white},
    --             {server_hitgroup, color},
    --             {" -", col.white},
    --             {tostring(shot_info.server_damage), color},
    --         }
    --         iengine.log(text)
    --     end
    --     events[#events+1] = {
    --         short_text = short_text,
    --         text = text,
    --         time = globalvars.get_real_time(),
    --         color = color,
    --         anims = anims.new({
    --             alpha = 0,
    --             active = 255,
    --         })
    --     }
    -- end, "rage_logs.shot_fired"))
end
gui.subtab("Misc")
do
    local cvar = cvars.fov_cs_debug
    gui.checkbox("Viewmodel in scope"):paint(function (el)
        local value = el:value() and 90 or 0
        if cvar:get_int() ~= value then
            cvar:set_int(value)
        end
    end)
end
do
    -- local cvar = cvars.cam_idealdist
    -- local distance
    -- gui.checkbox("Thirdperson"):options(function ()
    --     distance = gui.slider("Distance", 0, 200, 0, 50)
    -- end):paint(function(el)
    --     local value = distance:value()
    --     if ui.get_key_bind("visuals_thirdperson_bind"):is_active() and cvar:get_int() ~=  value then
    --         cvar:set_int(value)
    --     end
    -- end)
end

gui.column()

gui.tab("Misc", "E")
gui.subtab("General")
do
    local primary, secondary, other
    local buybot = gui.checkbox("Buybot"):options(function()
        primary = gui.dropdown("Primary", {"None", "Scout", "AWP", "Auto", "AK47 / M4A1", "Nova", "XM1014", "MAG-7", "MAC10 / MP9", "MP7", "UMP45", "P90", "Bizon"})
        secondary = gui.dropdown("Secondary", {"None", "Deagle / R8", "Dualies", "P250", "Tec-9 / Five-SeveN", "Glock-18 / USP-S"})
        other = gui.dropdown("Other", {"Armor", "Helmet", "HE", "Molotov", "Smoke", "Flashbang", "Zeus", "Defuse kit"}, {})
    end)
    local buybot_fn = function()
        if not buybot:value() then return end
        local lp = entitylist.get_local_player()
        if not lp then return end
        if lp.m_iAccount <= 800 then return end
        local pistols_list = {
            ".deagle;.revolver",
            ".elite", ".p250",
            ".tec9;.fiveseven",
            ".glock;.hkp2000;.usp_silencer",
        }
        local weapons_list = {
            ".ssg08", ".awp", ".scar20;.g3sg1",
            ".ak47;.m4a1;.m4a1_silencer",
            ".nova", ".xm1014", ".mag7",
            ".mac10;.mp9",
            ".mp7", ".ump45", ".p90", ".bizon"
        }
        local other_list = {
            ".vest", ".vesthelm",
            ".hegrenade", ".molotov;.incgrenade", ".smokegrenade", ".flashbang",
            ".taser", ".defuser"
        }
        local cmd_table = {}
        local weapon = primary:val_index()
        local pistol = secondary:val_index()
        if weapon ~= 1 then cmd_table[#cmd_table + 1] = weapons_list[weapon - 1] end
        if pistol ~= 1 then cmd_table[#cmd_table + 1] = pistols_list[pistol - 1] end
        local others  = ""
        for i = 1, #other_list do
            others = others .. (other:val_index(i) and (other_list[i] .. ";") or "")
        end
        if others ~= "" then cmd_table[#cmd_table+1] = others end
        local cmd = table.concat(cmd_table, ";"):gsub("%.", "buy ")
        engine.execute_client_cmd(cmd)
    end
    cbs.event("round_prestart", buybot_fn)
    cbs.event("round_start", buybot_fn)
end
gui.checkbox("Console filter"):update(function (el)
    local value = el:value()
    cvars.con_filter_enable:set_int(value and 1 or 0)
    cvars.con_filter_text:set_string(value and "magnoliamagnoliamagnolia" or "")
end)
do
    gui.checkbox("Performance boost"):update(function(el)
        local on = el:value()
        local off = not on
        cvars.r_shadows:set_bool(off)
        cvars.cl_csm_static_prop_shadows:set_bool(off)
        cvars.cl_csm_shadows:set_bool(off)
        cvars.cl_csm_world_shadows:set_bool(off)
        cvars.cl_foot_contact_shadows:set_bool(off)
        cvars.cl_csm_viewmodel_shadows:set_bool(off)
        cvars.cl_csm_rope_shadows:set_bool(off)
        cvars.cl_csm_sprite_shadows:set_bool(off)
        cvars.cl_csm_world_shadows_in_viewmodelcascade:set_bool(off)
        cvars.cl_csm_translucent_shadows:set_bool(off)
        cvars.cl_csm_entity_shadows:set_bool(off)
        cvars.violence_hblood:set_bool(off)
        cvars.violence_ablood:set_bool(off)
        cvars.violence_agibs:set_bool(off)
        cvars.violence_hgibs:set_bool(off)
        cvars.r_3dsky:set_bool(off)
        cvars.r_drawdecals:set_bool(off)
        cvars.r_drawropes:set_bool(off)
        cvars.r_drawsprites:set_bool(off)
        cvars.r_eyemove:set_bool(off)
        cvars.r_eyegloss:set_bool(off)
        cvars.muzzleflash_light:set_bool(off)
        cvars.r_dynamic:set_bool(off)
        cvars.r_drawtracers_firstperson:set_bool(off)
        cvars.func_break_max_pieces:set_int(off and 15 or 0)
        cvars.fog_enable_water_fog:set_bool(off)
        cvars["@panorama_disable_blur"]:set_bool(on)
        cvars.dsp_slow_cpu:set_bool(on)
        cvars.cl_disable_ragdolls:set_bool(on)
        cvars.mat_disable_bloom:set_bool(on)
        engine.execute_client_cmd("r_cheapwaterend " .. (off and "0.1" or "0"))
        cvars.cl_detail_avoid_force:set_float(off and 0.4 or 0)
        cvars.cl_detail_avoid_radius:set_float(off and 64 or 0)
        cvars.cl_detail_avoid_recover_speed:set_float(off and 0.25 or 0)
        cvars.cl_detail_max_sway:set_float(off and 5 or 0)
        cvars.cl_downloadfilter:set_string("nosounds")
        cvars.mat_disable_fancy_blending:set_bool(on)
        cvars.mat_bufferprimitives:set_bool(on)
        cvars.mat_bumpmap:set_bool(off)
        cvars.mat_phong:set_bool(off)
        cvars.mat_specular:set_bool(off)
        cvars.mat_reducefillrate:set_bool(on)
        cvars.mat_clipz:set_bool(on)
        cvars.mat_autoexposure_max:set_float(off and 2 or 0)
        cvars.mat_autoexposure_min:set_float(off and 0.5 or 0)
    end):options(function()
        gui.checkbox("Minecraft mode"):update(function(el)
            local value = el:value()
            cvars.mat_showlowresimage:set_bool(value)
            local old_sv_cheats = cvars.sv_cheats:get_int()
            cvars.sv_cheats:set_int(1)
            engine.execute_client_cmd("mat_reloadallmaterials")
            cvars.sv_cheats:set_int(old_sv_cheats)
        end)
        gui.checkbox("Extra (can't disable)"):update(function()
            cvars.mat_parallaxmap:set_bool(true)
            cvars.mat_detail_tex:set_bool(true)
        end)
    end)
end
gui.column()
gui.checkbox("Autostrafer+"):create_move(function ()
    -- local lp = entitylist.get_local_player()
    -- if not lp or not lp:is_alive() then return end
    -- if ui.is_visible() then
    --     return ui.get_check_box("misc_autostrafer"):set_value(true)
    -- end
    -- local velocity = lp.m_vecVelocity
    -- ui.get_check_box("misc_autostrafer"):set_value(#v2(velocity.x, velocity.y) > 10)
end)