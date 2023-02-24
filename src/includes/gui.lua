local drag = require("libs.drag")
local v2 = require("libs.vectors")()
local anims = require("libs.anims")
local render = require("libs.render")
local cbs = require("libs.callbacks")
local col = require("libs.colors")
gui = {
    size = v2(540, 380),
    drag = drag.new("magnolia", v2(0.5, 0.5), false),
    ---@type gui_tab_t[]
    elements = {},
    anims = anims.new({
        main_alpha = 0
    }),
    initialized = false,
    can_be_visible = false,
    active_tab = 1,
}

gui.init = function()
    gui.initialized = true
end

gui.get_path = function(name)
    local tab = gui.elements[#gui.elements]
    local path = {
        tab.name,
        tab.subtabs[#tab.subtabs].name,
        name
    }
    return table.concat(path, "_")
end

gui.add_element = function (element)
    local tab = gui.elements[#gui.elements]
    local subtab = tab.subtabs[#tab.subtabs]
    -- element.tab = #gui.elements
    -- element.subtab = #tab.subtabs
    table.insert(subtab.elements, element)
    return element
end

require("includes.gui.fonts")
local header = require("includes.gui.header")
require("includes.gui.tab")
local subtabs = require("includes.gui.subtab")
local container = require("includes.gui.container")

require("includes.gui.elements")

---@param pos vec2_t
gui.draw = function (pos, alpha)
    local background_color = col(18, 17, 16, (alpha / 255) * 250)

    render.rounded_rect(pos + v2(1, 1), pos + gui.size, background_color, 7, true)
    render.rounded_rect(pos, pos + gui.size, col.black:alpha(200):salpha(alpha), 7.5)

    header.draw(pos, alpha)
    container.draw(pos, alpha)
    subtabs.draw(pos, alpha)
end

cbs.add("paint", function()
    if not gui.initialized or not gui.can_be_visible then return end
    local main_alpha = gui.anims.main_alpha(ui.is_visible() and 255 or 0, 20)
    if main_alpha == 0 then return end
    local pos, highlight = gui.drag:run(drag.hover_fn(gui.size, true, true), function(pos, alpha)
        drag.highlight(pos - v2(gui.size.x / 2, 0), gui.size, alpha)
    end)
    pos = (pos - gui.size / 2):round()
    gui.draw(pos, main_alpha)
    -- highlight()
end)

return gui