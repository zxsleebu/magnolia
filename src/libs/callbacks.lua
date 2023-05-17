local errors = require("libs.error_handler")
local v2, v3 = require("libs.vectors")()
local cbs = {
    list = {
        unload = {},
        paint = {},
        create_move = {},
        frame_stage_notify = {},
    },
    critical_list = {
        unload = {},
    }
}
---@overload fun(name: "create_move", fn: fun(cmd: usercmd_t))
---@overload fun(name: "paint", fn: fun())
---@overload fun(name: "unload", fn: fun())
---@overload fun(name: "frame_stage_notify", fn: fun(stage: number))
cbs.add = function(name, fn)
    if not cbs.list[name] then
        cbs.list[name] = {}
    end
    table.insert(cbs.list[name], fn)
end

cbs.critical = function(name, fn)
    if not cbs.critical_list[name] then
        cbs.critical_list[name] = {}
    end
    table.insert(cbs.critical_list[name], fn)
end

---@param name string
---@param fn fun(event: game_event_t)
cbs.event = function(name, fn)
    client.register_callback(name, errors.handle(fn, name))
end

local last_impact_pos
local shot_fired_callbacks = {}
cbs.event("bullet_impact", function(event)
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    local userid = lp:get_info().user_id
    if event:get_int("userid", 0) ~= userid then return end
    last_impact_pos = v3(event:get_float("x", 0), event:get_float("y", 0), event:get_float("z", 0))
end)
local last_eye_pos
cbs.add("create_move", function (cmd)
    ---@cast cmd usercmd_t
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then
        last_impact_pos = nil
        last_eye_pos = nil
    end
    if last_impact_pos and last_eye_pos then
        local dir = (last_impact_pos - last_eye_pos)
        last_eye_pos = last_eye_pos + (dir / #dir) * 3
        for _, fn in pairs(shot_fired_callbacks) do
            fn({
                from = last_eye_pos,
                to = last_impact_pos,
            })
        end
    end
    last_eye_pos = lp:get_eye_pos()
    last_impact_pos = nil
end)
---@param fn fun(shot: {from: vec3_t, to: vec3_t})
cbs.on_shot_fired = function(fn)
    table.insert(shot_fired_callbacks, fn)
end

return cbs