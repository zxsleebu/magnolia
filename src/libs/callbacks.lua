local errors = require("libs.error_handler")
-- local v2, v3 = require("libs.vectors")()
local hooks = require("libs.hooks")
local utils = require("libs.utils")
local cbs = {
    list = {
        unload = {},
        paint = {},
        create_move = {},
        shot_fired = {},
        override_view = {}
    },
    critical_list = {
        unload = {},
    }
}
local frame_stage_notify_callbacks = {}
local IBaseClient = hooks.vmt.new(utils.create_interface("client", "VClient018"))
local origin_fsn
origin_fsn = IBaseClient:hookMethod("void(__stdcall*)(int stage)", function(stage)
    origin_fsn(stage)
    errors.handle(function()
        for i = 1, #frame_stage_notify_callbacks do
            local callback = frame_stage_notify_callbacks[i]
            errors.handle(callback.fn, callback.name, stage)
        end
    end, "frame_stage_notify.loop")
end, 37)
register_callback("unload", function()
    IBaseClient:unHookAll()
end)
---@param fn fun()
---@param name? string
cbs.paint = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.paint, t)
end
---@param fn fun(cmd: user_cmd_t)
---@param name? string
cbs.create_move = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.create_move, t)
end
---@param fn fun(stage: number)
---@param name? string
cbs.frame_stage = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(frame_stage_notify_callbacks, t)
end
---@param fn fun()
---@param name? string
cbs.unload = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.unload, t)
end
---@param fn fun(shot_info: shot_info_t)
---@param name? string
cbs.shot_fired = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.shot_fired, t)
end
---@param fn fun(view_setup: view_setup_t)
---@param name? string
cbs.override_view = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.override_view, t)
end

cbs.add = function(name, fn)
    if not cbs.list[name] then
        cbs.list[name] = {}
    end
    local t = { fn = fn }
    table.insert(cbs.list[name], t)
end

cbs.critical = function(name, fn)
    if not cbs.critical_list[name] then
        cbs.critical_list[name] = {}
    end
    table.insert(cbs.critical_list[name], fn)
end

---@param event_name string
---@param fn fun(event: game_event_t)
---@param name? string
cbs.event = function(event_name, fn, name)
    register_callback(event_name, errors.handler(fn, name or event_name))
end

local shot_fired_callbacks = {}
---@param fn fun(shot: {from: vec3_t, to: vec3_t})
cbs.on_shot_fired = function(fn)
    table.insert(shot_fired_callbacks, fn)
end

return cbs