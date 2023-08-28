local v2 = require("libs.vectors")()
local irender = require("libs.render")
local col = require("libs.colors")
require("libs.advanced math")
local modules = require("libs.modules")
local user32 = ffi.load('user32')
require("libs.types")
ffi.cdef[[
    typedef void* HANDLE;
    HANDLE LoadCursorA(HANDLE, PCSTR);
    HANDLE SetCursor(HANDLE);
    HANDLE FindWindowA(PCSTR, PCSTR);
    long SetWindowLongA(HANDLE, int, long);
    long CallWindowProcW(long, HANDLE, UINT, UINT, long);
    long GetWindowLongA(HANDLE, int);
]]
local SetCursor = modules.get_function("HANDLE(__stdcall*)(HANDLE)", "user32", "SetCursor")
local ss = render.screen_size()
local input = require("libs.input")
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local drag = {
    ---@type table<string, draggable_t>
    __elements = {},
    __blocked = false,
    ---@param to_pos? vec2_t
    is_hovered = function(pos, size, to_pos)
        local cursor = input.cursor_pos()
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
        irender.rounded_rect(from:round() - v2(3, 3), to:round() + v2(2, 2), col(200, 200, 200, alpha / 3), 3)
        local shine = col.white:alpha(alpha / 25)
        local trans = col.white:alpha(0)

        render.rect_filled_fade(from, from + size / 2, trans, trans, shine, trans)
        render.rect_filled_fade(from + size / 2, to, shine, trans, trans, trans)
        render.rect_filled_fade(v2(from.x + size.x / 2, from.y), from + v2(size.x, size.y / 2), trans, trans, trans, shine)
        render.rect_filled_fade(v2(from.x, from.y + size.y / 2), from + v2(size.x / 2, size.y), trans, shine, trans, trans)
    end,
    current_cursor = nil,
}
drag.arrow_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32512))
drag.move_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32646))
drag.hand_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32649))
drag.horizontal_resize_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32644))
drag.new = errors.handler(function(key, default_pos, pointer)
    if pointer == nil then pointer = true end
    drag.__elements[key] = {
        pos = {
            x = menu.add_slider_float(key .. "__x", "magnolia_drag", 0, 1, default_pos.x),
            y = menu.add_slider_float(key .. "__y", "magnolia_drag", 0, 1, default_pos.y),
        },
        hovered = false,
        key = key,
        highlight_alpha = 0,
        old_cursor = input.cursor_pos() / render.screen_size(),
        dragging = false,
        move_cursor = false,
        pointer = pointer
    }
    -- drag.__elements[key].pos.x:set_visible(false)
    -- drag.__elements[key].pos.y:set_visible(false)
    return setmetatable(drag.__elements[key], drag.mt)
end, "drag.new")

drag.is_menu_hovered = function()
    local rect = menu.get_menu_rect()
    return drag.is_hovered(v2(rect.x - 5, rect.y - 5), v2(rect.z - rect.x + 5, rect.w - rect.y + 5))
end
---@param from vec2_t
---@param to vec2_t
drag.hover_absolute = function(from, to)
    return drag.is_hovered(from, nil, to)
        and not (drag.is_menu_hovered() and menu.is_visible())
end
---@param size vec2_t
---@param center_x? boolean
drag.hover_fn = function(size, center_x, center_y)
    return function(pos)
        return drag.is_hovered(v2(center_x and pos.x - size.x / 2 or pos.x, center_y and pos.y - size.y / 2 or pos.y) or pos, size)
            and not (drag.is_menu_hovered() and menu.is_visible())
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
    ---@field highlight_alpha number
    ---@field old_cursor vec2_t
    ---@field pointer boolean
    __index = {
        ---@param s draggable_t
        ---@param hover_fn fun(pos: vec2_t): boolean
        ---@param highlight? fun(pos: vec2_t, alpha: number)
        ---@return vec2_t, fun()
        run = errors.handler(function(s, hover_fn, highlight)
            local draggable = menu.is_visible()
            for _, elem in pairs(drag.__elements) do
                if draggable and elem.dragging and elem.key ~= s.key then
                    draggable = false
                end
            end
            local pos = v2(s.pos.x:get(), s.pos.y:get()):clamp(v2(0, 0), v2(1, 1))
            local pressed = input.is_key_pressed(1)
            local cursor = input.cursor_pos() / ss

            local transformed_pos = pos * ss
            s.move_cursor = false
            s.hovered = (hover_fn(transformed_pos) or (s.dragging and pressed)) and draggable
            s.highlight_alpha = math.anim(s.highlight_alpha, (not pressed and s.hovered) and 255 or 0)
            local highlight_alpha = math.round(s.highlight_alpha)
            if draggable and s.hovered and not ((s.blocked or drag.__blocked) and not s.dragging) and not (s.key ~= "magnolia" and gui.hovered and not s.dragging) then
                if s.pointer then
                    drag.set_cursor(drag.move_cursor)
                end
                s.move_cursor = true
                if pressed or s.dragging then
                    s.dragging = true
                    pos = (cursor - s.old_cursor + pos):clamp(v2(0, 0), v2(1, 1))
                    s.pos.x:set(pos.x) s.pos.y:set(pos.y)
                end
            end
            if pressed and (not s.hovered and not s.dragging) then
                s.blocked = true
            end
            if not pressed then
                s.blocked = false
                s.dragging = false
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
        end, "drag_mt.run"),
        block = function(s)
            s.blocked = true
        end,
    }
}

local set_cursor
local hooks = require("libs.hooks")
local hooked_setcursor = function (original, cursor)
    if drag.current_cursor and menu.is_visible() then
        return original(drag.current_cursor)
    end
    return original(cursor)
end
drag.set_cursor = function(cursor)
    drag.current_cursor = cursor
end
set_cursor = hooks.jmp2.new("HANDLE(__stdcall*)(HANDLE)", hooked_setcursor, SetCursor)
cbs.paint(function ()
    drag.current_cursor = nil
end, "drag.paint")
-- local game_window = user32.FindWindowA("Valve001", nil)
-- local old_wndproc = user32.GetWindowLongA(game_window, -4)
-- local original_wndproc
-- local new_wndproc = function(hwnd, msg, param, lparam)
--     if msg == 0x0200 and menu.is_visible() then
--         for _, elem in pairs(drag.__elements) do
--             if elem.move_cursor and elem.pointer then
--                 user32.SetCursor(drag.move_cursor)
--             end
--         end
--         if drag.current_cursor then
--             user32.SetCursor(drag.current_cursor)
--             -- drag.current_cursor = nil
--         end
--     end
--     return user32.CallWindowProcW(original_wndproc, hwnd, msg, param, lparam)
-- end

-- original_wndproc = user32.SetWindowLongA(game_window, -4, ffi.cast("long", ffi.cast("long(__stdcall*)(HANDLE, UINT, UINT, long)", new_wndproc)))
-- print(("Original: 0x%X"):format(tonumber(original_wndproc)))
-- print(("Old: 0x%X"):format(tonumber(old_wndproc)))
cbs.add("unload", function ()
    if not set_cursor then return end
    set_cursor:unhook()
    -- user32.SetWindowLongA(game_window, -4, old_wndproc)
end)

return drag