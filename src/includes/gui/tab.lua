local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local subtabs = require("includes.gui.subtab")
local errors = require("libs.error_handler")

---@class gui_tab_t
---@field name string
---@field icon string
---@field anims __anims_mt
---@field subtabs gui_subtab_t[]
local tab_t = { }
local tab_mt = {
    ---@class gui_tab_t
    __index = {
        ---@param s gui_tab_t
        ---@param pos vec2_t
        ---@param alpha number
        ---@return vec2_t
        draw = errors.handle(function (s, pos, alpha)
            local text_size = render.text_size(fonts.header, s.name)
            local real_size = v2(text_size.x + fonts.tab_icons.size + 8, fonts.tab_icons.size)
            local size = real_size + v2(12, 0)
            local line_width = s.anims.underline_width()
            local color_blend, underline_alpha
            if gui.active_tab == s.index then
                line_width = s.anims.underline_width(text_size.x / 2)
                underline_alpha = s.anims.underline_alpha(255)
                color_blend = s.anims.active_color_blend(255)
                s.anims.alpha(255)
            else
                line_width = s.anims.underline_width(0)
                underline_alpha = s.anims.underline_alpha(0)
                color_blend = s.anims.active_color_blend(0)
                s.anims.alpha(0)
            end
            local hovered = drag.hover(pos - v2(2, real_size.y), pos + v2(real_size.x + 4, real_size.y))
            local hover_anim
            if hovered then
                drag.set_cursor(drag.hand_cursor)
            end
            if hovered or gui.active_tab == s.index then
                hover_anim = s.anims.hover(255)
            else
                hover_anim = s.anims.hover(0)
            end
            if hovered and input.is_key_pressed(1) then
                gui.active_tab = s.index
            end
            local color = col.white:alpha(alpha):alpha_anim(hover_anim, 60, 255)
            local icon_color = col.white:alpha(alpha):alpha_anim(hover_anim, 60, 150):fade(col.magnolia:alpha(alpha), color_blend / 255)

            render.text(s.icon, fonts.tab_icons, pos, icon_color, render.flags.Y_ALIGN)
            local text_pos = pos + v2(fonts.tab_icons.size + 8, 0)
            render.text(s.name, fonts.header, text_pos, color, render.flags.Y_ALIGN)

            line_width = line_width * 2
            local line_pos = text_pos + v2(text_size.x / 2 - line_width / 2, size.y - 2)
            local line_color = col.magnolia:alpha(alpha):alpha_anim(underline_alpha, 0, 255)
            renderer.rect_filled(line_pos, line_pos + v2(line_width, 1), line_color:salpha(100))
            renderer.rect_filled(line_pos + v2(0, 1), line_pos + v2(line_width, 2), line_color)
            return size
        end, "tab_t.draw")
    }
}
tab_t.index = 1
tab_t.new = function(name, icon)
    local tab = {
        name = name,
        icon = icon,
        subtabs = { },
        anims = anims.new({
            alpha = 0,
            hover = 0,
            underline_width = 0,
            underline_alpha = 255,
            active_color_blend = 0,
        }),
        index = tab_t.index,
    }
    tab_t.index = tab_t.index + 1
    subtabs.index = 1
    return setmetatable(tab, tab_mt)
end
gui.tab = function(name, icon)
    local tab = tab_t.new(name, icon)
    table.insert(gui.elements, tab)
    return tab
end
return tab_t