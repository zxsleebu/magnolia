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
local colors = require("includes.colors")
local cbs = require("libs.callbacks")


---@class gui_dropdown_t : gui_element_class
---@field el multi_combo_box_t|combo_box_t
---@field old_value number
---@field multi boolean
---@field open boolean
---@field pos vec2_t
---@field width number
---@field values string[]
---@field values_data { anims: __anims_mt, text_size: vec2_t }[]
local dropdown_mt = {
    master = element_t.master,
}

local trim_last_space = function(str)
    if str:sub(-1) == " " then
        str = str:sub(1, -2)
    end
    return str
end

---@param self gui_dropdown_t
---@param alpha number
---@param width number
---@param input_allowed boolean
dropdown_mt.draw = errors.handler(function(self, pos, alpha, width, input_allowed)
    local size = v2(width, 32)
    local from = pos + v2(0, self.size.y - size.y)
    local to = from + v2(size.x, size.y)
    render.rect_filled(from + v2(1, 1), to - v2(1, 1), col.gray:alpha(alpha))
    self.width = width
    do
        -- local text_padding = 10
        -- local text_pos, text_size = render.text(self.name, fonts.menu_small, pos + v2(text_padding + 1, -1), col.black:alpha(alpha), render.flags.TEXT_SIZE)
        -- -@cast text_size vec2_t
        -- render.text(self.name, fonts.menu_small, text_pos - v2(1, 1), col.white:alpha(alpha))
        -- local border_color = colors.magnolia_tinted:alpha(alpha) --:fade(colors.magnolia, hover_anim / 255)
        -- renderer.rect_filled(from + v2(1, 0), v2(text_pos.x - 4, from.y + 1), border_color)
        -- renderer.rect_filled(v2(text_pos.x + text_size.x + 3, from.y), v2(to.x - 1, from.y + 1), border_color)
        -- renderer.rect_filled(from + v2(0, 1), v2(from.x + 1, to.y - 1), border_color)
        -- renderer.rect_filled(v2(from.x + 1, to.y - 1), to - v2(1, 0), border_color)
        -- renderer.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), border_color)
    end
    local hovered = input_allowed and drag.hover_absolute(from, to)
    local hover_anim = self.anims.hover((hovered or self.open) and 255 or 0)
    self.pos = pos
    self.anims.active(self.open and 255 or 0)
    if hovered then
        if input.is_key_clicked(1) then
            gui.drag:block()
            click_effect.add()
            self.open = true
        end
        drag.set_cursor(drag.hand_cursor)
    end
    if hovered or self.open and not self.multi then
        local el = self.el ---@type combo_box_t
        local can_fast_scroll = globals.frame_count % 7 == 0
        local down_arrow = input.is_key_clicked(40) or (input.get_key_pressed_time(40) > 0.3 and can_fast_scroll)
        local up_arrow = not down_arrow and (input.is_key_clicked(38) or (input.get_key_pressed_time(38) > 0.3 and can_fast_scroll))
        if down_arrow or up_arrow then
            --increase or decrease the index
            el:set(math.clamp(el:get() + (down_arrow and 1 or -1), 0, #self.values - 1))
        end
    end
    do
        local text_pos = pos + v2(5, 3)
        local border_color = colors.magnolia_tinted:fade(colors.magnolia, hover_anim / 255):alpha(alpha)
        render.rect(from, to, border_color, 1)
        -- render.text(self.name, fonts.menu_small, text_pos + v2(1, 1), col.black:alpha(alpha))
        irender.text(self.name:upper(), fonts.subtab_title, text_pos, col.white:alpha(alpha / 2))
    end
    if self.size.x == 0 then
        local max_width = 0
        for i = 1, #self.values do
            local text_size = irender.text_size(fonts.menu, self.values[i])
            if max_width < text_size.x then
                max_width = text_size.x
            end
            self.size.x = max_width + 22
        end
    end
    local el = self.el
    local text_pos = from + v2(5, size.y / 2 - 3)
    local shadow_color = col.black:alpha(alpha)
    local text_color = col.white:alpha(alpha)
    if self.multi then
        local comma_width = irender.text_size(fonts.menu, ", ").x
        local ellipsis_width = irender.text_size(fonts.menu, "...").x
        local elements_after_width = 10 + ellipsis_width * 2 + 6
        local x = 0
        local place_comma = false
        ---@cast el multi_combo_box_t
        local last_active_index
        local has_active_been_trimmed = false
        local has_any_been_trimmed = false
        for i = 1, #self.values do
            local active = el:get(i-1)
            if active then
                last_active_index = i
            end
        end
        local none_active_alpha = self.anims.none_active(not last_active_index and 255 or 0)
        if none_active_alpha > 0 then
            irender.text("None", fonts.menu, text_pos + v2(1, 1), shadow_color:salpha(none_active_alpha))
            irender.text("None", fonts.menu, text_pos, text_color:salpha(none_active_alpha))
        end
        for i = 1, #self.values do
            local active = el:get(i-1)
            if self.values_data[i].text_size.x == 0 then
                self.values_data[i].text_size = irender.text_size(fonts.menu, self.values[i])
            end
            local value_width = (self.values_data[i].text_size.x)
            local out_of_bounds = text_pos.x + x > to.x - 4
            local value_alpha = self.values_data[i].anims.alpha((active and not out_of_bounds and not has_active_been_trimmed) and 255 or 0)
            -- self.values_data[i].anims.active(active and 255 or 0)
            if value_alpha > 0 then
                local elements_after = last_active_index and (last_active_index > i)
                local name = self.values[i]
                if place_comma then
                    name = ", " .. name
                    value_width = value_width + comma_width * (value_alpha / 255)
                end
                local value_pos = v2(text_pos.x + x, text_pos.y)
                if value_pos.x + value_width > to.x - elements_after_width and elements_after then
                    local current_width = value_width
                    while value_pos.x + current_width > to.x - elements_after_width do
                        name = name:sub(1, -2)
                        if name == "" then break end
                        current_width = irender.text_size(fonts.menu, name).x
                    end
                    name = trim_last_space(name)
                    if name == "," then
                        name = ", "
                    end
                    if not has_any_been_trimmed then
                        name = name .. "..., ..."
                    end
                    has_any_been_trimmed = true
                    if active then
                        has_active_been_trimmed = true
                    end
                elseif value_pos.x + value_width > to.x - 10 then
                    local current_width = value_width
                    while value_pos.x + current_width > to.x - 10 - ellipsis_width do
                        name = name:sub(1, -2)
                        if name == "" then break end
                        current_width = irender.text_size(fonts.menu, name).x
                    end
                    if not has_any_been_trimmed then
                        name = trim_last_space(name) .. "..."
                    end
                end
                if value_alpha > 0 then
                    irender.text(name, fonts.menu, value_pos + v2(1, 1), shadow_color:salpha(value_alpha))
                    irender.text(name, fonts.menu, value_pos, text_color:salpha(value_alpha))
                end

                x = x + math.round(value_width * (value_alpha / 255))
            end
            if active then
                place_comma = true
            end
        end
    else
        ---@cast el combo_box_t
        for i = 1, #self.values do
            local active = el:get() + 1 == i
            local value_alpha = self.values_data[i].anims.alpha(active and 255 or 0)
            -- self.values_data[i].anims.active(active and 255 or 0)
            if value_alpha > 0 then
                irender.text(self.values[i], fonts.menu, text_pos + v2(1, 1), shadow_color:salpha(value_alpha))
                irender.text(self.values[i], fonts.menu, text_pos, text_color:salpha(value_alpha))
            end
        end
    end
end, "dropdown_t.draw")

---@param self gui_dropdown_t
---@param alpha number
dropdown_mt.draw_popout = errors.handler(function (self, alpha)
    local active_alpha = self.anims.active() * (alpha / 255)
    if active_alpha == 0 then return end
    local padding = 26
    local height = #self.values * padding + 3
    local from = self.pos + v2(0, self.size.y - 2)
    local to = from + v2(self.width, height)
    local hover_anim = self.anims.hover()
    local active_border_color = colors.magnolia_tinted:fade(colors.magnolia, hover_anim / 255):alpha(active_alpha)
    local border_color = colors.magnolia_tinted:alpha(active_alpha)
    local half_height = math.round(height / 2)
    render.rect_filled(from + v2(1, 2), to - v2(1, 1), col.gray:alpha(active_alpha))
    render.rect_filled_fade(v2(to.x - 1, from.y + 1), to - v2(0, 1 + half_height), active_border_color, active_border_color, border_color, border_color)
    render.rect_filled_fade(from + v2(0, 1), v2(from.x + 1, to.y - 1 - half_height), active_border_color, active_border_color, border_color, border_color)
    render.rect_filled(v2(from.x, to.y - half_height - 1), v2(from.x + 1, to.y - 1), border_color)
    render.rect_filled(to - v2(1, 1 + half_height), to - v2(0, 1), border_color)
    render.rect_filled(v2(from.x + 1, to.y - 1), to - v2(1, 0), border_color)
    local new_col = border_color:salpha(127)
    render.rect_filled(v2(from.x, to.y), v2(from.x + 1, to.y - 1), new_col)
    render.rect_filled(to - v2(1, 1), to, new_col)

    local text_color = col.white:alpha(active_alpha)
    local active_text_color = col(colors.magnolia.r + 10, colors.magnolia.g + 10, colors.magnolia.b + 10, active_alpha)
    local shadow_color = col.black:alpha(active_alpha)
    do
        local hovered = drag.hover_absolute(from, to)
        if hovered then
            gui.hovered = true
        end
        if not hovered and input.is_key_clicked(1) and active_alpha > 127 then
            self.open = false
        end
    end
    for i = 1, #self.values do
        local el = self.el
        local active
        if self.multi then
            ---@cast el multi_combo_box_t
            active = el:get(i - 1)
        else
            ---@cast el combo_box_t
            active = el:get() + 1 == i
        end
        local pos = from + v2(0, 2 + (i - 1) * padding)
        if i ~= 1 then
            render.rect_filled(pos + v2(1, 0), pos - v2(1, 0) + v2(self.width, 1), border_color)
        end
        local text_padding = 5
        local text_pos = pos + v2(text_padding, padding / 2)
        local hovered = drag.hover_absolute(pos, pos + v2(self.width, padding))
        if hovered and active_alpha > 127 then
            if input.is_key_clicked(1) then
                gui.drag:block()
                click_effect.add()
                if self.multi then
                    ---@cast el multi_combo_box_t
                    el:set(i - 1, false)
                else
                    ---@cast el combo_box_t
                    el:set(i - 1)
                end
            end
            drag.set_cursor(drag.hand_cursor)
        end
        local value_alpha = self.values_data[i].anims.active(active and 255 or 0) * (active_alpha / 255)
        local hover_text_anim = self.values_data[i].anims.hover((active or hovered) and 255 or 0)
        local cur_text_color = text_color:fade(active_text_color, value_alpha / 255)
        irender.text(self.values[i], fonts.menu, text_pos + v2(1, 1), shadow_color:alpha_anim(hover_text_anim, 127, 255), irender.flags.Y_ALIGN)
        irender.text(self.values[i], fonts.menu, text_pos, cur_text_color:alpha_anim(hover_text_anim, 127, 255), irender.flags.Y_ALIGN)
        if value_alpha > 0 then
            render.circle_filled(text_pos + v2(self.width - text_padding * 3, 0), 2, 6, cur_text_color:alpha(value_alpha))
        end
    end
end)

---@overload fun(self: gui_dropdown_t, index: number): boolean
---@overload fun(self: gui_dropdown_t): number
dropdown_mt.val_index = function (self, index)
    if self.multi and index then
        return self.el:get(index - 1)
    elseif not self.multi then
        return self.el:get() + 1
    end
end

---@overload fun(self: gui_dropdown_t, name: string): boolean
---@overload fun(self: gui_dropdown_t): string
dropdown_mt.value = errors.handler(function (self, name)
    if self.multi and name then
        for i = 1, #self.values do
            if self.values[i] == name then
                return self.el:get(i - 1)
            end
        end
    elseif not self.multi then
        local val = self.el:get() + 1
        if name then
            for i = 1, #self.values do
                if self.values[i] == name then
                    return self.el:get() + 1 == i
                end
            end
        else
            return self.values[val]
        end
    end
end, "dropdown_mt.value")

---@param fn fun(el: gui_dropdown_t)
---@return gui_dropdown_t?
dropdown_mt.update = function (self, fn)
    if self.multi then return error("can't use update on multi dropdown") end
    cbs.paint(function ()
        local value = self:value()
        if value ~= self.old_value then
            fn(self)
        end
        self.old_value = value
    end, self.name .. ".update")
    cbs.unload(function ()
        self.el:set(0)
        fn(self)
    end, self.name .. ".update")
    return self
end

dropdown_mt.new = errors.handler(function (name, values, defaults)
    local path = gui.get_path(name)
    local el
    local multi = false
    if type(defaults) == "table" then
        local defaults_table = {}
        for i = 1, #defaults do
            for k = 1, #values do
                if values[k] == defaults[i] then
                    defaults_table[#defaults_table+1] = k - 1
                end
            end
        end
        el = menu.add_multi_combo_box(path, "magnolia", values, defaults_table)
        multi = true
    else
        local def_value = 0
        if defaults then
            for i = 1, #values do
                if values[i] == defaults then
                    def_value = i - 1
                    break
                end
            end
        end
        el = menu.add_combo_box(path, "magnolia", values, def_value)
    end
    local c = setmetatable({
        name = name,
        el = el,
        multi = multi,
        values = values,
        open = false,
        anims = anims.new({
            alpha = 255,
            hover = 0,
            active = 0,
            none_active = 0,
        }),
        pos = v2(0, 0),
        width = 0,
        values_data = {

        },
        size = v2(0, 32),
    }, { __index = dropdown_mt })
    if not multi then
        c.old_value = def_value or 0
    end
    for i = 1, #values do
        c.values_data[i] = {
            anims = anims.new({
                alpha = 0,
                active = 0,
                hover = 0,
            }),
            text_size = v2(0, 0),
        }
    end
    -- c.el:set_visible(false)
    return c
end, "dropdown_mt.new")

---@param name string
---@param values string[]
---@param defaults? string[]|string
---@return gui_dropdown_t
gui.dropdown = function(name, values, defaults)
    return gui.add_element(dropdown_mt.new(name, values, defaults))
end