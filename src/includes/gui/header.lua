local v2 = require("libs.vectors")()
local col = require("libs.colors")
local render = require("libs.render")
local http = require("libs.http")
local fonts = require("includes.gui.fonts")
local anims = require("libs.anims")
-- local delay = require("libs.delay")
local errors = require("libs.error_handler")
local drag = require("libs.drag")
local input = require("libs.input")
local win32 = require("libs.win32")
local once = require("libs.once").new()
local click_effect = require("includes.gui.click_effect")

local header = {
    ---@param pos vec2_t
    tabs = function (pos)
        local alpha = gui.anims.main_alpha()
        for _, v in pairs(gui.elements) do
            local size = v:draw(pos, alpha)
            pos = pos + v2(size.x + 10, 0)
        end
    end,
    anims = anims.new({
        avatar_alpha = 0,
        hover = 0,
    }),
    avatar_texture = nil,
}
---@param pos vec2_t
header.user = errors.handle(function (pos)
    local avatar_size = v2(26, 26)
    local avatar_pos = pos - v2(avatar_size.x - 4, avatar_size.y / 2)
    local alpha = gui.anims.main_alpha()
    local color = col.white:alpha(alpha)
    local avatar_alpha = header.anims.avatar_alpha()
    local hover_anim = header.anims.hover()
    local circle_pos = avatar_pos + avatar_size / 2 ---@type vec2_t
    local circle_color = col.white:alpha(255 - avatar_alpha):salpha(alpha):salpha(hover_anim)

    local start_angle = globalvars.get_real_time() * 300 % 360
    local spinner_pos = circle_pos - v2(0.5, 0.5)
    if header.avatar_texture then
        avatar_alpha = header.anims.avatar_alpha(255)
        renderer.texture(header.avatar_texture, avatar_pos, avatar_pos + avatar_size, color:salpha(avatar_alpha):salpha(hover_anim))
    end
    if avatar_alpha ~= 255 then
        local spinner_radius = 11
        renderer.circle(circle_pos, avatar_size.x / 2, 15, true, circle_color:salpha(20))
        render.text("?", fonts.avatar_question, circle_pos, circle_color, render.flags.X_ALIGN + render.flags.Y_ALIGN)
        render.circle(spinner_pos, spinner_radius + 0.5, circle_color:salpha(50), start_angle, start_angle + 270, false)
        render.circle(spinner_pos, spinner_radius - 0.5, circle_color:salpha(50), start_angle, start_angle + 270, false)
        render.circle(spinner_pos, spinner_radius, circle_color:salpha(100), start_angle, start_angle + 270, false)
    end
    local text_pos = pos - v2(avatar_size.x + 3, 0)
    local normalized_text_pos, text_size =
        render.text(client.get_username(), fonts.header, text_pos, color:salpha(hover_anim), render.flags.RIGHT_ALIGN + render.flags.Y_ALIGN)
    ---@cast text_size vec2_t
    local hovered =
        drag.hover_absolute(normalized_text_pos - v2(2, 0), normalized_text_pos + text_size + v2(2, 00)) or
        drag.hover_absolute(avatar_pos - v2(1, 1), avatar_pos + avatar_size + v2(1, 1))
    if hovered then
        drag.block()
        header.anims.hover(175)
        drag.set_cursor(drag.hand_cursor)
    else
        header.anims.hover(255)
    end
    if hovered and input.is_key_clicked(1) then
        click_effect.add()
        header.open_link()
    end
end, "header.user")
header.get_avatar = function ()
    if gui.anims.main_alpha() ~= 255 then return end
    if header.avatar_texture then return end
    once(function ()
        http.download("https://pleasant-build-r39zc.cloud.serverless.com/avatar_round/s/" .. client.get_username(), nil, function(path)
            header.avatar_texture = renderer.setup_texture(path)
        end)
    end, "get_avatar")
end
header.open_link = function()
    win32.open_url("https://nixware.uk.ms/profile/" .. client.get_username())
end

---@param pos vec2_t
header.draw = errors.handle(function (pos, alpha)
    header.get_avatar()
    local icon_padding = 14
    local icon_pos = pos + v2(icon_padding, icon_padding - 3)
    render.text("A", fonts.logo_shadow, icon_pos - v2(2, 2), col.magnolia:alpha(alpha):salpha(50))
    render.text("A", fonts.logo, icon_pos, col.magnolia:alpha(alpha))
    local center_after_icon_pos = icon_pos + v2(fonts.logo.size + icon_padding, fonts.logo.size / 2)
    local line_size = 14
    local line_start_pos = center_after_icon_pos - v2(0, line_size / 2 - 4)
    renderer.line(line_start_pos, line_start_pos + v2(0, line_size / 2), col.white:alpha(20):salpha(alpha))


    local tab_icon_pos = center_after_icon_pos + v2(icon_padding, 0)
    header.tabs(tab_icon_pos)
    header.user(v2(pos.x + gui.size.x - icon_padding, tab_icon_pos.y))
end, "header.draw")

return header