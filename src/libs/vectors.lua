require("libs.advanced math")

---@class vec2_t
---@operator add(vec2_t): vec2_t
---@operator sub(vec2_t): vec2_t
---@operator mul(number|vec2_t): vec2_t
---@operator sub(number|vec2_t): vec2_t
---@operator unm(): vec2_t
---@field clamp fun(self: vec2_t, min: vec2_t, max: vec2_t): vec2_t
---@field round fun(self: vec2_t): vec2_t

---@class vec3_t
---@operator add(vec3_t): vec3_t
---@operator sub(vec3_t): vec3_t
---@operator mul(number|vec3_t): vec3_t
---@operator sub(number|vec3_t): vec3_t
---@operator unm(): vec3_t
---@operator len(): vec3_t
---@field remove_nan fun(self: vec3_t): vec3_t


---@type fun(x: number, y: number): vec2_t
local v2 = vec2_t.new
---@type fun(x: number, y: number, z: number): vec3_t
local v3 = vec3_t.new

-- vec2_t.__add = function(a, b)
--     return v2(a.x + b.x, a.y + b.y)
-- end
-- vec2_t.__sub = function(a, b)
--     return v2(a.x - b.x, a.y - b.y)
-- end
-- vec2_t.__mul = function(a, b)
--     return type(b) == "number" and v2(a.x * b, a.y * b) or v2(a.x * b.x, a.y * b.y)
-- end
-- vec2_t.__div = function(a, b)
--     return type(b) == "number" and v2(a.x / b, a.y / b) or v2(a.x / b.x, a.y / b.y)
-- end
vec2_t.__unm = function(a)
    return v2(-a.x, -a.y)
end
vec2_t.__tostring = function(a)
    return "vec2_t("..a.x..", "..a.y..")"
end
-- vec2_t.__eq = function(a, b)
--     return a.x == b.x and a.y == b.y
-- end
vec2_t.clamp = function(s, min, max)
    return v2(math.clamp(s.x, min.x, max.x), math.clamp(s.y, min.y, max.y))
end
vec2_t.round = function(s)
    return v2(math.round(s.x), math.round(s.y))
end

-- vec3_t.__add = function(a, b)
--     return v3(a.x + b.x, a.y + b.y, a.z + b.z)
-- end
-- vec3_t.__sub = function(a, b)
--     return v3(a.x - b.x, a.y - b.y, a.z - b.z)
-- end
-- vec3_t.__mul = function(a, b)
--     return type(b) == "number" and v3(a.x * b, a.y * b, a.z * b) or v3(a.x * b.x, a.y * b.y, a.z * b.z)
-- end
-- vec3_t.__div = function(a, b)
--     return type(b) == "number" and v3(a.x / b, a.y / b, a.z / b) or v3(a.x / b.x, a.y / b.y, a.z / b.z)
-- end
vec3_t.__unm = function(a)
    return v3(-a.x, -a.y, -a.z)
end
vec3_t.__tostring = function(a)
    return "vec3_t("..a.x..", "..a.y..", "..a.z..")"
end
-- vec3_t.__eq = function(a, b)
--     return a.x == b.x and a.y == b.y and a.z == b.z
-- end
vec3_t.__len = function (a)
    return (a.x ^ 2 + a.y ^ 2 + a.z ^ 2) ^ 0.5
end
vec3_t.remove_nan = function(s)
    if s.x ~= s.x then s.x = 0 end
    if s.y ~= s.y then s.y = 0 end
    if s.z ~= s.z then s.z = 0 end
    return s
end

---@class angle_t
---@field to_vec fun(s: angle_t): vec3_t
angle_t.to_vec = function (s)
    local pitch, yaw = math.deg2rad(s.pitch), math.deg2rad(s.yaw)
    local pcos = math.cos(pitch)
    return v3(pcos * math.cos(yaw), pcos * math.sin(yaw), -math.sin(pitch)):remove_nan()
end

return function()
    return v2, v3
end
