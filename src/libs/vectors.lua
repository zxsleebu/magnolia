require("libs.advanced math")

---@class vec2_t
---@operator add(vec2_t): vec2_t
---@operator sub(vec2_t): vec2_t
---@operator mul(number|vec2_t): vec2_t
---@operator sub(number|vec2_t): vec2_t
---@operator unm(): vec2_t
---@operator len(): number
---@field clamp fun(self: vec2_t, min: vec2_t, max: vec2_t): vec2_t
---@field round fun(self: vec2_t): vec2_t

---@class vec3_t
---@operator add(vec3_t): vec3_t
---@operator sub(vec3_t): vec3_t
---@operator mul(number|vec3_t): vec3_t
---@operator sub(number|vec3_t): vec3_t
---@operator unm(): vec3_t
---@operator len(): number
---@field remove_nan fun(self: vec3_t): vec3_t
---@field dist_to fun(self: vec3_t, other: vec3_t): number
---@field round fun(self: vec3_t): vec3_t
---@field dot fun(self: vec3_t, other: vec3_t): number
---@field length_sqr fun(self: vec3_t): number
---@field normalize fun(self: vec3_t): vec3_t
---@field pairs fun(self: vec3_t): { x: number, y: number, z: number }
---@field angle_to fun(self: vec3_t, to: vec3_t): angle_t


---@type fun(x: number, y: number): vec2_t
local v2 = vec2_t.new
---@type fun(x: number, y: number, z: number): vec3_t
local v3 = vec3_t.new

vec2_t.__unm = function(a)
    return v2(-a.x, -a.y)
end
vec2_t.__tostring = function(a)
    return "vec2_t("..a.x..", "..a.y..")"
end
vec2_t.__len = function (a)
    return (a.x ^ 2 + a.y ^ 2) ^ 0.5
end
vec2_t.clamp = function(s, min, max)
    return v2(math.clamp(s.x, min.x, max.x), math.clamp(s.y, min.y, max.y))
end
vec2_t.round = function(s)
    return v2(math.round(s.x), math.round(s.y))
end
vec3_t.__unm = function(a)
    return v3(-a.x, -a.y, -a.z)
end
vec3_t.__tostring = function(a)
    return "vec3_t("..a.x..", "..a.y..", "..a.z..")"
end
vec3_t.dot = function(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end
vec3_t.length_sqr = function(self)
    return self:dot(self)
end
vec3_t.__len = function (self)
    return self:length_sqr() ^ 0.5
end
---@param to vec3_t
---@return angle_t
vec3_t.angle_to = function(self, to)
    local delta = to - self
    local yaw = math.deg(math.atan2(delta.y, delta.x))
    local pitch = math.deg(math.atan2(delta.z, #delta))
    return angle_t.new(pitch, yaw, 0)
end

vec3_t.remove_nan = function(self)
    if self.x ~= self.x then self.x = 0 end
    if self.y ~= self.y then self.y = 0 end
    if self.z ~= self.z then self.z = 0 end
    return self
end
---@param a vec3_t
vec3_t.dist_to = function(self, a)
    return #(self - a)
end
vec3_t.round = function(self)
    return v3(math.round(self.x), math.round(self.y), math.round(self.z))
end
vec3_t.pairs = function(self)
    return pairs({x = self.x, y = self.y, z = self.z})
end
vec3_t.normalize = function(self)
    local len = #self
    if len == 0 then return self end
    return self / len
end

---@class angle_t
---@field to_vec fun(self: angle_t): vec3_t

---@param self angle_t
angle_t.to_vec = function (self)
    local pitch, yaw = math.rad(self.pitch), math.rad(self.yaw)
    local pcos = math.cos(pitch)
    return v3(pcos * math.cos(yaw), pcos * math.sin(yaw), -math.sin(pitch)):remove_nan()
end

return function()
    return v2, v3
end
