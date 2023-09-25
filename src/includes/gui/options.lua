local v2 = require("libs.vectors")()
local col = require("libs.colors")
local render = require("libs.render")
local fonts = require("includes.gui.fonts")
local anims = require("libs.anims")
local drag = require("libs.drag")
local errors = require("libs.error_handler")
local input = require("libs.input")
local column_t = require("includes.gui.column")
local click_effect = require("includes.gui.click_effect")
local cbs = require("libs.callbacks")
local bind_t = require("includes.gui.bind")
local security = require("includes.security")

local options_t = {}

---@class gui_options_t
---@field anims __anims_mt
---@field columns gui_column_t[]
---@field pos vec2_t
---@field open boolean
---@field parent gui_checkbox_t
---@field master fun(self: gui_options_t, fn_or_func: gui_checkbox_t|fun(): boolean): gui_options_t
local options_mt = {
    size = v2(18, 18),
    ---@param self gui_options_t
    master = function(self, fn_or_func)
        return self.parent:master(fn_or_func)
    end,
    bind = bind_t.new,
}

---@param self gui_options_t
---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
options_mt.inline_draw = errors.handler(function(self, pos, alpha, input_allowed)
    local _, text_size = render.sized_text(function ()
        return render.text("E", fonts.menu_icons, pos - v2(2, 1), col.white:alpha(alpha):salpha(self.anims.hover()), render.flags.TEXT_SIZE)
    end, fonts.menu_icons, 19)
    ---@cast text_size vec2_t
    local hovered = input_allowed and drag.hover_absolute(pos - v2(0, 1), pos + text_size + v2(0, 2))
    self.anims.hover((hovered or self.open) and 255 or 100)
    self.anims.alpha(self.open and 255 or 0)
    if hovered then
        drag.set_cursor(drag.hand_cursor)
        if input.is_key_clicked(1) then
            click_effect.add()
            if not self.open then
                self.pos = input.cursor_pos()
            end
            self.open = true
        end
    end
end, "options_mt.inline_draw")
local container_t
---@param self gui_options_t
---@param alpha number
options_mt.draw = errors.handler(function(self, alpha)
    if not container_t then
        container_t = require("includes.gui.container")
    end
    local alpha_anim = self.anims.alpha()
    local open_alpha = alpha_anim * (alpha / 255)
    if open_alpha > 0 then
        local input_allowed = self.open and not gui.is_another_dragging()
        local size = v2((#self.columns + 1) * gui.paddings.options_container_padding, 0)
        if self.columns then
            for _, column in pairs(self.columns) do
                local col_size = column:get_size()
                if col_size.x < 100 then
                    col_size.x = 100
                end
                size.x = size.x + col_size.x
                if col_size.y > size.y then
                    size.y = col_size.y
                end
                for _, element in pairs(column.elements) do
                    if element.size.x == 0 then
                        --*HACK: this is a hack to make the options menu wait for the element to calculate its size before drawing it
                        open_alpha = 0.01
                    end
                end
                input_allowed = input_allowed and column:input_allowed()
            end
        end
        size = v2(size.x + 1, gui.paddings.options_container_padding * 2 + size.y + 1)

        local pos = self.pos - v2(size.x / 2, 0)
        local to = pos + size

        local hovered = drag.hover_absolute(pos, to)
        if hovered and alpha_anim > 127 then
            gui.hovered = true
        end
        if input_allowed and alpha_anim > 127 and not hovered and input.is_key_clicked(1) then
            self.open = false
        end

        container_t.draw_background(pos, to, open_alpha, 253)

        if self.columns then
            local add_pos = v2(gui.paddings.options_container_padding + 1, gui.paddings.options_container_padding + 1)
            for i = 1, #self.columns do
                local column = self.columns[i]
                container_t.draw_elements(column.elements, pos + add_pos, math.round(column.size.x), open_alpha, input_allowed)

                --!DEBUG
                -- renderer.rect(s.pos + add_pos, s.pos + add_pos + column.size, col.black:alpha(open_alpha))
                --!DEBUG

                add_pos.x = column.size.x + add_pos.x + gui.paddings.options_container_padding
            end
        end
    end
end, "options_mt.draw")
---@param fn fun(cmd: user_cmd_t, el: gui_options_t)
---@return gui_options_t
options_mt.create_move = function (self, fn)
    cbs.create_move(function(cmd)
        if self.parent.value and self.parent:value() or not self.parent.value then fn(cmd, self) end
    end, self.parent.name .. ".create_move")
    return self
end
---@param fn fun(el: gui_options_t)
---@return gui_options_t
options_mt.paint = function (self, fn)
    cbs.paint(function()
        if self.parent.value and self.parent:value() or not self.parent.value then fn(self) end
    end, self.parent.name .. ".paint")
    return self
end
---@param fn fun(el: gui_options_t)
---@return gui_options_t
options_mt.update = function (self, fn)
    cbs.paint(function ()
        local value = self.parent:value()
        if value ~= self.parent.old_value then
            fn(self)
        end
        self.parent.old_value = value
    end, self.parent.name .. ".update")
    cbs.unload(function ()
        self.parent:value(false)
        fn(self)
    end, self.parent.name .. ".update")
    return self
end

---@param self gui_options_t
---@param new_value? boolean
---@return boolean
options_mt.value = function (self, new_value)
    if not security.authorized then return false end
    if not self.parent.el then return true end
    return self.parent:value(new_value)
end

---@param self gui_options_t
---@param name string
---@return gui_element_t?
options_mt.__get = function (self, name)
    for _, column in pairs(self.columns) do
        for _, element in pairs(column.elements) do
            if element.name == name then
                return element
            end
        end
    end
    error("couldn't find element with name '" .. name .. "'")
end
---@param name string
---@return gui_checkbox_t
options_mt.get_checkbox = function (self, name)
    ---@diagnostic disable-next-line: return-type-mismatch
    return self:__get(name)
end
---@param name string
---@return gui_options_t?
options_mt.get_options = function (self, name)
    local el = self:__get(name)
    if not el then return end
    for i = 1, #el.inline do
        if el.inline[i].parent then
            return el.inline[i]
        end
    end
    ---@diagnostic disable-next-line: return-type-mismatch
end
---@param name string
---@return gui_slider_t
options_mt.get_slider = function (self, name)
    ---@diagnostic disable-next-line: return-type-mismatch
    return self:__get(name)
end
---@param name string
---@return gui_dropdown_t
options_mt.get_dropdown = function (self, name)
    ---@diagnostic disable-next-line: return-type-mismatch
    return self:__get(name)
end

---@param element gui_checkbox_t|gui_label_t 
---@param options fun(el: gui_options_t)
---@return gui_options_t
options_t.new = errors.handler(function (element, options)
    local t = setmetatable({
        parent = element,
        columns = {
            column_t.new(),
        },
        anims = anims.new({
            hover = 100,
            enabled = 0,
            alpha = 0,
        }),
        path = gui.get_path(element.name),
        pos = v2(0, 0),
        open = false,
    }, { __index = options_mt })
    element.inline[#element.inline+1] = t
    local old_options = gui.current_options
    gui.current_options = t
    options(t)
    gui.current_options = old_options
    return t
end, "options_t.new")

return options_t