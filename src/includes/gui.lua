local drag = require("libs.drag")
local v2 = require("libs.vectors")()
local cbs = require("libs.callbacks")
local col = require("libs.colors")
local render = require("libs.render")
local tabs = require("includes.gui.tab")
local anims = require("libs.anims")
local header
local gui = {
    size = v2(512, 360),
    drag = drag.new("magnolia", v2(0.5, 0.5)),
    ---@type gui_tab_t[]
    elements = {},
    anims = anims.new({
        main_alpha = 0
    }),
    initialized = false,
    can_be_visible = false,
}
gui.init = function ()
    if gui.initialized then return end
    header = require("includes.gui.header")
    gui.initialized = true
end
gui.tab = function(name, icon)
    local tab = tabs.new(name, icon)
    table.insert(gui.elements, tab)
    return tab
end
---@param pos vec2_t
gui.draw = function (pos, alpha)
    local background_color = col(18, 17, 16, (alpha / 255) * 250)

    render.rounded_rect(pos + v2(1, 1), pos + gui.size, background_color, 7, true)
    render.rounded_rect(pos, pos + gui.size, col.black:alpha(200):salpha(alpha), 7.5)

    header.draw(pos, alpha)
end
gui.tab("Aimbot", "B")
gui.tab("Anti-Aim", "C")
gui.tab("Visuals", "D")
gui.tab("Misc", "E")
cbs.add("paint", function()
    if not gui.initialized or not gui.can_be_visible then return end
    local main_alpha = gui.anims.main_alpha(ui.is_visible() and 255 or 0)
    if main_alpha == 0 then return end
    local pos, highlight = gui.drag:run(drag.hover_fn(gui.size), function(pos, alpha)
        drag.highlight(pos, gui.size, alpha)
    end)
    pos = pos:round()
    gui.draw(pos, main_alpha)
    highlight()
end)

return gui