local errors = require("libs.error_handler")
local cbs = {
    list = {
        unload = {},
        paint = {},
        create_move = {},
        frame_stage_notify = {},
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

---@param name string
---@param fn fun(event: game_event_t)
cbs.event = function(name, fn)
    client.register_callback(name, errors.handle(fn, name))
end
return cbs