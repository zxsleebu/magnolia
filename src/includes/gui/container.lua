local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local errors = require("libs.error_handler")
require("includes.gui.checkbox")
local fonts  = require("includes.gui.fonts")
-- local gui = require("includes.gui")

---@class gui_container_t
local container_t = {}
---@param pos vec2_t
container_t.draw = errors.handle(function (pos, alpha)
    local menu_padding = 14
    local width = 114
    local padding = 34
    local from = pos + v2(width + menu_padding, 64 - padding / 2 + 1)
    local background_color = col(23, 22, 20, 200):salpha(alpha)
    render.rounded_rect(from + v2(1, 1), pos + v2(gui.size.x - 1, gui.size.y - 1), background_color, 7.5, true)
    render.rounded_rect(from, pos + v2(gui.size.x - 1, gui.size.y - 1), col.white:alpha(alpha):salpha(30), 7.5, false)
    for i = 1, #gui.elements do
        local tab = gui.elements[i]
        local tab_alpha = tab.anims.alpha()
        render.text(tab.icon, fonts.title_icon, from + v2(23, 14), col.magnolia:alpha(tab_alpha):salpha(alpha), render.flags.X_ALIGN)
        local text_pos = from + v2(40, 13)
        render.text(tab.name, fonts.tab_title, text_pos, col.white:alpha(tab_alpha):salpha(alpha), render.flags.TEXT_SIZE)
        if tab_alpha > 0 then
            for s = 1, #tab.subtabs do
                local subtab = tab.subtabs[s]
                local subtab_alpha = subtab.anims.alpha()
                if subtab_alpha > 0 then
                    render.text(subtab.name:upper(), fonts.subtab_title, text_pos + v2(0, 13), col.white:alpha(subtab_alpha / 2):salpha(alpha):salpha(tab_alpha))
                end
            end
        end
    end
end, "container_t.draw")
---@param subtab gui_subtab_t
container_t.draw_elements = errors.handle(function(subtab, pos, alpha)
    local input_allowed = gui.active_tab == subtab.tab and subtab.active
    local y = 0
    for i = 1, #subtab.elements do
        local element = subtab.elements[i]
        local p = pos + v2(0, y) ---@type vec2_t
        y = y + element.size.y
        if alpha > 0 then
            element:draw(p, alpha, input_allowed)
        end
    end
end, "container_t.draw_elements")

return container_t