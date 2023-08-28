local irender = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")

local container_t = require("includes.gui.container")
local column_t = require("includes.gui.column")
local click_effect = require("includes.gui.click_effect")
require("includes.gui.types")
local colors = require("includes.colors")


---@class gui_g_subtab_t
local subtab_t = {}
local subtab_mt = {
    ---@class gui_subtab_t
    ---@field name string
    ---@field anims __anims_mt
    ---@field index number
    ---@field active boolean
    ---@field columns gui_column_t[]
    ---@field tab number
    __index = {
        ---@type fun(subtab: gui_subtab_t, pos: vec2_t, width: number, alpha: number, input_allowed: boolean)
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
        columns = {
            column_t.new()
        },
        tab = #gui.elements
    }, subtab_mt)
    if s.index == 1 then
        s.active = true
    end
    subtab_t.index = subtab_t.index + 1
    return s
end
---@param pos vec2_t
---@param global_alpha number
---@param input_allowed boolean
subtab_t.draw = errors.handler(function (pos, global_alpha, input_allowed)
    local menu_padding = gui.paddings.menu_padding
    local padding = 40
    local width = gui.paddings.subtab_list_width
    local top_padding = 70
    for i = 1, #gui.elements do
        local tab = gui.elements[i]
        local alpha = tab.anims.alpha()
        local active = gui.active_tab == i
        errors.handler(function()
            if alpha == 0 then return end
            alpha = alpha * (global_alpha / 255)
            for t = 1, #tab.subtabs do
                local subtab = tab.subtabs[t]
                local p = pos + v2(menu_padding, padding * (t - 1) + top_padding) ---@type vec2_t
                local is_last = t == #tab.subtabs
                -- local text_size = render.text_size(fonts.header, subtab.name)
                -- local active_line_pos = p + v2(0, text_size.y / 2 + 2)
                local box_from = p - v2(5, padding / 2 - 1)
                -- local container_pos = p + v2(width + menu_padding, top_padding - padding / 2 + 1)
                local box_to = p + v2(width, padding / 2)
                -- renderer.rect_filled(box_from, box_to, col.white:alpha(alpha):salpha(100))
                local is_hovered = input_allowed and active and drag.hover_absolute(box_from, box_to)
                if is_hovered then
                    drag.set_cursor(drag.hand_cursor)
                end
                if is_hovered and input.is_key_clicked(1) then
                    gui.drag:block()
                    click_effect.add()
                    for a = 1, #tab.subtabs do
                        tab.subtabs[a].active = false
                    end
                    subtab.active = true
                end
                local underline_alpha, hover
                if subtab.active then
                    subtab.anims.alpha(255)
                    underline_alpha = subtab.anims.underline_alpha(255)
                else
                    subtab.anims.alpha(0)
                    underline_alpha = subtab.anims.underline_alpha(0)
                end
                if is_hovered or subtab.active then
                    hover = subtab.anims.hover(255)
                else
                    hover = subtab.anims.hover(0)
                end
                irender.text(subtab.name,
                    fonts.header, p,
                    col.white:fade(colors.magnolia, underline_alpha / 255):alpha(alpha):alpha_anim(hover, 100, 255),
                    irender.flags.Y_ALIGN)
                -- if underline_alpha > 0 then
                --     local active_line_color = colors.magnolia:alpha(alpha):salpha(underline_alpha)
                --     -- renderer.rect_filled(active_line_pos, active_line_pos + v2(text_size.x, 1), active_line_color)
                --     -- renderer.rect_filled(active_line_pos + v2(0, 1), active_line_pos + v2(text_size.x, 2), active_line_color:salpha(100))
                -- end
                if not is_last then
                    local line_pos = p + v2(0, padding / 2)
                    render.rect_filled(line_pos, line_pos + v2(width, 1), col.white:alpha(alpha):salpha(30))
                end
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