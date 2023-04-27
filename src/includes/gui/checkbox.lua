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

local checkbox_t = { }

---@class gui_checkbox_t
---@field name string
---@field path string
---@field anims __anims_mt
---@field inline gui_options_t
---@field el checkbox_t
---@field size vec2_t
---@field master_object? { el?: checkbox_t, fn: fun(): boolean }
---@field callbacks table<string, fun()>
local checkbox_mt = {
    master = element_t.master,
    padding = 6,
}
---@param self gui_checkbox_t
---@param pos vec2_t
---@param alpha number
---@param width number
---@param input_allowed boolean
checkbox_mt.draw = errors.handle(function (self, pos, alpha, width, input_allowed)
    -- renderer.rect(pos, pos + v2(width, s.size.y), col.white:alpha(alpha))
    local text_size = render.text_size(fonts.menu, self.name)
    local size = v2(18, 18)
    local text_padding = 8
    local hover_to = pos + size + v2(text_size.x + text_padding + 2, 0)
    local hovered = input_allowed and drag.hover_absolute(pos, hover_to)
    render.text(self.name, fonts.menu, pos + v2(size.x + text_padding + 1, 2), col.black:alpha(alpha))
    render.text(self.name, fonts.menu, pos + v2(size.x + text_padding, 1), col.white:alpha(alpha))
    local value = self:value()
    local hover_anim, active_anim
    if hovered then
        if input.is_key_clicked(1) then
            drag.block()
            click_effect.add()
            value = self.el:set_value(not value)
        end
        drag.set_cursor(drag.hand_cursor)
    end
    hover_anim = self.anims.hover((hovered or value) and 255 or 0 )
    active_anim = self.anims.active(value and 255 or 0)
    renderer.rect_filled(pos + v2(1, 1), pos + size - v2(1, 1), col.gray:fade(col.magnolia, active_anim / 255):alpha(alpha))
    render.smoothed_rect(pos, pos + size, col.magnolia_tinted:fade(col.magnolia, hover_anim / 255):alpha(alpha), false)
    self:draw_checkmark(pos, alpha * (active_anim / 255))
    if self.inline and self.inline.inline_draw then
        local i = self.inline
        local inline_alpha = i.anims.enabled(value and 255 or 0)
        if inline_alpha > 0 then
            i:inline_draw(pos + v2(width - i.size.x, size.y / 2), alpha * inline_alpha / 255, input_allowed and value)
        end
    end
    if self.size.x == 0 then
        self.size.x = hover_to.x - pos.x
        if self.inline then
            self.size.x = self.size.x + self.inline.size.x + gui.paddings.options_padding
        end
    end
end, "checkbox_t.draw")
---@param fn fun(cmd: usercmd_t, el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.create_move = function (self, fn)
    client.register_callback("create_move", errors.handle(function (cmd)
        if self:value() then fn(cmd, self) end
    end, self.name .. ".create_move"))
    return self
end
---@param fn fun(el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.paint = function (self, fn)
    client.register_callback("paint", errors.handle(function()
        if self:value() then fn(self) end
    end, self.name .. ".paint"))
    return self
end
---@param fn fun(event: game_event_t, el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.callback = function (self, event_name, fn)
    client.register_callback(event_name, errors.handle(function(event)
        if self:value() then fn(event, self) end
    end, self.name .. "." .. event_name))
    return self
end
---@param self gui_checkbox_t 
---@param pos vec2_t
---@param alpha number
checkbox_mt.draw_checkmark = errors.handle(function (self, pos, alpha)
    local color = col.gray:alpha(alpha)
    local size = v2(18, 18)
    local anim = self.anims.active()
    do
        local start_pos = pos + v2(5, size.y / 2)
        local difference = pos + v2(size.x / 2, size.y / 2 + 3) - start_pos
        renderer.line(start_pos, start_pos + difference * math.clamp(anim * 2, 0, 255) / 255, color)
    end
    do
        local start_pos = pos + v2(size.x / 2 - 1, size.y / 2 + 3)
        local difference = pos + v2(size.x - 5, 5) - start_pos
        renderer.line(start_pos, start_pos + difference * math.clamp(anim * 2 - 255, 0, 255) / 255, color)
    end
end, "checkbox_t.draw_checkmark")
checkbox_mt.value = function (self)
    return self.el:get_value()
end
checkbox_t.new = errors.handle(function (name, value)
    local path = gui.get_path(name)
    local c = setmetatable({
        name = name,
        el = ui.add_check_box(path, path, value or false),
        anims = anims.new({
            alpha = 255,
            hover = 0,
            active = 0,
        }),
        size = v2(0, 18),
    }, { __index = checkbox_mt })
    c.el:set_visible(false)
    return c
end, "checkbox_t.new")
---@param name string
---@param value? boolean
---@return gui_checkbox_t
gui.checkbox = function(name, value)
    return gui.add_element(checkbox_t.new(name, value))
end