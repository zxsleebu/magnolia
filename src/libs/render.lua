local v2, v3 = require("libs.vectors")()
local col = require("libs.colors")
local errors = require("libs.error_handler")
-- local iengine = require("includes.engine")

local corner_angles = {
    {180, 270},
    {270, 360},
    {0, 90},
    {90, 180}
}

local irender = {}

---@param pts vec2_t[]
---@param color color_t
---@param smoothing? boolean
---@param closed? boolean
irender.polyline = function(pts, color, smoothing, closed)
    -- render.poly_line(pts, color)
    if smoothing == nil then smoothing = true end
    if closed or closed == nil then render.line(pts[#pts], pts[1], color) end
    for i = 1, #pts do
        if i % 2 == 1 or not smoothing then
            if pts[i-1] and smoothing then render.line(pts[i], pts[i-1], color) end
            if pts[i+1] then render.line(pts[i], pts[i+1], color) end
        end
    end
end
---@param pos vec2_t
---@param clr? color_t
---@param size? number
irender.dot = function(pos, clr, size)
    size = size or 1
    clr = clr or col.red
    render.rect_filled(pos, pos + v2(size, size), clr)
end
---@param pos vec2_t
---@param radius number
---@param clr color_t
---@param start_angle number
---@param end_angle number
---@param filled? boolean
irender.circle = function(pos, radius, clr, start_angle, end_angle, filled)
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
        return render.filled_polygon(vertices, clr)
    end
    irender.polyline(vertices, clr)
end
---@param from vec2_t
---@param to vec2_t
---@param clr color_t
---@param r number
---@param filled? boolean
irender.rounded_rect = function (from, to, clr, r, filled)
    if filled then
        render.rect_filled(from, to, clr, r)
        return
    end
    render.rect(from, to, clr, r)
    -- r = r + 0.1
    -- local vertices = {}
    -- local pos = {
    --     v2(from.x + r, from.y + r),
    --     v2(to.x - r, from.y + r),
    --     v2(to.x - r, to.y - r),
    --     v2(from.x + r, to.y- r),
    -- }
    -- local i = 0
    -- for _, angles in pairs(corner_angles) do
    --     i = i + 1
    --     local step = angles[2] >= angles[1] and 10 or -10

    --     for a = angles[1], angles[2], step do
    --         local i_rad = math.rad(a)
    --         local point = pos[i] + v2(math.cos(i_rad), math.sin(i_rad)) * r
    --         vertices[#vertices+1] = point
    --     end
    -- end
    -- if filled then
    --     return render.filled_polygon(vertices, clr)
    -- end
    -- irender.polyline(vertices, clr, true, true)
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
irender.smoothed_rect = function(from, to, clr, filled)
    if filled then
        render.rect_filled(from, to, clr, 1)
        return
    end
    render.rect(from, to, clr, 1)
    -- if filled then
    --     render.rect_filled(from + v2(1, 0), to - v2(1, 0), clr)
    --     render.rect_filled(from + v2(0, 1), v2(from.x + 1, to.y - 1), clr)
    --     render.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), clr)
    -- else
    --     render.rect_filled(from + v2(1, 0), v2(to.x - 1, from.y + 1), clr)
    --     render.rect_filled(from + v2(0, 1), v2(from.x + 1, to.y - 1), clr)
    --     render.rect_filled(v2(from.x + 1, to.y - 1), to - v2(1, 0), clr)
    --     render.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), clr)
    -- end

    -- local new_col = clr:salpha(127)
    -- render.rect_filled(from, from + v2(1, 1), new_col)
    -- render.rect_filled(v2(to.x, from.y), v2(to.x - 1, from.y + 1), new_col)
    -- render.rect_filled(v2(from.x, to.y), v2(from.x + 1, to.y - 1), new_col)
    -- render.rect_filled(to - v2(1, 1), to, new_col)
end

---@class __font_t
---@field font font_t
---@field size number

local font_cache = {}
---@param name string
---@param size number
---@param flags? number
---@return __font_t
irender.font = function(name, size, flags)
    local key = name .. size .. (flags or 0)
    if font_cache[key] then return font_cache[key] end
    local font = render.setup_font(name, size, flags or 0)
    font_cache[key] = {
        font = font,
        size = size
    }
    return font_cache[key]
end
irender.font_flags = {
    NoHinting = 1,
    NoAutoHint = 2,
    ForceAutoHint = 4,
    LightHinting = 8,
    MonoHinting = 16,
    Bold = 32,
    Oblique = 64,
    Monochrome = 128,
}
irender.flags = {
    X_ALIGN = 0x1,
    Y_ALIGN = 0x2,
    SHADOW = 0x4,
    MORE_SHADOW = 0x10,
    BIG_SHADOW = 0x20,
    RIGHT_ALIGN = 0x40,
    TEXT_SIZE = 0x80,
}
irender.flags.CENTER = irender.flags.X_ALIGN + irender.flags.Y_ALIGN

---@param font __font_t
---@param text string
irender.text_size = function(font, text)
    return render.calc_text_size(text, font.font, font.size)
end
local outline_pos = {
    v2(0, 1),
    v2(1, 0),
    v2(0, -1),
    v2(-1, 0),
    v2(1, 1),
    v2(1, -1),
    v2(-1, 1),
    v2(-1, -1),
}

local process_flags = function (text, font, pos, flags)
    local new_pos = v2(pos.x, pos.y)
    if type(flags) == "table" then
        local int_flags = 0
        for _, flag in pairs(flags) do
            int_flags = int_flags + flag
        end
        flags = int_flags
    end
    local text_size
    --horizontal align
    if bit.band(flags, irender.flags.X_ALIGN) == irender.flags.X_ALIGN then
        text_size = text_size or irender.text_size(font, text)
        new_pos.x = new_pos.x - text_size.x / 2
    end
    --vertical align
    if bit.band(flags, irender.flags.Y_ALIGN) == irender.flags.Y_ALIGN then
        text_size = text_size or irender.text_size(font, text)
        new_pos.y = new_pos.y - text_size.y / 2
    end
    --right align
    if bit.band(flags, irender.flags.RIGHT_ALIGN) == irender.flags.RIGHT_ALIGN then
        text_size = text_size or irender.text_size(font, text)
        new_pos.x = new_pos.x - text_size.x
    end
    --textsize
    if bit.band(flags, irender.flags.TEXT_SIZE) == irender.flags.TEXT_SIZE then
        text_size = text_size or irender.text_size(font, text)
    end

    return new_pos, text_size
end

---@param text string
---@param font __font_t
---@param pos vec2_t
---@param color color_t
---@param flags? number
---@return vec2_t, vec2_t?
irender.text = function(text, font, pos, color, flags)
    flags = flags or 0
    local new_pos, text_size = process_flags(text, font, pos, flags)

    local shadow = bit.band(flags, irender.flags.SHADOW) == irender.flags.SHADOW
    local more_shadow = bit.band(flags, irender.flags.MORE_SHADOW) == irender.flags.MORE_SHADOW
    local big_shadow = bit.band(flags, irender.flags.BIG_SHADOW) == irender.flags.BIG_SHADOW
    if shadow or more_shadow or big_shadow then
        local offset = 1
        if more_shadow then offset = 2 end
        if big_shadow then offset = 3 end
        render.text(text, font.font, new_pos + v2(offset, offset), col.black:alpha(150):salpha(color.a), font.size)
    end
    render.text(text, font.font, new_pos, color, font.size)
    return new_pos, text_size
end
---@param text string
---@param font __font_t
---@param pos vec2_t
---@param color color_t
---@param flags? number
---@param outline_color color_t?
---@return vec2_t, vec2_t?
irender.outline_text = function (text, font, pos, color, flags, outline_color)
    flags = flags or 0
    local new_pos, text_size = process_flags(text, font, pos, flags)
    local clr = (outline_color or col.black:alpha(100)):salpha(color.a)
    for _, p in pairs(outline_pos) do
        render.text(text, font.font, new_pos + p, clr, font.size)
    end
    render.text(text, font.font, new_pos, color, font.size)
    return new_pos, text_size
end

---@param fn fun(): vec2_t, vec2_t?
---@param font __font_t
---@param size number
irender.sized_text = function(fn, font, size)
    local old_size = font.size
    font.size = size
    local result1, result2 = errors.handle(fn)
    font.size = old_size
    return result1, result2
end
---@param strings { [1]: string, [2]: color_t }[]
---@param font __font_t
---@param pos vec2_t
---@param flags number
---@param alpha_multiplier number?
irender.multi_color_text = function(strings, font, pos, flags, alpha_multiplier)
    if alpha_multiplier == nil then
        alpha_multiplier = 255
    end
    if bit.band(flags or 0, irender.flags.X_ALIGN) == irender.flags.X_ALIGN then
        local str = ""
        for i = 1, #strings do str = str .. strings[i][1] end
        pos.x = pos.x - irender.text_size(font, str).x / 2
        flags = bit.band(flags, bit.bnot(irender.flags.X_ALIGN))
    end
    for i = 1, #strings do
        local text, color = strings[i][1], strings[i][2]:salpha(alpha_multiplier)
        irender.text(text, font, pos, color, flags)
        pos.x = pos.x + irender.text_size(font, text).x
    end
end

---@param strings { [1]: string, [2]: color_t }[]
---@param font __font_t
irender.multi_text_size = function(strings, font)
    local str = ""
    for i = 1, #strings do str = str .. strings[i][1] end
    return irender.text_size(font, str)
end

---@param from vec2_t
---@param to vec2_t
---@param color color_t
---@param radius number
---@param opacity? number
---@param spreading? number
---@param steps? number
irender.box_shadow = function(from, to, color, radius, opacity, steps, spreading)
    spreading = spreading or 2
    steps = steps or 4
    opacity = opacity or 15
    for i = 1, steps do
        irender.rounded_rect(
            from - v2(spreading * i, spreading * i),
            to + v2(spreading * i, spreading * i),
            color:salpha(opacity / i),
            math.min(math.ceil(radius * i + 1), 20),
            true
        )
    end
end

return irender