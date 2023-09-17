local irender = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")
local element_t = require("includes.gui.element")
local inline_t = require("includes.gui.inline")
local colors = require("includes.colors")
local cbs = require("libs.callbacks")
local options_t = require("includes.gui.options")
local bind_t = require("includes.gui.bind")

local checkbox_t = { }

---@class gui_checkbox_t : gui_element_class
---@field inline gui_options_t[]
---@field el check_box_t
---@field old_value boolean
---@field default_value boolean
---@field callbacks table<string, fun()>
local checkbox_mt = {
    master = element_t.master,
    options = options_t.new,
    bind = bind_t.new,
}
---@param self gui_checkbox_t
---@param pos vec2_t
---@param alpha number
---@param width number
---@param input_allowed boolean
checkbox_mt.draw = errors.handler(function (self, pos, alpha, width, input_allowed)
    -- render.rect(pos, pos + v2(width, s.size.y), col.white:alpha(alpha))
    local text_size = irender.text_size(fonts.menu, self.name)
    local size = v2(18, 18)
    local text_padding = 8
    local hover_to = pos + size + v2(text_size.x + text_padding + 2, 0)
    local hovered = input_allowed and drag.hover_absolute(pos, hover_to)
    irender.text(self.name, fonts.menu, pos + v2(size.x + text_padding + 1, 2), col.black:alpha(alpha))
    irender.text(self.name, fonts.menu, pos + v2(size.x + text_padding, 1), col.white:alpha(alpha))
    local value = self:value()
    local hover_anim, active_anim
    if hovered then
        if input.is_key_clicked(1) then
            gui.drag:block()
            click_effect.add()
            value = self:value(not value)
        end
        drag.set_cursor(drag.hand_cursor)
    end
    hover_anim = self.anims.hover((hovered or value) and 255 or 0 )
    active_anim = self.anims.active(value and 255 or 0)
    render.rect_filled(pos + v2(1, 1), pos + size - v2(1, 1), col.gray:fade(colors.magnolia, active_anim / 255):alpha(alpha))
    render.rect(pos, pos + size, colors.magnolia_tinted:fade(colors.magnolia, hover_anim / 255):alpha(alpha), 1)
    self:draw_checkmark(pos, alpha * (active_anim / 255))
    inline_t.draw(self, pos, alpha, width, input_allowed)
    if self.size.x == 0 then
        self.size.x = hover_to.x - pos.x + inline_t.calculate_size(self)
    end
end, "checkbox_t.draw")
---@param fn fun(cmd: user_cmd_t, el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.create_move = function (self, fn)
    cbs.create_move(function (cmd)
        if self:value() then fn(cmd, self) end
    end, self.name .. ".create_move")
    return self
end
---@param fn fun(el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.paint = function (self, fn)
    cbs.paint(function ()
        if self:value() then fn(self) end
    end, self.name .. ".paint")
    return self
end
---@param fn fun(event: game_event_t, el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.callback = function (self, event_name, fn)
    cbs.event(event_name, function (event)
        if self:value() then fn(event, self) end
    end, self.name .. "." .. event_name)
    return self
end
---@param fn fun(el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.update = function (self, fn)
    cbs.paint(function ()
        local value = self:value()
        if value ~= self.old_value then
            fn(self)
        end
        self.old_value = value
    end, self.name .. ".update")
    cbs.unload(function ()
        self:value(false)
        fn(self)
    end, self.name .. ".update")
    return self
end
---@param self gui_checkbox_t 
---@param pos vec2_t
---@param alpha number
checkbox_mt.draw_checkmark = errors.handler(function (self, pos, alpha)
    local color = col.gray:alpha(alpha)
    local size = v2(18, 18)
    local anim = self.anims.active()
    do
        local start_pos = pos + v2(5, size.y / 2)
        local difference = pos + v2(size.x / 2, size.y / 2 + 3) - start_pos
        render.line(start_pos, start_pos + difference * math.clamp(anim * 2, 0, 255) / 255, color)
    end
    do
        local start_pos = pos + v2(size.x / 2 - 1, size.y / 2 + 3)
        local difference = pos + v2(size.x - 5, 5) - start_pos
        render.line(start_pos, start_pos + difference * math.clamp(anim * 2 - 255, 0, 255) / 255, color)
    end
end, "checkbox_t.draw_checkmark")
---@param new_value? boolean
---@return boolean
checkbox_mt.value = function (self, new_value)
    if new_value ~= nil then
        self.el:set(new_value)
    end
    local value = self.el:get()
    if not value then return false end
    if self.master_object and self.master_object.el then
        return self.master_object.el:get()
    end
    if self.options_element then
        return self.options_element:value()
    end
    return value
end
checkbox_t.new = errors.handler(function (name, value)
    local path = gui.get_path(name)
    local c = setmetatable({
        name = name,
        default_value = value or false,
        el = menu.add_check_box(path, "magnolia", value or false),
        anims = anims.new({
            alpha = 255,
            hover = 0,
            active = 0,
        }),
        inline = {},
        size = v2(0, 18),
        old_value = value or false,
    }, { __index = checkbox_mt })
    -- c.el:set_visible(false)
    return c
end, "checkbox_t.new")
---@param name string
---@param value? boolean
---@return gui_checkbox_t
gui.checkbox = function(name, value)
    return gui.add_element(checkbox_t.new(name, value))
end