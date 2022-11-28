local v2 = require("libs.vectors")()

local corner_angles = {
    {180, 270},
    {270, 360},
    {0, 90},
    {90, 180}
}

local render = {}

---@param pts vec2_t[]
---@param color color_t
---@param smoothing? boolean
---@param closed? boolean
render.polyline = function(pts, color, smoothing, closed)
    if smoothing == nil then smoothing = true end
    if closed or closed == nil then renderer.line(pts[#pts], pts[1], color) end
    for i = 1, #pts do
        if i % 2 == 1 or not smoothing then
            if pts[i-1] and smoothing then renderer.line(pts[i], pts[i-1], color) end
            if pts[i+1] then renderer.line(pts[i], pts[i+1], color) end
        end
    end
end
---@param pos vec2_t
---@param radius number
---@param clr color_t
---@param start_angle number
---@param end_angle number
---@param filled? boolean
render.circle = function(pos, radius, clr, start_angle, end_angle, filled)
    start_angle = start_angle or 0
    end_angle = end_angle or 360
    local vertices = {}

    local step = end_angle >= start_angle and 10 or -10

    for i = start_angle, end_angle, step do
        local i_rad = math.rad(i)
        local point = pos + v2(math.cos(i_rad), math.sin(i_rad)) * radius
        vertices[#vertices+1] = point
    end
    for i = #vertices, 1, -1 do
        vertices[#vertices+1] = vertices[i]
    end
    if filled then
        return renderer.filled_polygon(vertices, clr)
    end
    render.polyline(vertices, clr)
end
---@param from vec2_t
---@param to vec2_t
---@param clr color_t
---@param r number
---@param filled? boolean
render.rounded_rect = function (from, to, clr, r, filled)
    local vertices = {}
    local pos = {
        v2(from.x + r, from.y + r),
        v2(to.x - r, from.y + r),
        v2(to.x - r, to.y - r),
        v2(from.x + r, to.y- r),
    }
    local i = 0
    for _, angles in pairs(corner_angles) do
        i = i + 1
        local step = angles[2] >= angles[1] and 10 or -10

        for a = angles[1], angles[2], step do
            local i_rad = math.rad(a)
            local point = pos[i] + v2(math.cos(i_rad), math.sin(i_rad)) * r
            vertices[#vertices+1] = point
        end
    end
    if filled then
        return renderer.filled_polygon(vertices, clr)
    end
    render.polyline(vertices, clr, true, true)
end
-- render.rounded_rect = function(from, to, clr, r, filled)
--     local x, y = from.x, from.y
--     local w, h = to.x - from.x, to.y - from.y
--     n = n or 20
--     if n % 4 > 0 then n = n + 4 - (n % 4) end
--     local pts, c, d, i = {}, {x + w / 2, y + h / 2}, {w / 2 - r, r - h / 2}, 0
--     local cos, sin, pi, ins = math.cos, math.sin, math.pi, table.insert
--     local ii = 0
--     while i < n do
--         local cur = v2(0, 0)
--         local a = i * 2 * pi / n
--         local p = {r * cos(a), r * sin(a)}
--         for j = 1, 2 do
--             if j == 1 then
--                 cur.x = c[j] + d[j] + p[j]
--             end
--             if j == 2 then
--                 cur.y = c[j] + d[j] + p[j]
--                 ins(pts, cur)
--             end
--             if p[j] * d[j] <= 0 and (p[1] * d[2] < p[2] * d[1]) then
--                 d[j] = d[j] * -1
--                 i = i - 1
--             end
--         end
--         i = i + 1
--         ii = ii + 1
--     end
--     if not filled then
--         return render.polyline(pts, clr, true, true) end
--     renderer.filled_polygon(pts, clr)
-- end
---@param from vec2_t
---@param to vec2_t
---@param clr color_t
---@param filled? boolean
render.smoothed_rect = function(from, to, clr, filled)
    if filled then
        renderer.rect_filled(from + v2(1, 0), to - v2(1, 0), clr)
        renderer.rect_filled(from + v2(0, 1), v2(from.x + 1, to.y - 1), clr)
        renderer.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), clr)
    else
        renderer.rect_filled(from + v2(1, 0), v2(to.x - 1, from.y + 1), clr)
        renderer.rect_filled(from + v2(0, 1), v2(from.x + 1, to.y - 1), clr)
        renderer.rect_filled(v2(from.x + 1, to.y - 1), to - v2(1, 0), clr)
        renderer.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), clr)
    end

    local new_col = clr:salpha(127)
    renderer.rect_filled(from, from + v2(1, 1), new_col)
    renderer.rect_filled(v2(to.x, from.y), v2(to.x - 1, from.y + 1), new_col)
    renderer.rect_filled(v2(from.x, to.y), v2(from.x + 1, to.y - 1), new_col)
    renderer.rect_filled(to - v2(1, 1), to, new_col)
end

---@class __font_t
---@field font font_t
---@field size number

local font_cache = {}
---@param name string
---@param size number
---@param flags? number
---@return __font_t
render.font = function(name, size, flags)
    local key = name .. size .. flags
    if font_cache[key] then return font_cache[key] end
    local font = renderer.setup_font(name, size, flags or 0)
    font_cache[key] = {
        font = font,
        size = size
    }
    return font_cache[key]
end
render.font_flags = {
    NoHinting = 1,
    NoAutoHint = 2,
    ForceAutoHint = 4,
    LightHinting = 8,
    MonoHinting = 16,
    Bold = 32,
    Oblique = 64,
    Monochrome = 128,
}
render.flags = {
    X_ALIGN = 0x1,
    Y_ALIGN = 0x2,
    SHADOW = 0x4,
    OUTLINE = 0x8,
}
---@param text string
---@param font __font_t
---@param pos vec2_t
---@param color color_t
---@param flags? number
render.text = function(text, font, pos, color, flags)
    if type(flags) == "table" then
        local int_flags = 0
        for _, flag in pairs(flags) do
            int_flags = int_flags + flag
        end
        flags = int_flags
    end
    flags = flags or 0
    --horizontal align
    if bit.band(flags, render.flags.X_ALIGN) == render.flags.X_ALIGN then
        pos.x = pos.x - renderer.get_text_size(font.font, font.size, text).x / 2
    end
    --vertical align
    if bit.band(flags, render.flags.Y_ALIGN) == render.flags.Y_ALIGN then
        pos.y = pos.y - renderer.get_text_size(font.font, font.size, text).y / 2
    end
    renderer.text(text, font.font, pos, font.size, color)
end
return render