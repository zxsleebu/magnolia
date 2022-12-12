local render = require("libs.render")
local delay = require("libs.delay")
local v2 = require("libs.vectors")()
local col = require("libs.colors")
local cbs = require("libs.callbacks")
local nixware = require("includes.nixware")
local once = require("libs.once").new()
local logger = require("includes.logger").new()
local anims = require("libs.anims").new({
    bg_alpha = 0,
    slider_y_offset = 55,
    slider_border_alpha = 0,
    slider_alpha = 0,
    text_alpha = 0,
    text_y_offset = 25,
    progress = 0,
    transparency = 255,
    percent_align = 0,
    test_progress = 0,
})
local loading = {}
local magnolia_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 80, 0)
local percentage_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, render.font_flags.MonoHinting)
local can_be_closed = false
local remove_slider = false
loading.draw = function()
    if anims.transparency() == 0 then return end
    local ss = engine.get_screen_size()
    local slider_sizes = v2(300, 25)
    local main_alpha = 1
    once(function()
        -- ui.set_visible(false)
    end, "close_menu")
    if can_be_closed then
        once(function()
            logger:clean()
        end, "clean_logger")
        main_alpha = anims.transparency(0) / 255
    end
    do
        local alpha = anims.bg_alpha(255) * main_alpha
        local c1, c2 = col.black:alpha(50):salpha(alpha), col.black:alpha(200):salpha(alpha)
        renderer.rect_filled_fade(v2(0, 0), v2(ss.x, ss.y), c1, c1, c2, c2)
    end
    if anims.bg_alpha.done then
        local y = ss.y / 2 + anims.slider_y_offset(35)
        local from = v2(ss.x / 2 - slider_sizes.x / 2, y):round()
        local to = v2(ss.x / 2 + slider_sizes.x / 2, y + slider_sizes.y):round()

        local slider_border_alpha = anims.slider_border_alpha()
        if not remove_slider then
            slider_border_alpha = anims.slider_border_alpha(255)
        end
        slider_border_alpha = slider_border_alpha * main_alpha
        do
            local border_color = col.white:alpha(slider_border_alpha)
            render.rounded_rect(from, to, border_color, 3.1)
            render.rounded_rect(from - v2(1, 1), to + v2(1, 1), border_color:salpha(75), 4.1)
        end

        if anims.slider_y_offset.done then
            if nixware.__scan.percent == 1 then
                once(function()
                    logger:add({{"nixware allocbase found", col.white}})
                end, "nixware_scan_done")
            end
            local progress = nixware.__scan.percent / 2 + anims.test_progress(50, 3) / 100
            if progress == 1 then
                once(function()
                    logger:add({{"have", col.white}, {" fun!", col.magnolia}})
                end, "progress_done")
            end
            local percentage = anims.progress(progress * 100)
            local alpha = anims.slider_alpha()
            if not remove_slider then
                alpha = anims.slider_alpha(255)
            end
            local width = math.max(10, slider_sizes.x * anims.progress.value / 100)
            render.rounded_rect(from + v2(4, 4), v2(from.x + width, to.y) - v2(3, 3), col.magnolia:salpha(alpha), 2.1, true)
            local text_alpha = anims.text_alpha(255) * main_alpha

            render.text("magnolia", magnolia_font, v2(ss.x / 2, ss.y / 2 - anims.text_y_offset()), col.white:alpha(text_alpha),
                render.flags.X_ALIGN + render.flags.Y_ALIGN + render.flags.BIG_SHADOW)

            do
                local text = percentage .. "%"
                local text_size = render.text_size(percentage_font, text)
                local x = math.clamp(math.round(from.x + width - (text_size.x + 5)), from.x, to.x - text_size.x)
                render.text(text, percentage_font, v2(x, from.y + (to.y - from.y) / 2), col.white:alpha(text_alpha):salpha(alpha), render.flags.Y_ALIGN + render.flags.OUTLINE)
            end

            if progress == 1 and not remove_slider then
                once(function()
                    delay.add(function()
                        remove_slider = true
                    end, 750)
                end, "remove_slider")
            end

            if remove_slider then
                anims.slider_border_alpha(0)
                anims.slider_alpha(0)
                anims.text_y_offset(0)
                if not can_be_closed then
                    once(function()
                        delay.add(function()
                            can_be_closed = true
                        end, 1000)
                    end, "can_be_closed")
                end
            end
        end
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    logger:draw(ss / 2 + v2(0, 50 + slider_sizes.y))
end
cbs.add("paint", loading.draw)

return loading