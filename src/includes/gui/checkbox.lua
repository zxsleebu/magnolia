local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")

---@class gui_checkbox_t
---@field name string
---@field value boolean
---@field anims __anims_mt
---@field draw fun(s: gui_checkbox_t, pos: vec2_t, alpha: number, width: number, input_allowed: boolean)
---@field inline gui_options_t
---@field el checkbox_t
---@field size vec2_t
local checkbox_t = { }

local checkbox_mt = {
    __index = {
        ---@param s gui_checkbox_t
        ---@param pos vec2_t
        draw = errors.handle(function (s, pos, alpha, width, input_allowed)
            -- renderer.rect(pos, pos + v2(width, s.size.y), col.white:alpha(alpha))
            local text_size = render.text_size(fonts.menu, s.name)
            local size = v2(18, 18)
            local text_padding = 8
            local hover_to = pos + size + v2(text_size.x + text_padding + 2, 0)
            local hovered = input_allowed and drag.hover_absolute(pos, hover_to)
            render.text(s.name, fonts.menu, pos + v2(size.x + text_padding + 1, 2), col.black:alpha(alpha))
            render.text(s.name, fonts.menu, pos + v2(size.x + text_padding, 1), col.white:alpha(alpha))
            local value = s.el:get_value()
            local hover_anim, active_anim
            if hovered then
                if input.is_key_clicked(1) then
                    drag.block()
                    click_effect.add()
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
            render.smoothed_rect(pos, pos + size, col.magnolia_tinted:fade(col.magnolia, hover_anim / 255):alpha(alpha), false)
            local check_pos = pos - v2(0, 0)
            renderer.line(check_pos + v2(5, size.y / 2), check_pos + v2(size.x / 2, size.y / 2 + 3), col.gray:alpha(alpha):salpha(active_anim))
            -- renderer.line(check_pos + v2(5, size.y / 2 + 1), check_pos + v2(size.x / 2, size.y / 2 + 4), col.gray:alpha(alpha):salpha(active_anim))
            renderer.line(check_pos + v2(size.x / 2 - 1, size.y / 2 + 3), check_pos + v2(size.x - 5, 5), col.gray:alpha(alpha):salpha(active_anim))
            -- renderer.line(check_pos + v2(size.x / 2, size.y / 2 + 3), check_pos + v2(size.x - 4, 4), col.gray:alpha(alpha):salpha(active_anim))
            if s.inline and s.inline.inline_draw then
                local i = s.inline
                local inline_alpha = i.anims.enabled()
                if value then
                    inline_alpha = i.anims.enabled(255)
                else
                    inline_alpha = i.anims.enabled(0)
                end
                i:inline_draw(pos + v2(width - i.size.x, size.y / 2), alpha * inline_alpha / 255, input_allowed)
            end
            if s.size.x == 0 then
                s.size.x = hover_to.x - pos.x
                if s.inline then
                    s.size.x = s.size.x + s.inline.size.x + 6
                end
            end
        end, "checkbox_t.draw"),
    }
}
checkbox_t.new = errors.handle(function (name, value)
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
        size = v2(0, 24),
    }, checkbox_mt)
    c.el:set_visible(false)
    return c
end, "checkbox_t.new")
gui.checkbox = function(name, value)
    return gui.add_element(checkbox_t.new(name, value))
end