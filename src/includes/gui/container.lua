local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local gui = require("includes.gui")

local container_t = {}
container_t.draw = function (pos, alpha)
    local menu_padding = 14
    local width = 100
    local padding = 40
    local from = pos + v2(width + menu_padding, 64 - padding / 2 + 1)
    local background_color = col(23, 22, 20, 200):salpha(alpha)
    render.rounded_rect(from + v2(1, 1), pos + v2(gui.size.x - 1, gui.size.y - 1), background_color, 7.5, true)
    render.rounded_rect(from, pos + v2(gui.size.x - 1, gui.size.y - 1), col.white:alpha(alpha):salpha(30), 7.5, false)
end
return container_t