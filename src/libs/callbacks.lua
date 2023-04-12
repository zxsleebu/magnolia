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
---@overload fun(name: "frame_stage_notify", fn: fun(stage: number))
cbs.add = function(name, fn)
    if not cbs.list[name] then
        cbs.list[name] = {}
    end
    table.insert(cbs.list[name], fn)
end
return cbs