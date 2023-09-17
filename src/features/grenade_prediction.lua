require("libs.entity")
require("libs.advanced math")
local iengine = require("includes.engine")
local cbs = require("libs.callbacks")
local v2, v3 = require("libs.vectors")()
local errors = require("libs.error_handler")
local fonts = require("includes.gui.fonts")
local irender = require("libs.render")
local col = require("libs.colors")
local colors = require("includes.colors")
local beams = require("features.beams")

local molotov_throw_detonate_time = cvars.molotov_throw_detonate_time
local sv_gravity = cvars.sv_gravity
local weapon_molotov_maxdetonateslope = cvars.weapon_molotov_maxdetonateslope
local samples_per_second = 30

---@class grenade_prediction_t
---@field tickcount number
---@field next_think_tick number
---@field collision_group number
---@field detonate_time number
---@field throw_time number
---@field offset number
---@field bounces number
---@field grenade_type "flashbang"|"he"|"smoke"|"decoy"|"molotov"|nil
---@field last_update_tick number
---@field expire_time number
---@field detonated boolean
---@field collision_entity entity_t
---@field origin vec3_t
---@field velocity vec3_t
---@field entity_index number
---@field local_player boolean
---@field owner_index number
---@field broken boolean[]
---@field path { [1]: vec3_t, [2]: number }[]
local grenade_prediction_mt = {}
---@param bounced boolean
grenade_prediction_mt.update_path = function (self, bounced)
    self.path[#self.path + 1] = { self.origin + v3(0, 0, 0), self.tickcount }
    self.last_update_tick = self.tickcount
end
---@param bounced boolean
grenade_prediction_mt.detonate = function (self, bounced)
    self.detonated = true
    self:update_path(bounced)
end
grenade_prediction_mt.think = function (self)
    if self.grenade_type == "smoke" and #self.velocity <= 0.1 then
        self:detonate(false)
    elseif self.grenade_type == "decoy" and #self.velocity <= 0.2 then
        self:detonate(false)
    elseif (self.grenade_type == "flashbang"
        or self.grenade_type == "he"
        or self.grenade_type == "molotov")
        and (iengine.ticks_to_time(self.tickcount - self.offset) >= self.detonate_time)
    then
        self:detonate(false)
    end

    self.next_think_tick = self.tickcount + iengine.time_to_ticks(0.2)
end
---@param entity entity_t
grenade_prediction_mt.is_broken = function (self, entity)
    if not entity then
        return false
    end
    local handle = entity[0]
    if not handle then
        return false
    end
    local broken = self.broken[handle]
    self.broken[handle] = true
    if not broken then
        return false
    end
    return true
end
grenade_prediction_mt.physics_run_think = function (self)
    if self.next_think_tick > self.tickcount then
		return
    end
    self:think()
end
---@return vec3_t
grenade_prediction_mt.physics_add_gravity_move = function (self)
    local interval_per_tick = globals.interval_per_tick
    local gravity = sv_gravity:get_float() * 0.4
    local move = self.velocity * interval_per_tick


	local z = self.velocity.z - (gravity * interval_per_tick)

	move.z = ((self.velocity.z + z) / 2) * interval_per_tick
	self.velocity.z = z

    return move
end
---@param self grenade_prediction_t
---@param start vec3_t
---@param dest vec3_t
---@param mins vec3_t
---@param maxs vec3_t
---@param mask number
---@return trace_t
local trace_hull = function(self, start, dest, mins, maxs, mask)
    return engine.trace_hull(start, dest, mins, maxs, function (entity, contents_mask)
        if entity:is_grenade() then return false end
        if entity:get_index() == self.owner_index then return false end
        return true
    end, mask)
end
---@param start vec3_t
---@param dest vec3_t
---@param mask number
---@return trace_t
grenade_prediction_mt.trace_line = function(self, start, dest, mask)
    local null_v3 = v3(0, 0, 0)
    return trace_hull(self, start, dest, null_v3, null_v3, mask)
end
---@param start vec3_t
---@param dest vec3_t
---@param mask number
---@return trace_t
grenade_prediction_mt.trace_entity = function(self, start, dest, mask)
    local mins, maxs = v3(-2, -2, -2), v3(2, 2, 2)
    return trace_hull(self, start, dest, mins, maxs, mask)
end

---@param start vec3_t
---@param dest vec3_t
---@param mask number
---@return trace_t
grenade_prediction_mt.physics_trace_entity = function(self, start, dest, mask)
    local trace_info = self:trace_entity(start, dest, mask)

    if trace_info.start_solid and bit.band(trace_info.contents, 0x80000) then --CONTENTS_CURRENT_90
        trace_info = self:trace_entity(start, dest, bit.band(mask, bit.bnot(0x80000))) --~CONTENTS_CURRENT_90
    end

    if trace_info.fraction < 1 or trace_info.all_solid or trace_info.start_solid then
        if trace_info.entity then
            local hit_entity = trace_info.entity
            if hit_entity and hit_entity:is_player() then
                trace_info = self:trace_line(start, dest, mask)
            end
        end
    end

    return trace_info
end
---@param start vec3_t
---@param delta vec3_t
---@return trace_t
grenade_prediction_mt.physics_check_sweep = function (self, start, delta)
    local mask
    if self.collision_group == 1 then --COLLISION_GROUP_DEBRIS
        mask = 540683 --(MASK_SOLID | CONTENTS_CURRENT_90) & ~CONTENTS_MONSTER
    else
        mask = 1107845259 --(MASK_SOLID | CONTENTS_OPAQUE | CONTENTS_IGNORE_NODRAW_OPAQUE | CONTENTS_CURRENT_90| CONTENTS_HITBOX)
    end
    return self:physics_trace_entity(start, start + delta, mask)
end
-- -@param entity entity_t
---@param normal_z number
grenade_prediction_mt.touch = function (self, normal_z)
    if self.grenade_type == "molotov" then
        if normal_z >= math.cos(math.rad(weapon_molotov_maxdetonateslope:get_float())) then
            self:detonate(true)
        end
    -- -- elseif self.grenade_type == "tagranade" then
    -- --     if not entity:is_player() then
    -- --         self:detonate(true)
    -- --     end
    end
end
-- -@param entity entity_t
---@param normal_z number
grenade_prediction_mt.physics_impact = function (self, normal_z)--entity
    -- self:touch(entity, normal_z)
    self:touch(normal_z)
end
---@param push vec3_t
---@return trace_t
grenade_prediction_mt.physics_push_entity = function(self, push)
    local trace_info = self:physics_check_sweep(self.origin, push)

    if trace_info.start_solid then
        self.collision_group = 3 --COLLISION_GROUP_INTERACTIVE_DEBRIS
        trace_info = self:trace_line(self.origin - push, self.origin + push, 540683) --(MASK_SOLID | CONTENTS_CURRENT_90) & ~CONTENTS_MONSTER
    end

    if trace_info.fraction ~= 0 then
        self.origin = trace_info.end_pos
    end
    if trace_info.fraction ~= 1 then
        -- local hit_entity = entitylist.get(trace_info.hit_entity_index)
        -- if hit_entity then
            -- self:physics_impact(hit_entity, trace_info.normal.z)
        -- end
        self:physics_impact(trace_info.plane.normal.z)
    end

    return trace_info
end
---@param vector vec3_t
---@param normal vec3_t
---@param overbounce number
---@return vec3_t
local clip_velocity = function(vector, normal, overbounce)
    local STOP_EPSILON = 0.1
    local backoff = vector:dot(normal) * overbounce
    local out = v3(0, 0, 0)
    for k, _ in vector:pairs() do
        local change = normal[k] * backoff
        out[k] = vector[k] - change
        if out[k] > -STOP_EPSILON and out[k] < STOP_EPSILON then
            out[k] = 0
        end
    end
    return out
end
---@param trace_info trace_t
grenade_prediction_mt.perform_fly_collision_resolution = function(self, trace_info)
    local surface_elacticity = 1
    if trace_info.entity then
        local hit_entity = trace_info.entity
        if hit_entity then
            if hit_entity:is_breakable() and not self:is_broken(hit_entity) then
                self.velocity = self.velocity * 0.4
                return
            end
            if hit_entity:is_player() then
                surface_elacticity = 0.3
            end

            --if did not hit world
            if self.collision_entity == hit_entity then
                if hit_entity:is_player() then
                    self.collision_group = 1 --COLLISION_GROUP_DEBRIS
                    return
                end
            end
            self.collision_entity = hit_entity
        end
    end
    local total_elasticity = math.clamp(0.45 * surface_elacticity, 0, 0.9)
    local velocity = clip_velocity(self.velocity, trace_info.plane.normal, 2) * total_elasticity

    local interval_per_tick = globals.interval_per_tick
    if trace_info.plane.normal.z > 0.7 then
        local speed_sqr = velocity:length_sqr()
        if speed_sqr > 96000 then
            local l = velocity:normalize():dot(trace_info.plane.normal)
            if l > 0.5 then
                velocity = velocity * (1 - l + 0.5)
            end
        end
        if speed_sqr < 400 then
            self.velocity = v3(0, 0, 0)
        else
            self.velocity = velocity
            self:physics_push_entity(velocity * ((1 - trace_info.fraction) * interval_per_tick))
        end
        --!HACK
    else
        self.velocity = velocity
        self:physics_push_entity(velocity * ((1 - trace_info.fraction) * interval_per_tick))
    end
    if self.bounces > 20 then
        self:detonate(true)
    else
        self.bounces = self.bounces + 1
    end
end
grenade_prediction_mt.physics_simulate = function(self)
    self:physics_run_think()

    if self.detonated then
        return
    end

    local move = self:physics_add_gravity_move()
    local trace_info = self:physics_push_entity(move)

    if self.detonated then
        return
    end

    if trace_info.fraction ~= 1 then
        self:update_path(true)
        self:perform_fly_collision_resolution(trace_info)
    end

    -- self:physics_check_water_transition()
end
grenade_prediction_mt.predict = function(self)
    -- self:throw_grenade(grenade, origin, throw_angle)
    local sample_tick = iengine.time_to_ticks(1 / samples_per_second)
    self.last_update_tick = -sample_tick
    self.path = {}
    while self.tickcount < iengine.time_to_ticks(60) do
        if self.tickcount >= self.offset then
            errors.handler(function()
                self:physics_simulate()

                if self.last_update_tick + sample_tick < self.tickcount then
                    self:update_path(false)
                end
            end, "grenade_prediction_t.predict.while_loop")()
        end
        if self.detonated then
            break
        end
        self.tickcount = self.tickcount + 1
    end

    if self.last_update_tick + sample_tick < self.tickcount then
        self:update_path(false)
    end

    self.expire_time = self.throw_time + iengine.ticks_to_time(self.tickcount)
end


local grenade_prediction_t = {
    ---@param entity entity_t
    ---@param origin vec3_t
    ---@param velocity vec3_t
    ---@param owner entity_t
    ---@param grenade_type "flashbang"|"he"|"smoke"|"decoy"|"molotov"|nil
    ---@param throw_time number
    ---@param offset number
    ---@param local_player? boolean
    ---@return grenade_prediction_t
    new = function (entity, origin, velocity, owner, grenade_type, throw_time, offset, local_player)
        local detonate_time = 1.5
        if grenade_type == "molotov" then
            detonate_time = molotov_throw_detonate_time:get_float()
        end
        local s = setmetatable({
            tickcount = 0,
            next_think_tick = 0,
            collision_group = 13, --COLLISION_GROUP_PROJECTILE
            detonate_time = detonate_time,
            bounces = 0,
            grenade_type = grenade_type,
            last_update_tick = 0,
            detonated = false,
            collision_entity = nil,
            velocity = velocity,
            origin = origin,
            offset = offset,
            owner_index = owner:get_index(),
            entity_index = entity:get_index(),
            throw_time = throw_time,
            local_player = local_player,
            broken = {},
        }, { __index = grenade_prediction_mt })
        s:predict()
        return s
    end
}

---@type grenade_prediction_t[]
local list = {}

local beams_list = {}

cbs.paint(function()
    local highest_index = entitylist.get_highest_entity_index()
    local tick_count = globals.tick_count
    -- local interval_per_tick = globals.interval_per_tick

    for i = 1, highest_index do
        errors.handler(function()
            local entity = entitylist.get(i)
            if entity == nil or entity:is_dormant() then
                return
            end
            local grenade_type = entity:get_grenade_type()

            if grenade_type ~= "he" and grenade_type ~= "molotov" then
                return
            end
            -- if not grenade_type then
            --     return
            -- end

            local handle = entity[0]
            if not handle then return end
            local thrower = entity.m_hThrower
            if not thrower then return end
            if entity.m_nExplodeEffectTickBegin ~= 0 then
                list[handle] = nil
                return
            end
            local throw_time = entity.m_nGrenadeSpawnTime
            local offset = iengine.time_to_ticks(entity.m_flSimulationTime - globals.cur_time)
            if not list[handle] then
                list[handle] = grenade_prediction_t.new(
                    entity,
                    entity.m_vecOrigin,
                    entity.m_vecVelocity,
                    thrower,
                    grenade_type,
                    throw_time,
                    offset
                )
            else
                list[handle].offset = offset
                list[handle].throw_time = throw_time
            end
        end, "grenade_prediction_t.loop")()
    end

    for _, beam in pairs(beams_list) do
        -- beam:kill()
    end

    beams_list = {}

    for _, grenade in pairs(list) do
        errors.handler(function()
            local current_time = globals.cur_time
            if grenade.expire_time <= current_time then
                list[_] = nil
                return
            end
            if not grenade.path[1] then
                return
            end
            local valid_index = 1
            local throw_tick_count = iengine.time_to_ticks(grenade.throw_time)
            for a = #grenade.path, 1, -1 do
                if grenade.path[a][2] + throw_tick_count < tick_count then
                    break
                end
                valid_index = a
            end
            local entity = entitylist.get(grenade.entity_index)
            local origin = grenade.path[1][1]
            if entity and not grenade.local_player then
                origin = entity:get_origin()
            end
            if not origin and not grenade.local_player then return end
            local previous_w2s = iengine.world_to_screen(origin)--iengine.world_to_screen(grenade.path[valid_index][1])
            for a = valid_index + 1, #grenade.path - 1 do
                local w2s = iengine.world_to_screen(grenade.path[a][1])
                if previous_w2s and w2s then
                    -- local beam = beams.new({
                    --     amplitude = 1,
                    --     color = colors.magnolia,
                    --     width = 35,
                    --     life = interval_per_tick * (a - 1.5) * 3,
                    --     end_pos = pos,
                    --     start_pos = previous_pos,
                    --     model_name = "sprites/physbeam.vmt",
                    --     speed = 0,
                    --     segments = 2,
                    -- })
                    -- beams_list[#beams_list+1] = beam
                    render.line(previous_w2s, w2s, colors.magnolia)
                end
                previous_w2s = w2s
            end
            if grenade.local_player then return end
            local dist_w2s = render.world_to_screen(grenade.path[#grenade.path][1])
            if not dist_w2s then return end
            dist_w2s = dist_w2s:round()
            local size = v2(28, 24)
            local from = dist_w2s - (size / 2)
            local to = dist_w2s + (size / 2)
            local icon_name = "j"
            if grenade.grenade_type == "molotov" then
                icon_name = "l"
            end
            ---value from 0 to 1 that represents the time left until the grenade explodes
            local time_modifier = 1 - (grenade.expire_time - current_time) / grenade.detonate_time
            if dist_w2s then
                irender.box_shadow(from, to, colors.magnolia:alpha(time_modifier * 255), 1.5, 100, 6, 1.3)
                irender.rounded_rect(from, to, colors.magnolia:alpha(200), 3, false)
                irender.rounded_rect(from + v2(1, 1), to - v2(1, 1), colors.container_bg:alpha(240), 3, true)
                irender.text(icon_name, fonts.nade_warning, dist_w2s + v2(1, 0), col.white:fade(colors.magnolia, time_modifier), irender.flags.CENTER)
                -- render.text("!", fonts.menu, dist_w2s, col.white, render.flags.CENTER)
            end
        end, "grenade_prediction_t.draw")()
    end
end)


local current_local_prediction_handle = nil

cbs.create_move(function(cmd)
    if current_local_prediction_handle then
        list[current_local_prediction_handle] = nil
        current_local_prediction_handle = nil
    end
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    local weapon = lp:get_weapon()
    if not weapon then return end
    local entity = weapon.entity
    if not entity then return end
    if not entity:is_grenade() then return end
    if not entity.m_bPinPulled and entity.m_fThrowTime == 0 then return end

    local viewangles = cmd.viewangles:clone()
    if viewangles.pitch < -90 then
        viewangles.pitch = viewangles.pitch + 360
    elseif viewangles.pitch > 90 then
        viewangles.pitch = viewangles.pitch - 360
    end
    viewangles.pitch = viewangles.pitch - (90 - math.abs(viewangles.pitch)) * 10 / 90

    local throw_strength = math.clamp(entity.m_flThrowStrength, 0, 1)
    local src = lp:get_eye_pos()
    src.z = src.z + throw_strength * 12 - 12

    local velocity = math.clamp(weapon.throw_velocity * 0.9, 15, 750) * (throw_strength * 0.7 + 0.3)

    local direction = viewangles:to_vec()

    local trace_info = engine.trace_hull(src, src + direction * 22, v3(-2, -2, -2), v3(2, 2, 2), lp, 34095115)

    list[entity[0]] = grenade_prediction_t.new(
        entity,
        trace_info.end_pos - direction * 6,
        direction * velocity + lp.m_vecVelocity * 1.25,
        lp,
        entity:get_grenade_type(),
        globals.cur_time,
        0,
        true
    )
    current_local_prediction_handle = entity[0]
end)