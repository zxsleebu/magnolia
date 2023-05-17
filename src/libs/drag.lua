local v2 = require("libs.vectors")()
local render = require("libs.render")
local col = require("libs.colors")
require("libs.advanced math")
local modules = require("libs.modules")
ffi.load('user32')
require("libs.types")
ffi.cdef[[
    typedef void* HANDLE;
    HANDLE LoadCursorA(HANDLE, PCSTR);
    typedef struct { long x; long y; } POINT;
]]
local SetCursor = modules.get_function("HANDLE(__stdcall*)(HANDLE)", "user32", "SetCursor")
local ss = engine.get_screen_size()
local input = require("libs.input")
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local drag = {
    __elements = {},
    __blocked = false,
    ---@param to_pos? vec2_t
    is_hovered = function(pos, size, to_pos)
        local cursor = renderer.get_cursor_pos()
        local from = pos
        local to = to_pos or pos + size
        local distance_from, distance_to = cursor - from, cursor - to

        --!HOVER DEBUG
        -- renderer.rect(from, to, col(255, 255, 255, 127))
        --!HOVER DEBUG

        if distance_from.x > 0 and distance_from.y > 0
            and distance_to.x < 0 and distance_to.y < 0 then
            return true
        end
    end,
    ---@param pos vec2_t
    ---@param size vec2_t
    ---@param alpha number
    highlight = function(pos, size, alpha)
        local from, to = pos, pos + size
        render.rounded_rect(from:round() - v2(3, 3), to:round() + v2(2, 2), col(200, 200, 200, alpha / 3), 3)
        local shine = col.white:alpha(alpha / 25)
        local trans = col.white:alpha(0)

        renderer.rect_filled_fade(from, from + size / 2, trans, trans, shine, trans)
        renderer.rect_filled_fade(from + size / 2, to, shine, trans, trans, trans)
        renderer.rect_filled_fade(v2(from.x + size.x / 2, from.y), from + v2(size.x, size.y / 2), trans, trans, trans, shine)
        renderer.rect_filled_fade(v2(from.x, from.y + size.y / 2), from + v2(size.x / 2, size.y), trans, shine, trans, trans)
    end,
    current_cursor = nil,
}
drag.arrow_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32512))
drag.move_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32646))
drag.hand_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32649))
drag.horizontal_resize_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32644))
drag.new = errors.handle(function(key, default_pos, pointer)
    if pointer == nil then pointer = true end
    drag.__elements[key] = {
        pos = {
            x = ui.add_slider_float(key .. "__x", key .. "_dx", 0, 1, default_pos.x),
            y = ui.add_slider_float(key .. "__y", key .. "_dy", 0, 1, default_pos.y),
        },
        hovered = false,
        key = key,
        highlight_alpha = 0,
        old_cursor = renderer.get_cursor_pos() / engine.get_screen_size(),
        dragging = false,
        move_cursor = false,
        blocked = false,
        pointer = pointer
    }
    drag.__elements[key].pos.x:set_visible(false) drag.__elements[key].pos.y:set_visible(false)
    return setmetatable(drag.__elements[key], drag.mt)
end, "drag.new")

drag.is_menu_hovered = function()
    local rect = ui.get_menu_rect()
    return drag.is_hovered(v2(rect.x, rect.y), v2(rect.z - rect.x, rect.w - rect.y))
end
---@param from vec2_t
---@param to vec2_t
drag.hover_absolute = function(from, to)
    return drag.is_hovered(from, nil, to)
        and not (drag.is_menu_hovered() and ui.is_visible())
end
---@param size vec2_t
---@param center_x? boolean
drag.hover_fn = function(size, center_x, center_y)
    return function(pos)
        return drag.is_hovered(v2(center_x and pos.x - size.x / 2 or pos.x, center_y and pos.y - size.y / 2 or pos.y) or pos, size)
            and not (drag.is_menu_hovered() and ui.is_visible())
    end
end
drag.block = function()
    drag.__blocked = true
end
drag.mt = {
    ---@class draggable_t
    ---@field pos { x: slider_float_t, y: slider_float_t }
    ---@field key string
    ---@field dragging boolean
    ---@field blocked boolean
    ---@field highlight_alpha number
    ---@field old_cursor vec2_t
    ---@field pointer boolean
    __index = {
        ---@param s draggable_t
        ---@param hover_fn fun(pos: vec2_t): boolean
        ---@param highlight? fun(pos: vec2_t, alpha: number)
        ---@return vec2_t, fun()
        run = errors.handle(function(s, hover_fn, highlight)
            local draggable = ui.is_visible() and not s.blocked
            for _, elem in pairs(drag.__elements) do
                if draggable and elem.hovered and elem.key ~= s.key then
                    draggable = false
                end
            end
            local pos = v2(s.pos.x:get_value(), s.pos.y:get_value()):clamp(v2(0, 0), v2(1, 1))
            local pressed = input.is_key_pressed(1)
            local cursor = renderer.get_cursor_pos() / ss

            local transformed_pos = pos * ss
            s.move_cursor = false
            s.hovered = (hover_fn(transformed_pos) or (s.dragging and pressed)) and draggable
            s.highlight_alpha = math.anim(s.highlight_alpha, (not pressed and s.hovered) and 255 or 0)
            local highlight_alpha = math.round(s.highlight_alpha)
            if pressed and not s.hovered and not s.dragging then
                drag.__blocked = true
            end
            if draggable and s.hovered and not drag.__blocked then
                if s.pointer then
                    drag.set_cursor(drag.move_cursor)
                end
                s.move_cursor = true
                if pressed or s.dragging then
                    s.dragging = true
                    pos = (cursor - s.old_cursor + pos):clamp(v2(0, 0), v2(1, 1))
                    s.pos.x:set_value(pos.x) s.pos.y:set_value(pos.y)
                end
            end
            if not pressed then
                s.dragging = false
                drag.__blocked = false
            end

            transformed_pos = pos * ss
            if draggable then
                s.old_cursor = cursor
            end
            return transformed_pos, function()
                if highlight_alpha > 0 and highlight then
                    highlight(transformed_pos, highlight_alpha)
                end
            end
        end, "drag_mt.run")
    }
}

local hooks = require("libs.hooks")
local hooked_setcursor = function (cursor)
    drag.original_cursor = cursor
    if drag.current_cursor then
        local result = set_cursor(drag.current_cursor)
        return result
    end
    return set_cursor(cursor)
end
drag.set_cursor = function(cursor)
    drag.current_cursor = cursor
end
set_cursor = hooks.jmp.new("HANDLE(__stdcall*)(HANDLE)", hooked_setcursor, SetCursor)
cbs.add("paint", errors.handle(function ()
    for _, elem in pairs(drag.__elements) do
        if elem.move_cursor and elem.pointer then
            return set_cursor(drag.move_cursor)
        end
    end
    if drag.current_cursor then
        local result = set_cursor(drag.current_cursor)
        drag.current_cursor = nil
        return result
    end
    return set_cursor(drag.original_cursor)
end, "drag.paint"))
cbs.add("unload", function ()
    set_cursor:stop()
end)

return drag