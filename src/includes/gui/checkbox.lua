local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")

---@class gui_checkbox_t
---@field name string
---@field value boolean
---@field anims __anims_mt
---@field draw fun(s: gui_checkbox_t, pos: vec2_t, alpha: number, input_allowed: boolean)
---@field el checkbox_t
---@field size vec2_t
local checkbox_t = { }

local checkbox_mt = {
    __index = {
        ---@param s gui_checkbox_t
        ---@param pos vec2_t
        draw = errors.handle(function (s, pos, alpha, input_allowed)
            local text_size = render.text_size(fonts.menu, s.name)
            local size = v2(16, 16)
            local text_padding = 8
            local hovered = drag.hover(pos, pos + size + v2(text_size.x + text_padding + 2, 0)) and input_allowed
            render.text(s.name, fonts.menu, pos + v2(size.x + text_padding + 1, 0), col.black:alpha(alpha))
            render.text(s.name, fonts.menu, pos + v2(size.x + text_padding, -1), col.white:alpha(alpha))
            local value = s.el:get_value()
            local hover_anim, active_anim
            if hovered then
                if input.is_key_clicked(1) then
                    value = s.el:set_value(not value)
                end
                drag.set_cursor(drag.hand_cursor)
            end
            if hovered or value then
                hover_anim = s.anims.hover(255)
            else
                hover_anim = s.anims.hover(0)
            end
            active_anim = s.anims.active(value and 255 or 0)
            renderer.rect_filled(pos + v2(1, 1), pos + size - v2(1, 1), col.gray:fade(col.magnolia, active_anim / 255):alpha(alpha))
            render.smoothed_rect(pos, pos + size, col.gray:fade(col.magnolia, hover_anim / 255):alpha(alpha), false)
            local check_pos = pos - v2(0, 0)
            renderer.line(check_pos + v2(5, size.y / 2), check_pos + v2(size.x / 2, size.y / 2 + 3), col.gray:alpha(alpha):salpha(active_anim))
            -- renderer.line(check_pos + v2(5, size.y / 2 + 1), check_pos + v2(size.x / 2, size.y / 2 + 4), col.gray:alpha(alpha):salpha(active_anim))
            renderer.line(check_pos + v2(size.x / 2 - 1, size.y / 2 + 3), check_pos + v2(size.x - 5, 5), col.gray:alpha(alpha):salpha(active_anim))
            -- renderer.line(check_pos + v2(size.x / 2, size.y / 2 + 3), check_pos + v2(size.x - 4, 4), col.gray:alpha(alpha):salpha(active_anim))
        end, "checkbox_t.draw")
    }
}
checkbox_t.new = function (name, value)
    local path = gui.get_path(name)
    local c = setmetatable({
        name = name,
        value = value,
        el = ui.add_check_box(path, path, value or false),
        anims = anims.new({
            alpha = 0,
            hover = 0,
            active = 0,
        }),
        size = v2(18, 26),
    }, checkbox_mt)
    c.el:set_visible(false)
    return c
end
gui.checkbox = function(name, value)
    return gui.add_element(checkbox_t.new(name, value))
end