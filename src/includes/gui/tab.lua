local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")

---@class gui_tab_t
---@field name string
---@field icon string
local tab_t = { }
local tab_mt = {
    ---@class gui_tab_t
    __index = {
        ---@param s gui_tab_t
        ---@param pos vec2_t
        ---@param alpha number
        ---@return vec2_t
        draw = function (s, pos, alpha)
            local color = col.white:alpha(100):salpha(alpha)
            render.text(s.icon, fonts.tab_icons, pos, color, render.flags.Y_ALIGN)
            local text_size = render.text_size(fonts.header, s.name)
            render.text(s.name, fonts.header, pos + v2(fonts.tab_icons.size + 8, 0), color, render.flags.Y_ALIGN)
            --return size
            return v2(text_size.x + fonts.tab_icons.size + 20, fonts.tab_icons.size)
        end
    }
}
tab_t.new = function(name, icon)
    local tab = {
        name = name,
        icon = icon,
        subtabs = { }
    }
    return setmetatable(tab, tab_mt)
end
return tab_t