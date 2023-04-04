local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")
local element_t = require("includes.gui.element")

---@class gui_slider_t
---@field name string
---@field value boolean
---@field anims __anims_mt
---@field active boolean
---@field el slider_int_t|slider_float_t
---@field float boolean
---@field min number
---@field max number
---@field size vec2_t
---@field master_object? { el?: checkbox_t, fn: fun(): boolean }
local slider_t = { }

local slider_mt = {
    ---@class gui_slider_t
    __index = {
        ---@param s gui_slider_t
        ---@param pos vec2_t
        ---@param alpha number
        ---@param width number
        ---@param input_allowed boolean
        draw = errors.handle(function (s, pos, alpha, width, input_allowed)
            local value = s.el:get_value()
            local value_anim = s.anims.value(value)
            local value_str = s.float and string.format("%.1f", value) or tostring(value)
            local active_anim = s.anims.active()
            local hover_anim = s.anims.hover()
            local height = math.round((s.size.y) + math.round(s.anims.active() / 255 * 3) * 2)
            local size = v2(width, height)
            local from = pos + v2(0, s.size.y / 2 - size.y / 2)
            local to = from + v2(size.x, size.y)
            local progress = (value_anim - s.min) / (s.max - s.min)
            local progress_offset = v2(math.round(progress * width), 0)
            local clamped_x = math.max(from.x + progress_offset.x - 1, from.x + 1)

            if s.size.x == 0 then
                local max_width = 28 + render.text_size(fonts.menu, s.name).x
                local longest_value = math.max(math.abs(s.min), math.abs(s.max))
                local numbers_count = #tostring(longest_value)
                max_width = max_width + render.text_size(fonts.menu, string.rep("0", numbers_count)).x
                s.size.x = max_width
            end

            local border_color = col.magnolia_tinted:fade(col.magnolia, hover_anim / 255):alpha(alpha)
            local active_color = col.magnolia:alpha(alpha)


            --borders of slider progress
            renderer.rect_filled(v2(clamped_x, from.y), v2(to.x - 1, from.y + 1), border_color)
            renderer.rect_filled(v2(clamped_x, to.y - 1), v2(to.x - 1, to.y), border_color)

            --slider progress
            renderer.rect_filled(v2(from.x, from.y + 1), v2(from.x + progress_offset.x, to.y - 1), active_color)

            local left_color, right_color = col.magnolia:alpha(alpha), col.magnolia:alpha(alpha)

            if progress_offset.x > 0 then
                --top and bottom borders of slider progress
                renderer.rect_filled(v2(from.x + 1, from.y), v2(clamped_x, from.y + 1), active_color)
                renderer.rect_filled(v2(from.x + 1, to.y - 1), v2(clamped_x, to.y), active_color)
            else
                left_color = border_color
                --left slider progress border
                renderer.rect_filled(v2(from.x, from.y + 1), v2(from.x + 1, to.y - 1), border_color)
            end

            if progress_offset.x < width then
                right_color = border_color
                --slider background
                renderer.rect_filled(v2(math.max(from.x + progress_offset.x, from.x + 1), from.y + 1), to - v2(1, 1), col.gray:alpha(alpha))
                --right slider progress border
                renderer.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), border_color)
            end

            --antialias dots on each corner of the slider
            left_color = left_color:salpha(127)
            right_color = right_color:salpha(127)
            renderer.rect_filled(v2(from.x, from.y), v2(from.x + 1, from.y + 1), left_color)
            renderer.rect_filled(v2(to.x - 1, from.y), v2(to.x, from.y + 1), right_color)
            renderer.rect_filled(v2(from.x, to.y - 1), v2(from.x + 1, to.y), left_color)
            renderer.rect_filled(v2(to.x - 1, to.y - 1), v2(to.x, to.y), right_color)

            local text_padding_anim = math.round(1 * (active_anim / 255))
            local text_padding = v2(4 - text_padding_anim, 1 - text_padding_anim)

            local font_size = fonts.menu.size - (active_anim / 255 * 1.6)

            local outline_color = col.black:alpha(75)
            render.sized_text(function()
                render.outline_text(s.name, fonts.slider, from + text_padding, col.white:alpha(alpha), 0, outline_color)
                return render.outline_text(value_str, fonts.slider, v2(to.x, from.y) - v2(text_padding.x, -text_padding.y),
                col.white:alpha(alpha), render.flags.RIGHT_ALIGN, outline_color)
            end, fonts.slider, font_size)

            if active_anim > 0 then
                local color = col.white:alpha(alpha):salpha(active_anim)
                render.outline_text(tostring(s.min), fonts.slider_small, v2(from.x + 3, to.y - 10), color, 0, outline_color)
                render.outline_text(tostring(s.max), fonts.slider_small, v2(to.x - 3, to.y - 10), color, render.flags.RIGHT_ALIGN, outline_color)
            end

            local hovered = input_allowed and drag.hover_absolute(from, to)
            if hovered then
                drag.set_cursor(drag.horizontal_resize_cursor)
                drag.block()
            end
            local is_pressed = input.is_key_pressed(1)
            local active = (hovered and input.is_key_clicked(1)) or s.active
            s.anims.hover((active or hovered) and 255 or 0)
            s.anims.active(active and 255 or 0)

            if not is_pressed then
                s.active = false
                active = false
            end

            if active then
                drag.set_cursor(drag.horizontal_resize_cursor)
                drag.block()
                if not s.active then
                    click_effect.add()
                end
                s.active = true
                local mouse_pos = renderer.get_cursor_pos()
                local new_progress = (mouse_pos.x - from.x - 1) / (to.x - from.x - 2)
                local new_value = math.clamp(s.min + (s.max - s.min) * new_progress, s.min, s.max)
                if s.float then
                    new_value = math.round(new_value * 100) / 100
                end
                s.el:set_value(new_value)
            end
        end, "slider_t.draw"),
        master = element_t.master,
        padding = 6,
    },
}

slider_t.new = errors.handle(function (name, min, max, float, value)
    local path = gui.get_path(name)
    local c = setmetatable({
        name = name,
        default_value = value,
        el = float
            and ui.add_slider_float(path, path, min, max, value)
            or ui.add_slider_int(path, path, min, max, value),
        float = float or false,
        min = min,
        max = max,
        anims = anims.new({
            alpha = 255,
            hover = 0,
            active = 0,
            value = 0,
        }),
        active = false,
        size = v2(0, 18),
    }, slider_mt)
    c.el:set_visible(false)
    return c
end, "slider_t.new")
---@param name string
---@param min number
---@param max number
---@param float boolean
---@param value? number
---@return gui_checkbox_t
gui.slider = function(name, min, max, float, value)
    return gui.add_element(slider_t.new(name, min, max, float, value))
end