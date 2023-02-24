local render = require("libs.render")
local delay = require("libs.delay")
local v2 = require("libs.vectors")()
local col = require("libs.colors")
local cbs = require("libs.callbacks")
-- local nixware = require("includes.nixware")
local security = require("includes.security")
local once = require("libs.once").new()
-- local gui = require("includes.gui")
local easings = require("libs.easings")
local logger = require("includes.logger").new({ infinite = true, console = true })
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
local logo_font_size_addition = 0
local loading = {}
local magnolia_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 80, 0)
local percentage_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, render.font_flags.MonoHinting)
local large_logo_font = render.font("nix/magnolia/icon.ttf", 250)
local can_be_closed = false
local remove_slider = false
local close_delay = 1000
loading.skipped_lag = false
loading.do_security = false
loading.stopped = false
loading.draw = function()
    once(function()
        delay.add(function ()
            loading.skipped_lag = true
        end, 200)
    end, "skip_lag")
    if not loading.skipped_lag then return end
    if loading.do_security then
        local _, err = pcall(security.init, logger)
        if err or security.error then
            once(function()
                if not security.loaded then
                    engine.execute_client_cmd("showconsole")
                    logger.flags.console = false
                    logger:add({{"error. ", col.red}, {"see console for info"}})
                    logger.flags.console = true
                end
                remove_slider = true
                close_delay = 3000
                loading.stopped = true
            end, "error")
        end
    end
    if anims.transparency() == 0 then return end

    if security.debug then
        once(function ()
            gui.init()
            gui.can_be_visible = true
        end, "debug_init")
        return
    end

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
            local progress = security.progress
            if progress == 100 then
                gui.init()
            end
            once(function()
                logger:add({{"magnolia", col.magnolia}, {" by ", col.white}, {"lia", col.magnolia}})
            end, "magnolia_start_log")
            local percentage = anims.progress(progress)
            if percentage == 100 then
                once(function()
                    logger:add({{"have", col.white}, {" fun!", col.magnolia}})
                    print("")
                end, "progress_done")
            end
            local alpha = anims.slider_alpha()
            if not remove_slider then
                alpha = anims.slider_alpha(255)
            end
            local width = math.max(10, slider_sizes.x * anims.progress.value / 100)
            if percentage > 0 then
                render.rounded_rect(from + v2(4, 4), v2(from.x + width, to.y) - v2(3, 3), col.magnolia:salpha(alpha), 2.1, true)
            end
            local text_alpha = anims.text_alpha(255) * main_alpha

            if alpha == 255 then
                once(function()
                    loading.do_security = true
                    logger:clean()
                end, "start_security")
            end

            local logo_animation = easings.quart.out(logo_font_size_addition) * 40
            large_logo_font.size = 260 + math.round(logo_animation)
            render.text("A", large_logo_font, v2(ss.x / 2, ss.y / 2), col.magnolia:alpha(anims.bg_alpha() * main_alpha / 15), render.flags.X_ALIGN + render.flags.Y_ALIGN)
            render.text("magnolia", magnolia_font, v2(ss.x / 2, ss.y / 2 - anims.text_y_offset()), col.white:alpha(text_alpha),
                render.flags.X_ALIGN + render.flags.Y_ALIGN + render.flags.BIG_SHADOW)

            do
                local text = percentage .. "%"
                local text_size = render.text_size(percentage_font, text)
                local x = math.clamp(math.round(from.x + width - (text_size.x + 5)), from.x + 10, to.x - text_size.x)
                render.text(text, percentage_font, v2(x, from.y + (to.y - from.y) / 2), col.white:alpha(text_alpha):salpha(alpha), render.flags.Y_ALIGN + render.flags.OUTLINE)
            end

            if percentage == 100 then
                logo_font_size_addition = math.clamp(logo_font_size_addition + globalvars.get_frame_time() * 1.5, 0, 1)
                once(function()
                    remove_slider = true
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
                            gui.can_be_visible = true
                        end, close_delay)
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