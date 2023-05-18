local v2 = require("libs.vectors")()
local col = require("libs.colors")
local render = require("libs.render")
local fonts = require("includes.gui.fonts")
local anims = require("libs.anims")
local drag = require("libs.drag")
local errors = require("libs.error_handler")
local input = require("libs.input")
local container_t = require("includes.gui.container")
local column_t = require("includes.gui.column")
local click_effect = require("includes.gui.click_effect")

local options_t = {}

---@class gui_options_t
---@field anims __anims_mt
---@field columns gui_column_t[]
---@field pos vec2_t
---@field open boolean
---@field parent gui_checkbox_t
local options_mt = {
    size = v2(18, 18),
}

---@param self gui_options_t
---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
options_mt.inline_draw = errors.handle(function(self, pos, alpha, input_allowed)
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
                self.pos = renderer.get_cursor_pos()
            end
            self.open = true
        end
    end
end, "options_mt.inline_draw")
---@param self gui_options_t
---@param alpha number
options_mt.draw = errors.handle(function(self, alpha)
    local alpha_anim = self.anims.alpha()
    local open_alpha = alpha_anim * (alpha / 255)
    if open_alpha > 0 then
        local input_allowed = self.open
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

        local to = self.pos + size
        --if unfocused then
        if input_allowed and alpha_anim > 127 and not drag.hover_absolute(self.pos, to) and input.is_key_clicked(1) then
            self.open = false
        end

        container_t.draw_background(self.pos, to, open_alpha, 253)

        if self.columns then
            local add_pos = v2(gui.paddings.options_container_padding + 1, gui.paddings.options_container_padding + 1)
            for i = 1, #self.columns do
                local column = self.columns[i]
                container_t.draw_elements(column.elements, self.pos + add_pos, math.round(column.size.x), open_alpha, input_allowed)

                --!DEBUG
                -- renderer.rect(s.pos + add_pos, s.pos + add_pos + column.size, col.black:alpha(open_alpha))
                --!DEBUG

                add_pos.x = column.size.x + add_pos.x + gui.paddings.options_container_padding
            end
        end
    end
end, "options_mt.draw")
---@param fn fun(cmd: usercmd_t, el: gui_options_t)
---@return gui_options_t
options_mt.create_move = function (self, fn)
    client.register_callback("create_move", errors.handle(function (cmd)
        if self.parent:value() then fn(cmd, self) end
    end, self.parent.name .. ".create_move"))
    return self
end
---@param fn fun(el: gui_options_t)
---@return gui_options_t
options_mt.paint = function (self, fn)
    client.register_callback("paint", errors.handle(function()
        if self.parent:value() then fn(self) end
    end, self.parent.name .. ".paint"))
    return self
end

options_mt.value = function (self)
    return self.parent:value()
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
---@return gui_slider_t
options_mt.get_slider = function (self, name)
    ---@diagnostic disable-next-line: return-type-mismatch
    return self:__get(name)
end

---@param element gui_element_t
---@param options fun()
---@return gui_options_t
options_t.new = errors.handle(function (element, options)
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
    options()
    gui.current_options = old_options
    return t
end, "options_t.new")

---comment
---@param columns gui_column_t[]
---@param alpha any
options_t.draw_columns = function(columns, alpha)
    for _, column in pairs(columns) do
        for _, element in pairs(column.elements) do
            for i = 1, #(element.inline or {}) do
                local inline = element.inline[i]
                if inline.columns then
                    inline:draw(alpha)
                    options_t.draw_columns(inline.columns, alpha)
                end
            end
        end
    end
end

options_t.draw = errors.handle(function()
    local alpha = gui.anims.main_alpha()
    for _, tab in pairs(gui.elements) do
        local tab_alpha = tab.anims.alpha() * (alpha / 255)
        for _, subtab in pairs(tab.subtabs) do
            local subtab_alpha = subtab.anims.alpha() * (tab_alpha / 255)
            options_t.draw_columns(subtab.columns, subtab_alpha)
        end
    end
end, "options_t.draw")

gui.options = options_t.new

return options_t