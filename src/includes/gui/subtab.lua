local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
-- local gui = require("includes.gui")
local input = require("libs.input")
local container_t = require("includes.gui.container")
local errors = require("libs.error_handler")
require("includes.gui.types")

---@class gui_g_subtab_t
local subtab_t = {}
local subtab_mt = {
    ---@class gui_subtab_t
    ---@field name string
    ---@field anims __anims_mt
    ---@field index number
    ---@field active boolean
    ---@field elements gui_element_t[]
    ---@field tab number
    __index = {
        draw = container_t.draw_elements
    }
}
---@return gui_subtab_t
subtab_t.new = function (name)
    local s = setmetatable({
        name = name,
        index = subtab_t.index,
        anims = anims.new({
            alpha = 0,
            underline_alpha = 0,
            hover = 0,
        }),
        active = false,
        elements = {},
        tab = #gui.elements
    }, subtab_mt)
    if s.index == 1 then
        s.active = true
    end
    subtab_t.index = subtab_t.index + 1
    return s
end
subtab_t.draw = errors.handle(function (pos, global_alpha)
    local menu_padding = 14
    local padding = 40
    local width = 100
    for i = 1, #gui.elements do
        local tab = gui.elements[i]
        local alpha = tab.anims.alpha()
        errors.handle(function()
            if alpha == 0 then return end
            alpha = alpha * (global_alpha / 255)
            for t = 1, #tab.subtabs do
                local subtab = tab.subtabs[t]
                local p = pos + v2(menu_padding, padding * (t - 1) + 64) ---@type vec2_t
                local is_last = t == #tab.subtabs
                local text_size = render.text_size(fonts.header, subtab.name)
                local active_line_pos = p + v2(0, text_size.y / 2 + 2)
                local box_from = p - v2(5, padding / 2 - 1)
                local container_pos = p + v2(width + menu_padding, 64 - padding / 2 + 1)
                local box_to = p + v2(width, padding / 2)
                -- renderer.rect_filled(box_from, box_to, col.white:alpha(alpha):salpha(100))
                local is_hovered = drag.hover(box_from, box_to)
                if is_hovered then
                    drag.set_cursor(drag.hand_cursor)
                end
                if is_hovered and input.is_key_pressed(1) then
                    for a = 1, #tab.subtabs do
                        tab.subtabs[a].active = false
                    end
                    subtab.active = true
                end
                local underline_alpha, hover, tab_alpha
                if subtab.active then
                    tab_alpha = subtab.anims.alpha(255)
                    underline_alpha = subtab.anims.underline_alpha(255)
                else
                    tab_alpha = subtab.anims.alpha(0)
                    underline_alpha = subtab.anims.underline_alpha(0)
                end
                if is_hovered or subtab.active then
                    hover = subtab.anims.hover(255)
                else
                    hover = subtab.anims.hover(0)
                end
                render.text(subtab.name, fonts.header, p, col.white:alpha(alpha):alpha_anim(hover, 100, 255), render.flags.Y_ALIGN)
                if underline_alpha > 0 then
                    local active_line_color = col.magnolia:alpha(alpha):salpha(underline_alpha)
                    renderer.rect_filled(active_line_pos, active_line_pos + v2(text_size.x, 1), active_line_color)
                    renderer.rect_filled(active_line_pos + v2(0, 1), active_line_pos + v2(text_size.x, 2), active_line_color:salpha(100))
                end
                if not is_last then
                    local line_pos = p + v2(0, padding / 2)
                    renderer.rect_filled(line_pos, line_pos + v2(width, 1), col.white:alpha(alpha):salpha(30))
                end
                subtab:draw(pos + v2(130, 60), alpha * tab_alpha / 255)
            end
        end, "subtab_t.draw.loop")()
    end
end, "subtab_t.draw")

gui.subtab = function(name)
    local subtab = subtab_t.new(name)
    table.insert(gui.elements[#gui.elements].subtabs, subtab)
    return subtab
end

return subtab_t