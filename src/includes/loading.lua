local irender = require("libs.render")
local delay = require("libs.delay")
local v2 = require("libs.vectors")()
local col = require("libs.colors")
local cbs = require("libs.callbacks")
-- local nixware = require("includes.nixware")
local security = require("includes.security")
local once = require("libs.once").new()
-- local gui = require("includes.gui")
local easings = require("libs.easings")
local colors = require("includes.colors")
local logger = require("includes.logger").new({ infinite = true, console = true })
local fonts = require("includes.gui.fonts")
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
local loading = {
    skipped_lag = false,
    do_security = false,
    stopped = false,
    can_be_closed = false,
    remove_slider = false,
    close_delay = 1000,
    logo_font_size_addition = 0
}
security.logger = logger
loading.draw = function()
    once(function()
        delay.add(function ()
            loading.skipped_lag = true
        end, 400)
    end, "skip_lag")
    if not security.debug and not loading.skipped_lag then return end
    if loading.do_security then
        local _, err = pcall(security.init, logger)
        if err or security.error then
            once(function()
                loading.remove_slider = true
                loading.close_delay = 4000
                loading.stopped = true
                if not security.loaded then
                    engine.execute_client_cmd("showconsole")
                    logger.flags.console = false
                    logger:add({{"error. ", col.red}, {"see console for info"}})
                    logger.flags.console = true
                end
            end, "error")
        end
    end
    if anims.transparency() == 0 then
        if security.error then
            once(function ()
                -- client.unload_script(client.get_script_name())
            end, "unload_script")
        end
        return
    end

    if security.debug then
        loading.do_security = true
        return
    end

    local ss = render.screen_size()
    local slider_sizes = v2(300, 25)
    local main_alpha = 1
    once(function()
        -- menu.set_visible(false)
    end, "close_menu")
    if loading.can_be_closed then
        once(function()
            logger:clean()
        end, "clean_logger")
        main_alpha = anims.transparency(0) / 255
    end
    do
        local alpha = anims.bg_alpha(255) * main_alpha

        local c1, c2 = col.black:alpha(50):salpha(alpha), col.black:alpha(200):salpha(alpha)
        render.rect_filled_fade(v2(0, 0), v2(ss.x, ss.y), c1, c1, c2, c2)
    end
    if anims.bg_alpha.done then
        local y = ss.y / 2 + anims.slider_y_offset(35)
        local from = v2(ss.x / 2 - slider_sizes.x / 2, y):round()
        local to = v2(ss.x / 2 + slider_sizes.x / 2, y + slider_sizes.y):round()

        local slider_border_alpha = anims.slider_border_alpha()
        if not loading.remove_slider then
            slider_border_alpha = anims.slider_border_alpha(255)
        end
        slider_border_alpha = slider_border_alpha * main_alpha
        do
            local border_color = col.white:alpha(slider_border_alpha)
            irender.rounded_rect(from, to, border_color, 3.1)
            irender.rounded_rect(from - v2(1, 1), to + v2(1, 1), border_color:salpha(75), 4.1)
        end

        if anims.slider_y_offset.done then
            local progress = security.progress
            if progress == 100 then
                gui.init()
            end
            once(function()
                -- logger:add({{"magnolia", colors.magnolia}, {" by ", col.white}, {"lia", colors.magnolia}})
            end, "magnolia_start_log")
            local percentage = anims.progress(progress)
            if percentage == 100 then
                once(function()
                    logger:clean()
                    logger:add({{"with ", col.white}, {"magnolia", colors.magnolia}, {" by ", col.white}, {"lia", colors.magnolia}})
                    logger:add({{"have", col.white}, {" fun!", colors.magnolia}})
                    print("")
                end, "progress_done")
            end
            local alpha = anims.slider_alpha()
            if not loading.remove_slider then
                alpha = anims.slider_alpha(255)
            end
            local width = math.max(10, slider_sizes.x * anims.progress.value / 100)
            if percentage > 0 then
                irender.rounded_rect(from + v2(4, 4), v2(from.x + width, to.y) - v2(3, 3), colors.magnolia:salpha(alpha), 2.1, true)
            end
            local text_alpha = anims.text_alpha(255) * main_alpha

            if alpha >= 255 then
                once(function()
                    loading.do_security = true
                    -- logger:clean()
                end, "start_security")
            end

            local logo_animation = easings.quart.out(loading.logo_font_size_addition) * 40
            fonts.large_logo_font.size = 260 + math.round(logo_animation)
            irender.text("A",fonts.large_logo_font, v2(ss.x / 2, ss.y / 2), colors.magnolia:alpha(anims.bg_alpha() * main_alpha / 15), irender.flags.X_ALIGN + irender.flags.Y_ALIGN)
            irender.text("magnolia", fonts.magnolia_font, v2(ss.x / 2, ss.y / 2 - anims.text_y_offset()), col.white:alpha(text_alpha),
                irender.flags.X_ALIGN + irender.flags.Y_ALIGN + irender.flags.BIG_SHADOW)

            do
                local text = percentage .. "%"
                local text_size = irender.text_size(fonts.percentage_font, text)
                local x = math.clamp(math.round(from.x + width - (text_size.x + 5)), from.x + 10, to.x - text_size.x)
                irender.outline_text(text, fonts.percentage_font, v2(x, from.y + (to.y - from.y) / 2), col.white:alpha(text_alpha):salpha(alpha), irender.flags.Y_ALIGN)
            end

            if percentage == 100 then
                loading.logo_font_size_addition = math.clamp(loading.logo_font_size_addition + globals.frame_time * 1.5, 0, 1)
                once(function()
                    loading.remove_slider = true
                end, "remove_slider")
            end

            if loading.remove_slider then
                anims.slider_border_alpha(0)
                anims.slider_alpha(0)
                anims.text_y_offset(0)
                if not loading.can_be_closed then
                    once(function()
                        delay.add(function()
                            loading.can_be_closed = true
                            -- ui.set_visible(true)
                            if not security.error then
                                gui.can_be_visible = true
                            end
                        end, loading.close_delay)
                    end, "can_be_closed")
                end
            end
        end
    end
    logger:draw(ss / 2 + v2(0, 50 + slider_sizes.y))
end
cbs.paint(loading.draw)

return loading