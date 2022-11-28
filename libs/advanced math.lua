---@param v number
---@param min number
---@param max number
---@return number
math.clamp = function(v, min, max)
    return math.min(math.max(min, v), max)
end
---@param a number
---@param b number
---@param t number|nil
---@return number
math.anim = function (a, b, t)
    return a + (b - a) * (globalvars.get_frame_time() * (t or 14))
end
---@param a number
---@return number
math.round = function(a)
    return math.floor(a + 0.5)
end
---@param a number
---@return number
math.deg2rad = function(a) return a * math.pi / 180.0 end
