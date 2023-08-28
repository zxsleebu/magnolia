require("libs.advanced math")
---@class color_t
---@field fade fun(s: color_t, new_color: color_t, factor: number): color_t
---@field alpha fun(s: color_t, new_alpha: number): color_t
---@field salpha fun(s: color_t, float_multiplier: number): color_t
-- -@field alpha_diff fun(s: color_t, alpha: number, diff: number): color_t
---@field alpha_anim fun(s: color_t, alpha: number, from: number, to: number): color_t

local col_mt = {}
col_mt.__call = function(s, r, g, b, a)
    return color_t.new(r / 255, g / 255, b / 255, (a or 255) / 255)
end

---@type (fun(r: number, g: number, b: number, a?: number): color_t)|{ red: color_t, green: color_t, blue: color_t, black: color_t, white: color_t, transparent: color_t, gray: color_t }
local col = setmetatable({}, col_mt)
col_mt.__index = {
    red = col(255, 127, 127),
    green = col(127, 255, 127),
    blue = col(127, 127, 255),
    white = col(255, 255, 255),
    black = col(0, 0, 0),
    gray = col(15, 15, 15),
    transparent = col(0, 0, 0, 0),
}




local lerp = function(a, b, t)
    return a + (b - a) * t
end
local color_mt = getmetatable(col(0, 0, 0, 0))
local orig_index = color_mt.__index
local alpha = function(s, a)
    return col(s.r, s.g, s.b, a)
end
color_mt.__index = function(s, k)
    if k == "alpha" then
        return alpha
    end
    if k == "r" or k == "g" or k == "b" or k == "a" then
        return math.round(orig_index(s, k) * 255)
    end
    local raw = orig_index(s, k)
    if raw then return raw end
end
color_mt.__tostring = function(s)
    return string.format("color_t(%d, %d, %d, %d)", s.r, s.g, s.b, s.a)
end

color_t.fade = function(a, b, t)
    return col(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t))
end
color_t.salpha = function(s, a)
    if not a then error("no alpha given to color_t:alpha", 2) end
    return col(s.r, s.g, s.b, math.clamp((s.a / 255) * a, 0, 255))
end
-- ---@param s color_t
-- color_t.alpha_diff = function(s, a, diff)
--     return s:salpha(((a / 255) * diff) + (255 - diff))
-- end
---@param s color_t
color_t.alpha_anim = function(s, a, from, to)
    return s:salpha(((a / 255) * (to - from)) + from)
end
return col