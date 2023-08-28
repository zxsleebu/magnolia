local irender = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local subtabs = require("includes.gui.subtab")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")
local colors = require("includes.colors")

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
        ---@param input_allowed boolean
        ---@return vec2_t
        draw = errors.handler(function (s, pos, alpha, input_allowed)
            local text_size = irender.text_size(fonts.header, s.name)
            local real_size = v2(text_size.x + fonts.tab_icons.size + 8, fonts.tab_icons.size)
            local size = real_size + v2(12, 0)
            local line_width = s.anims.underline_width()
            local color_blend, underline_alpha
            local active = gui.active_tab == s.index
            if active then
                line_width = s.anims.underline_width(math.round(text_size.x / 2))
                underline_alpha = s.anims.underline_alpha(255)
                color_blend = s.anims.active_color_blend(255)
                s.anims.alpha(255)
            else
                line_width = s.anims.underline_width(0)
                underline_alpha = s.anims.underline_alpha(0)
                color_blend = s.anims.active_color_blend(0)
                s.anims.alpha(0)
            end
            local hovered = input_allowed and drag.hover_absolute(pos - v2(2, real_size.y), pos + v2(real_size.x + 4, real_size.y))
            local hover_anim
            if hovered and not active and not gui.drag.dragging then
                drag.set_cursor(drag.hand_cursor)
            end
            if hovered and active then
                drag.set_cursor(drag.arrow_cursor)
            end
            if hovered or active then
                hover_anim = s.anims.hover(255)
            else
                hover_anim = s.anims.hover(0)
            end
            if hovered then
                gui.drag:block()
                if input.is_key_clicked(1) then
                    gui.active_tab = s.index
                    click_effect.add()
                end
            end
            local color = col.white:alpha(alpha):alpha_anim(hover_anim, 60, 255)
            local icon_color = col.white:alpha(alpha):alpha_anim(hover_anim, 60, 150):fade(colors.magnolia:alpha(alpha), color_blend / 255)

            irender.text(s.icon, fonts.tab_icons, pos, icon_color, irender.flags.Y_ALIGN)
            local text_pos = pos + v2(fonts.tab_icons.size + 8, 0)
            irender.text(s.name, fonts.header, text_pos, color, irender.flags.Y_ALIGN)

            line_width = line_width * 2
            local line_pos = text_pos + v2(text_size.x / 2 - line_width / 2, size.y - 2)
            local line_color = colors.magnolia:alpha(alpha):alpha_anim(underline_alpha, 0, 255)
            render.rect_filled(line_pos, line_pos + v2(line_width, 1), line_color:salpha(100))
            render.rect_filled(line_pos + v2(0, 1), line_pos + v2(line_width, 2), line_color)
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