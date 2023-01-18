local v2 = require("libs.vectors")()
local col = require("libs.colors")
local render = require("libs.render")
local gui = require("includes.gui")
local http = require("libs.http")
local fonts = require("includes.gui.fonts")
local header = {
    ---@param pos vec2_t
    tabs = function (pos)
        local alpha = gui.anims.main_alpha()
        for _, v in pairs(gui.elements) do
            local size = v:draw(pos, alpha)
            pos = pos + v2(size.x + 10, 0)
        end
    end,
    avatar_texture = nil,
}
---@param pos vec2_t
header.user = function (pos)
    local avatar_size = v2(20, 20)
    local avatar_pos = pos - v2(avatar_size.x, avatar_size.y / 2)
    local color = col.white:alpha(gui.anims.main_alpha())
    if header.avatar_texture then
        renderer.texture(header.avatar_texture, avatar_pos, avatar_pos + avatar_size, color)
    end
    render.text(client.get_username(), fonts.header, pos - v2(avatar_size.x + 8, 0), color, render.flags.RIGHT_ALIGN + render.flags.Y_ALIGN)
end
header.get_avatar = function ()
    local path = http.download("https://pleasant-build-r39zc.cloud.serverless.com/avatar_round/s/" .. client.get_username())
    if not path then return end
    header.avatar_texture = renderer.setup_texture(path)
end

header.get_avatar()

---@param pos vec2_t
header.draw = function (pos, alpha)
    local icon_padding = 14
    local icon_pos = pos + v2(icon_padding, icon_padding - 3)
    render.text("A", fonts.logo, icon_pos, col.magnolia:alpha(alpha))
    local center_after_icon_pos = icon_pos + v2(fonts.logo.size + icon_padding, fonts.logo.size / 2)
    local line_size = 14
    local line_start_pos = center_after_icon_pos - v2(0, line_size / 2 - 4)
    renderer.line(line_start_pos, line_start_pos + v2(0, line_size / 2), col.white:alpha(20):salpha(alpha))


    local tab_icon_pos = center_after_icon_pos + v2(icon_padding, 0)
    header.tabs(tab_icon_pos)
    header.user(v2(pos.x + gui.size.x - icon_padding, tab_icon_pos.y))
end

return header