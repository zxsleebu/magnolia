local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local errors = require("libs.error_handler")
require("includes.gui.checkbox")
local fonts  = require("includes.gui.fonts")
local element_t = require("includes.gui.element")

---@class gui_container_t
local container_t = {}
---@param from vec2_t
---@param to vec2_t
---@param alpha number
---@param background_alpha? number
container_t.draw_background = errors.handle(function(from, to, alpha, background_alpha)
    local background_color = col(23, 22, 20, background_alpha or 200):salpha(alpha)
    render.rounded_rect(from + v2(1, 1), to, background_color, 7.5, true)
    render.rounded_rect(from, to, col.white:alpha(alpha):salpha(30), 7.5, false)
end)

---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
container_t.draw = errors.handle(function (pos, alpha, input_allowed)
    local width = gui.paddings.subtab_list_width
    local menu_padding = gui.paddings.menu_padding
    local padding = 34
    local from = pos + v2(width + menu_padding, 64 - padding / 2 + 1)
    local to = pos + v2(gui.size.x - 1, gui.size.y - 1)
    local container_width = to.x - from.x - menu_padding
    container_t.draw_background(from, to, alpha)
    for i = 1, #gui.elements do
        local tab = gui.elements[i]
        local tab_alpha = tab.anims.alpha()
        render.text(tab.icon, fonts.title_icon, from + v2(23, menu_padding), col.magnolia:alpha(tab_alpha):salpha(alpha), render.flags.X_ALIGN)
        local text_pos = from + v2(40, 13)
        render.text(tab.name, fonts.tab_title, text_pos, col.white:alpha(tab_alpha):salpha(alpha), render.flags.TEXT_SIZE)
        if tab_alpha > 0 then
            for s = 1, #tab.subtabs do
                local subtab = tab.subtabs[s]
                local subtab_alpha = subtab.anims.alpha()
                if subtab_alpha > 0 then
                    container_t.draw_columns(subtab.columns, from + v2(menu_padding, menu_padding * 3 + 6),
                        container_width,
                        alpha * tab_alpha / 255 * subtab_alpha / 255,
                        gui.active_tab == subtab.tab and subtab.active and input_allowed)
                    render.text(subtab.name:upper(), fonts.subtab_title, text_pos + v2(0, 13), col.white:alpha(subtab_alpha / 2):salpha(alpha):salpha(tab_alpha))
                end
            end
        end
    end
end, "container_t.draw")

---@param elements gui_element_t[]
---@param pos vec2_t
---@param width number
---@param alpha number
---@param input_allowed boolean
container_t.draw_elements = errors.handle(function(elements, pos, width, alpha, input_allowed)
    local add_pos = v2(0, 0)
    if alpha > 0 then
        for e = 1, #elements do
            local element = elements[e]
            local p = (pos + add_pos):round() ---@type vec2_t
            local element_alpha, element_input = element_t.animate_master(element)
            element_alpha = element_alpha / 255
            element_input = element_input and element_alpha > 0
            add_pos.y = add_pos.y + (element.size.y + element.padding) * element_alpha
            element_alpha = element_alpha * alpha
            if element_alpha > 0 or alpha == 0.01 then
                element:draw(p, element_alpha, width, input_allowed and element_input)
            end
        end
    end
end, "container_t.draw_elements")

---@param columns gui_column_t[]
---@param pos vec2_t
---@param width number
---@param alpha number
---@param input_allowed boolean
container_t.draw_columns = errors.handle(function(columns, pos, width, alpha, input_allowed)
    local column_width = math.round(width / #columns - gui.paddings.menu_padding)
    for i = 1, #columns do
        local column = columns[i]
        local add_pos = v2(width / #columns * (i - 1), 0):round()
        container_t.draw_elements(column.elements, pos + add_pos, column_width, alpha, input_allowed)

        --!DEBUG
        -- renderer.rect(pos + add_pos, pos + add_pos + v2(column_width, 100), col.black:alpha(alpha))
        --!DEBUG
    end
end, "container_t.draw_columns")

return container_t