require("libs.advanced math")
---@class color_t
---@field fade fun(s: color_t, new_color: color_t, factor: number): color_t
---@field alpha fun(s: color_t, new_alpha: number): color_t
---@field salpha fun(s: color_t, float_multiplier: number): color_t
-- -@field alpha_diff fun(s: color_t, alpha: number, diff: number): color_t
---@field alpha_anim fun(s: color_t, alpha: number, from: number, to: number): color_t

---@type (fun(r: number, g: number, b: number, a?: number): color_t)
---|{ red: color_t, green: color_t, blue: color_t, black: color_t, white: color_t, magnolia: color_t, transparent: color_t, gray: color_t }
local col = setmetatable({}, {
    __index = {
        red = color_t.new(255, 127, 127, 255),
        green = color_t.new(127, 255, 127, 255),
        blue = color_t.new(127, 127, 255, 255),
        white = color_t.new(255, 255, 255, 255),
        black = color_t.new(0, 0, 0, 255),
        magnolia = color_t.new(242, 227, 201, 255),
        gray = color_t.new(15, 15, 15, 255),
        transparent = color_t.new(0, 0, 0, 0),
    },
    __call = function(s, r, g, b, a)
        return color_t.new(r, g, b, a or 255)
    end,
})



local lerp = function(a, b, t)
    return a + (b - a) * t
end
local color_mt = getmetatable(color_t.new(0, 0, 0, 0))
local orig_index = color_mt.__index
local alpha = function(s, a)
    return color_t.new(s.r, s.g, s.b, a)
end
color_mt.__index = function(s, k)
    if k == "alpha" then
        return alpha
    end
    local raw = orig_index(s, k)
    if raw then return raw end
    local real_key = ""
    if k == "r" then
        real_key = "red"
    elseif k == "g" then
        real_key = "green"
    elseif k == "b" then
        real_key = "blue"
    elseif k == "a" then
        real_key = "alpha"
    end
    if real_key ~= "" then
        return math.round(orig_index(s, real_key) * 255)
    end
end
color_mt.__tostring = function(s)
    return string.format("color_t(%d, %d, %d, %d)", s.r, s.g, s.b, s.a)
end

color_t.fade = function(a, b, t)
    return color_t.new(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t))
end
color_t.salpha = function(s, a)
    return color_t.new(s.r, s.g, s.b, math.clamp((s.a / 255) * a, 0, 255))
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