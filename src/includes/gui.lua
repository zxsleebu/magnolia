local drag = require("libs.drag")
local v2 = require("libs.vectors")()
local anims = require("libs.anims")
local errors = require("libs.error_handler")
local render = require("libs.render")
local cbs = require("libs.callbacks")
local col = require("libs.colors")
local click_effect = require("includes.gui.click_effect")

gui = {
    size = v2(560, 380),
    drag = drag.new("magnolia", v2(0.5, 0.5), false),
    ---@type gui_tab_t[]
    elements = {},
    anims = anims.new({
        main_alpha = 0
    }),
    initialized = false,
    can_be_visible = false,
    active_tab = 1,
    current_options = nil,
    paddings = {
        menu_padding = 14,
        subtab_list_width = 114,
        options_padding = 10,
    }
}

require("includes.gui.fonts")
local header_t = require("includes.gui.header")
require("includes.gui.tab")
local subtab_t = require("includes.gui.subtab")
local container_t = require("includes.gui.container")
local options_t = require("includes.gui.options")
local column_t = require("includes.gui.column")

gui.init = function()
    gui.initialized = true
end

gui.get_path = errors.handle(function(name)
    local tab = gui.elements[#gui.elements]
    local path = {
        tab.name,
        tab.subtabs[#tab.subtabs].name,
        name
    }
    return table.concat(path, "_")
end, "gui.get_path")

gui.add_element = errors.handle(function (element)
    if gui.current_options then
        table.insert(gui.current_options.columns[#gui.current_options.columns].elements, element)
        return element
    end
    local tab = gui.elements[#gui.elements]
    local subtab = tab.subtabs[#tab.subtabs]

    -- element.tab = #gui.elements
    -- element.subtab = #tab.subtabs
    table.insert(subtab.columns[#subtab.columns].elements, element)
    return element
end, "gui.add_element")

gui.column = errors.handle(function ()
    if gui.current_options then
        table.insert(gui.current_options.columns, column_t.new())
        return
    end
    local tab = gui.elements[#gui.elements]
    local subtab = tab.subtabs[#tab.subtabs]
    table.insert(subtab.columns, column_t.new())
end, "gui.column")

require("includes.gui.elements")

gui.is_input_allowed = errors.handle(function()
    local tab = gui.elements[gui.active_tab]
    for j = 1, #tab.subtabs do
        local subtab = tab.subtabs[j]
        if subtab.active then
            for k = 1, #subtab.columns do
                local column = subtab.columns[k]
                for l = 1, #column.elements do
                    local element = column.elements[l]
                    if element.inline and element.inline.open then
                        return false
                    end
                end
            end
        end
    end
    return true
end, "gui.is_input_allowed")

---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
gui.draw = errors.handle(function (pos, alpha, input_allowed)
    local background_color = col(18, 17, 16, (alpha / 255) * 250)

    render.rounded_rect(pos + v2(1, 1), pos + gui.size, background_color, 7, true)
    render.rounded_rect(pos, pos + gui.size, col.black:alpha(200):salpha(alpha), 7.5)

    header_t.draw(pos, alpha, input_allowed)
    container_t.draw(pos, alpha, input_allowed)
    subtab_t.draw(pos, alpha, input_allowed)
end, "gui.draw")

cbs.add("paint", errors.handle(function()
    if not gui.initialized or not gui.can_be_visible then return end
    local main_alpha = gui.anims.main_alpha(ui.is_visible() and 255 or 0, 20)
    if main_alpha == 0 then return end
    local input_allowed = gui.is_input_allowed()
    local is_hovered
    local pos, highlight = gui.drag:run(function(pos)
        is_hovered = input_allowed and drag.hover_absolute(pos - gui.size / 2, pos - gui.size / 2 + v2(gui.size.x, 48))
        return is_hovered
    end, function(pos, alpha)
        drag.highlight(pos - v2(gui.size.x / 2, 0), gui.size, alpha)
    end)
    if is_hovered then
        drag.set_cursor(drag.move_cursor)
    end
    pos = (pos - gui.size / 2):round()
    gui.pos = pos
    gui.draw(pos, main_alpha, input_allowed)
    options_t.draw()
    click_effect.draw()
    -- highlight()
end, "gui.paint"))


return gui