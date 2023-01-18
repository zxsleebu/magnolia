require("libs.advanced math")

---@alias __anim_mt (fun(value: number, time?: number): number)|(fun(): number)|{ done: boolean, value: number }
local anim_mt = {
    __call = function(s, value, time)
        if value == nil then
            return math.round(s.value)
        end
        if s.value == nil then
            s.value = value
        end
        s.value = math.anim(s.value, value, time)
        s.done = math.round(s.value) == value
        return math.round(s.value)
    end,
}

local anims = {}
local anims_mt = { }
anims_mt.__index = function(s, k)
    local list = rawget(s, "list")
    local value = list[k]
    if value == nil then
        list[k] = setmetatable({}, anim_mt)
        value = list[k]
    end
    return value
end
anims_mt.__newindex = function(s, k, v)
    local list = rawget(s, "list")
    local value = anims_mt.__index(s, k)
    list[k].value = v
    list[k].done = true
    list[k].anims = s
    return value
end
---@return { [string]: __anim_mt }
---@param values? { [string]: number }
anims.new = function(values)
    local t = { list = {} }
    setmetatable(t, anims_mt)
    for k, v in pairs(values or {}) do
        t[k] = v
    end
    return t
end
return anims