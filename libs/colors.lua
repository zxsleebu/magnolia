---@class color_t
---@field fade fun(a: color_t, b: color_t, t: number): color_t
---@field alpha fun(s: color_t, a: number): color_t
---@field salpha fun(s: color_t, a: number): color_t

---@type (fun(r: number, g: number, b: number, a?: number): color_t)
---|{ red: color_t, green: color_t, blue: color_t, black: color_t, white: color_t, magnolia: color_t }
local col = setmetatable({}, {
    __index = {
        __call = function(s, r, g, b, a)
            return color_t.new(r, g, b, a or 255)
        end,
        red = color_t.new(255, 127, 127, 255),
        green = color_t.new(127, 255, 127, 255),
        blue = color_t.new(127, 127, 255, 255),
        white = color_t.new(255, 255, 255, 255),
        black = color_t.new(0, 0, 0, 255),
        magnolia = color_t.new(242, 232, 215, 255),
    }
})

local lerp = function(a, b, t)
    return a + (b - a) * t
end
color_t.fade = function(a, b, t)
    return color_t.new(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t))
end
color_t.alpha = function(s, a)
    return color_t.new(s.r, s.g, s.b, a)
end
color_t.salpha = function(s, a)
    return color_t.new(s.r, s.g, s.b, (s.a / 255) * a)
end
return col