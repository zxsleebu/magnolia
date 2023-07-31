local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
-- jit.off()
-- jit.flush()
-- collectgarbage("stop")

math.randomseed(os.time())

require("includes.preload")
local errors = require("libs.error_handler")
errors.handler(function()
    require("includes.gui")
    local cbs = require("libs.callbacks")
    require("includes.loading")

    for callback_name, callback_fns in pairs(cbs.list) do
        client.register_callback(callback_name, function(...)
            for i = 1, #callback_fns do
                local callback = callback_fns[i]
                errors.handler(callback.fn, callback.name)(...)
            end
            if cbs.critical_list[callback_name] then
                for i = 1, #cbs.critical_list[callback_name] do
                    errors.handler(cbs.critical_list[callback_name][i])(...)
                end
            end
        end)
    end
end, "magnolia")()
client.register_callback("unload", function()
    clientstate.force_full_update()
end)
end)
__bundle_register("includes.loading", function(require, _LOADED, __bundle_register, __bundle_modules)
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
                client.unload_script(client.get_script_name())
            end, "unload_script")
        end
        return
    end

    if security.debug then
        loading.do_security = true
        return
    end

    local ss = engine.get_screen_size()
    local slider_sizes = v2(300, 25)
    local main_alpha = 1
    once(function()
        ui.set_visible(false)
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
        renderer.rect_filled_fade(v2(0, 0), v2(ss.x, ss.y), c1, c1, c2, c2)
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
            render.rounded_rect(from, to, border_color, 3.1)
            render.rounded_rect(from - v2(1, 1), to + v2(1, 1), border_color:salpha(75), 4.1)
        end

        if anims.slider_y_offset.done then
            local progress = security.progress
            if progress == 100 then
                gui.init()
            end
            once(function()
                logger:add({{"magnolia", colors.magnolia}, {" by ", col.white}, {"lia", colors.magnolia}})
            end, "magnolia_start_log")
            local percentage = anims.progress(progress)
            if percentage == 100 then
                once(function()
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
                render.rounded_rect(from + v2(4, 4), v2(from.x + width, to.y) - v2(3, 3), colors.magnolia:salpha(alpha), 2.1, true)
            end
            local text_alpha = anims.text_alpha(255) * main_alpha

            if alpha == 255 then
                once(function()
                    loading.do_security = true
                    logger:clean()
                end, "start_security")
            end

            local logo_animation = easings.quart.out(loading.logo_font_size_addition) * 40
            fonts.large_logo_font.size = 260 + math.round(logo_animation)
            render.text("A",fonts.large_logo_font, v2(ss.x / 2, ss.y / 2), colors.magnolia:alpha(anims.bg_alpha() * main_alpha / 15), render.flags.X_ALIGN + render.flags.Y_ALIGN)
            render.text("magnolia", fonts.magnolia_font, v2(ss.x / 2, ss.y / 2 - anims.text_y_offset()), col.white:alpha(text_alpha),
                render.flags.X_ALIGN + render.flags.Y_ALIGN + render.flags.BIG_SHADOW)

            do
                local text = percentage .. "%"
                local text_size = render.text_size(fonts.percentage_font, text)
                local x = math.clamp(math.round(from.x + width - (text_size.x + 5)), from.x + 10, to.x - text_size.x)
                render.outline_text(text, fonts.percentage_font, v2(x, from.y + (to.y - from.y) / 2), col.white:alpha(text_alpha):salpha(alpha), render.flags.Y_ALIGN)
            end

            if percentage == 100 then
                loading.logo_font_size_addition = math.clamp(loading.logo_font_size_addition + globalvars.get_frame_time() * 1.5, 0, 1)
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
                            ui.set_visible(true)
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
end)
__bundle_register("libs.anims", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.advanced math")

---@alias __anim_mt (fun(value: number, time?: number): number)|(fun(): number)|{ done: boolean, value: number }
local anim_mt = {
    __call = function(s, value, time)
        if value == nil then
            return math.round(s.value)
        end
        if s.value == nil then
            s.value = value
        end
        s.value = math.anim(s.value, value, time)
        s.done = math.round(s.value) == value
        return math.round(s.value)
    end,
}

local anims = {}
local anims_mt = { }
anims_mt.__index = function(s, k)
    local list = rawget(s, "list")
    local value = list[k]
    if value == nil then
        list[k] = setmetatable({}, anim_mt)
        value = list[k]
    end
    return value
end
anims_mt.__newindex = function(s, k, v)
    local list = rawget(s, "list")
    local value = anims_mt.__index(s, k)
    list[k].value = v
    list[k].done = true
    list[k].anims = s
    return value
end
---@alias __anims_mt { [string]: __anim_mt }
---@return __anims_mt
---@param values? { [string]: number }
anims.new = function(values)
    local t = { list = {} }
    setmetatable(t, anims_mt)
    for k, v in pairs(values or {}) do
        t[k] = v
    end
    return t
end
return anims
end)
__bundle_register("libs.advanced math", function(require, _LOADED, __bundle_register, __bundle_modules)
---@param v number
---@param min number
---@param max number
---@return number
math.clamp = function(v, min, max)
    return math.min(math.max(min, v), max)
end
---@param a number
---@param b number
---@param t number|nil
---@return number
math.anim = function (a, b, t)
    local anim = a + (b - a) * (globalvars.get_frame_time() * (t or 14))
    if a < b then
        anim = math.min(anim, b)
    else
        anim = math.max(anim, b)
    end
    return anim
end
---@param a number
---@return number
math.round = function(a)
    return math.floor(a + 0.5)
end
---@param a number
---@return number
math.deg2rad = function(a) return a * math.pi / 180.0 end
---@param yaw number
---@return number
math.normalize_yaw = function(yaw)
    yaw = yaw % 360.0
    if yaw > 180.0 then
        yaw = yaw - 360.0
    elseif yaw < -180.0 then
        yaw = yaw + 360.0
    end
    return yaw
end
end)
__bundle_register("includes.gui.fonts", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
local fonts = {
    logo = render.font("nix/magnolia/icon.ttf", 28),
    logo_shadow = render.font("nix/magnolia/icon.ttf", 32),
    tab_icons = render.font("nix/magnolia/icon.ttf", 16),
    header = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    menu = render.font("C:/Windows/Fonts/trebuc.ttf", 16, 0),
    label = render.font("C:/Windows/Fonts/trebuc.ttf", 16, 0),
    menu_small = render.font("C:/Windows/Fonts/trebuc.ttf", 13, 0),
    gamesense = render.font("C:/Windows/Fonts/verdana.ttf", 12, 128 + 16),
    slider = render.font("C:/Windows/Fonts/trebuc.ttf", 24, 0),
    slider_small = render.font("C:/Windows/Fonts/trebuc.ttf", 8, render.font_flags.ForceAutoHint),
    avatar_question = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, render.font_flags.Bold),
    title_icon = render.font("nix/magnolia/icon.ttf", 21),
    tab_title = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    subtab_title = render.font("C:/Windows/Fonts/trebucbd.ttf", 10, 0),
    menu_icons = render.font("nix/magnolia/icon.ttf", 22),
    magnolia_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 80, 0),
    percentage_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, render.font_flags.MonoHinting),
    large_logo_font = render.font("nix/magnolia/icon.ttf", 250),
    nade_warning = render.font("nix/magnolia/csgo.ttf", 18)
}
return fonts
end)
__bundle_register("libs.render", function(require, _LOADED, __bundle_register, __bundle_modules)
local v2, v3 = require("libs.vectors")()
local col = require("libs.colors")
-- local iengine = require("includes.engine")

local corner_angles = {
    {180, 270},
    {270, 360},
    {0, 90},
    {90, 180}
}

local render = {}

---@param pts vec2_t[]
---@param color color_t
---@param smoothing? boolean
---@param closed? boolean
render.polyline = function(pts, color, smoothing, closed)
    if smoothing == nil then smoothing = true end
    if closed or closed == nil then renderer.line(pts[#pts], pts[1], color) end
    for i = 1, #pts do
        if i % 2 == 1 or not smoothing then
            if pts[i-1] and smoothing then renderer.line(pts[i], pts[i-1], color) end
            if pts[i+1] then renderer.line(pts[i], pts[i+1], color) end
        end
    end
end
---@param pos vec2_t
---@param clr? color_t
---@param size? number
render.dot = function(pos, clr, size)
    size = size or 1
    clr = clr or col.red
    renderer.rect_filled(pos, pos + v2(size, size), clr)
end
---@param pos vec2_t
---@param radius number
---@param clr color_t
---@param start_angle number
---@param end_angle number
---@param filled? boolean
render.circle = function(pos, radius, clr, start_angle, end_angle, filled)
    start_angle = start_angle or 0
    end_angle = end_angle or 360
    local vertices = {}

    local step = end_angle >= start_angle and 10 or -10

    for i = start_angle, end_angle, step do
        local i_rad = math.rad(i)
        local point = pos + v2(math.cos(i_rad), math.sin(i_rad)) * radius
        vertices[#vertices+1] = point
    end
    for i = #vertices, 1, -1 do
        vertices[#vertices+1] = vertices[i]
    end
    if filled then
        return renderer.filled_polygon(vertices, clr)
    end
    render.polyline(vertices, clr)
end
---@param from vec2_t
---@param to vec2_t
---@param clr color_t
---@param r number
---@param filled? boolean
render.rounded_rect = function (from, to, clr, r, filled)
    r = r + 0.1
    local vertices = {}
    local pos = {
        v2(from.x + r, from.y + r),
        v2(to.x - r, from.y + r),
        v2(to.x - r, to.y - r),
        v2(from.x + r, to.y- r),
    }
    local i = 0
    for _, angles in pairs(corner_angles) do
        i = i + 1
        local step = angles[2] >= angles[1] and 10 or -10

        for a = angles[1], angles[2], step do
            local i_rad = math.rad(a)
            local point = pos[i] + v2(math.cos(i_rad), math.sin(i_rad)) * r
            vertices[#vertices+1] = point
        end
    end
    if filled then
        return renderer.filled_polygon(vertices, clr)
    end
    render.polyline(vertices, clr, true, true)
end
-- render.rounded_rect = function(from, to, clr, r, filled)
--     local x, y = from.x, from.y
--     local w, h = to.x - from.x, to.y - from.y
--     n = n or 20
--     if n % 4 > 0 then n = n + 4 - (n % 4) end
--     local pts, c, d, i = {}, {x + w / 2, y + h / 2}, {w / 2 - r, r - h / 2}, 0
--     local cos, sin, pi, ins = math.cos, math.sin, math.pi, table.insert
--     local ii = 0
--     while i < n do
--         local cur = v2(0, 0)
--         local a = i * 2 * pi / n
--         local p = {r * cos(a), r * sin(a)}
--         for j = 1, 2 do
--             if j == 1 then
--                 cur.x = c[j] + d[j] + p[j]
--             end
--             if j == 2 then
--                 cur.y = c[j] + d[j] + p[j]
--                 ins(pts, cur)
--             end
--             if p[j] * d[j] <= 0 and (p[1] * d[2] < p[2] * d[1]) then
--                 d[j] = d[j] * -1
--                 i = i - 1
--             end
--         end
--         i = i + 1
--         ii = ii + 1
--     end
--     if not filled then
--         return render.polyline(pts, clr, true, true) end
--     renderer.filled_polygon(pts, clr)
-- end
---@param from vec2_t
---@param to vec2_t
---@param clr color_t
---@param filled? boolean
render.smoothed_rect = function(from, to, clr, filled)
    if filled then
        renderer.rect_filled(from + v2(1, 0), to - v2(1, 0), clr)
        renderer.rect_filled(from + v2(0, 1), v2(from.x + 1, to.y - 1), clr)
        renderer.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), clr)
    else
        renderer.rect_filled(from + v2(1, 0), v2(to.x - 1, from.y + 1), clr)
        renderer.rect_filled(from + v2(0, 1), v2(from.x + 1, to.y - 1), clr)
        renderer.rect_filled(v2(from.x + 1, to.y - 1), to - v2(1, 0), clr)
        renderer.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), clr)
    end

    local new_col = clr:salpha(127)
    renderer.rect_filled(from, from + v2(1, 1), new_col)
    renderer.rect_filled(v2(to.x, from.y), v2(to.x - 1, from.y + 1), new_col)
    renderer.rect_filled(v2(from.x, to.y), v2(from.x + 1, to.y - 1), new_col)
    renderer.rect_filled(to - v2(1, 1), to, new_col)
end

---@class __font_t
---@field font font_t
---@field size number

local font_cache = {}
---@param name string
---@param size number
---@param flags? number
---@return __font_t
render.font = function(name, size, flags)
    local key = name .. size .. (flags or 0)
    if font_cache[key] then return font_cache[key] end
    local font = renderer.setup_font(name, size, flags or 0)
    font_cache[key] = {
        font = font,
        size = size
    }
    return font_cache[key]
end
render.font_flags = {
    NoHinting = 1,
    NoAutoHint = 2,
    ForceAutoHint = 4,
    LightHinting = 8,
    MonoHinting = 16,
    Bold = 32,
    Oblique = 64,
    Monochrome = 128,
}
render.flags = {
    X_ALIGN = 0x1,
    Y_ALIGN = 0x2,
    SHADOW = 0x4,
    MORE_SHADOW = 0x10,
    BIG_SHADOW = 0x20,
    RIGHT_ALIGN = 0x40,
    TEXT_SIZE = 0x80,
}
render.flags.CENTER = render.flags.X_ALIGN + render.flags.Y_ALIGN

---@param font __font_t
---@param text string
render.text_size = function(font, text)
    return renderer.get_text_size(font.font, font.size, text)
end
local outline_pos = {
    v2(0, 1),
    v2(1, 0),
    v2(0, -1),
    v2(-1, 0),
    v2(1, 1),
    v2(1, -1),
    v2(-1, 1),
    v2(-1, -1),
}

local process_flags = function (text, font, pos, flags)
    local new_pos = v2(pos.x, pos.y)
    if type(flags) == "table" then
        local int_flags = 0
        for _, flag in pairs(flags) do
            int_flags = int_flags + flag
        end
        flags = int_flags
    end
    local text_size
    --horizontal align
    if bit.band(flags, render.flags.X_ALIGN) == render.flags.X_ALIGN then
        text_size = text_size or render.text_size(font, text)
        new_pos.x = new_pos.x - text_size.x / 2
    end
    --vertical align
    if bit.band(flags, render.flags.Y_ALIGN) == render.flags.Y_ALIGN then
        text_size = text_size or render.text_size(font, text)
        new_pos.y = new_pos.y - text_size.y / 2
    end
    --right align
    if bit.band(flags, render.flags.RIGHT_ALIGN) == render.flags.RIGHT_ALIGN then
        text_size = text_size or render.text_size(font, text)
        new_pos.x = new_pos.x - text_size.x
    end
    --textsize
    if bit.band(flags, render.flags.TEXT_SIZE) == render.flags.TEXT_SIZE then
        text_size = text_size or render.text_size(font, text)
    end

    return new_pos, text_size
end

---@param text string
---@param font __font_t
---@param pos vec2_t
---@param color color_t
---@param flags? number
---@return vec2_t, vec2_t?
render.text = function(text, font, pos, color, flags)
    flags = flags or 0
    local new_pos, text_size = process_flags(text, font, pos, flags)

    local shadow = bit.band(flags, render.flags.SHADOW) == render.flags.SHADOW
    local more_shadow = bit.band(flags, render.flags.MORE_SHADOW) == render.flags.MORE_SHADOW
    local big_shadow = bit.band(flags, render.flags.BIG_SHADOW) == render.flags.BIG_SHADOW
    if shadow or more_shadow or big_shadow then
        local offset = 1
        if more_shadow then offset = 2 end
        if big_shadow then offset = 3 end
        renderer.text(text, font.font, new_pos + v2(offset, offset), font.size, col.black:alpha(150):salpha(color.a))
    end
    renderer.text(text, font.font, new_pos, font.size, color)
    return new_pos, text_size
end
---@param text string
---@param font __font_t
---@param pos vec2_t
---@param color color_t
---@param flags? number
---@param outline_color color_t?
---@return vec2_t, vec2_t?
render.outline_text = function (text, font, pos, color, flags, outline_color)
    flags = flags or 0
    local new_pos, text_size = process_flags(text, font, pos, flags)
    local clr = (outline_color or col.black:alpha(100)):salpha(color.a)
    for _, p in pairs(outline_pos) do
        renderer.text(text, font.font, new_pos + p, font.size, clr)
    end
    renderer.text(text, font.font, new_pos, font.size, color)
    return new_pos, text_size
end

---@param fn fun(): vec2_t, vec2_t?
---@param font __font_t
---@param size number
render.sized_text = function(fn, font, size)
    local old_size = font.size
    font.size = size
    local result1, result2 = fn()
    font.size = old_size
    return result1, result2
end
---@param strings { [1]: string, [2]: color_t }[]
---@param font __font_t
---@param pos vec2_t
---@param flags number
---@param alpha_multiplier number?
render.multi_color_text = function(strings, font, pos, flags, alpha_multiplier)
    if alpha_multiplier == nil then
        alpha_multiplier = 255
    end
    if bit.band(flags or 0, render.flags.X_ALIGN) == render.flags.X_ALIGN then
        local str = ""
        for i = 1, #strings do str = str .. strings[i][1] end
        pos.x = pos.x - render.text_size(font, str).x / 2
        flags = bit.band(flags, bit.bnot(render.flags.X_ALIGN))
    end
    for i = 1, #strings do
        local text, color = strings[i][1], strings[i][2]:salpha(alpha_multiplier)
        render.text(text, font, pos, color, flags)
        pos.x = pos.x + render.text_size(font, text).x
    end
end

---@param strings { [1]: string, [2]: color_t }[]
---@param font __font_t
render.multi_text_size = function(strings, font)
    local str = ""
    for i = 1, #strings do str = str .. strings[i][1] end
    return render.text_size(font, str)
end

---@param from vec2_t
---@param to vec2_t
---@param color color_t
---@param radius number
---@param opacity? number
---@param spreading? number
---@param steps? number
render.box_shadow = function(from, to, color, radius, opacity, steps, spreading)
    spreading = spreading or 2
    steps = steps or 4
    opacity = opacity or 15
    for i = 1, steps do
        render.rounded_rect(
            from - v2(spreading * i, spreading * i),
            to + v2(spreading * i, spreading * i),
            color:salpha(opacity / i),
            math.min(math.ceil(radius * i + 1), 20),
            true
        )
    end
end

return render
end)
__bundle_register("libs.colors", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.advanced math")
---@class color_t
---@field fade fun(s: color_t, new_color: color_t, factor: number): color_t
---@field alpha fun(s: color_t, new_alpha: number): color_t
---@field salpha fun(s: color_t, float_multiplier: number): color_t
-- -@field alpha_diff fun(s: color_t, alpha: number, diff: number): color_t
---@field alpha_anim fun(s: color_t, alpha: number, from: number, to: number): color_t

---@type (fun(r: number, g: number, b: number, a?: number): color_t)|{ red: color_t, green: color_t, blue: color_t, black: color_t, white: color_t, transparent: color_t, gray: color_t }
local col = setmetatable({}, {
    __index = {
        red = color_t.new(255, 127, 127, 255),
        green = color_t.new(127, 255, 127, 255),
        blue = color_t.new(127, 127, 255, 255),
        white = color_t.new(255, 255, 255, 255),
        black = color_t.new(0, 0, 0, 255),
        gray = color_t.new(15, 15, 15, 255),
        transparent = color_t.new(0, 0, 0, 0),
    },
    __call = function(s, r, g, b, a)
        return color_t.new(r, g, b, a or 255)
    end,
})



local lerp = function(a, b, t)
    return a + (b - a) * t
end
local color_mt = getmetatable(color_t.new(0, 0, 0, 0))
local orig_index = color_mt.__index
local alpha = function(s, a)
    return color_t.new(s.r, s.g, s.b, a)
end
color_mt.__index = function(s, k)
    if k == "alpha" then
        return alpha
    end
    local raw = orig_index(s, k)
    if raw then return raw end
    local real_key = ""
    if k == "r" then
        real_key = "red"
    elseif k == "g" then
        real_key = "green"
    elseif k == "b" then
        real_key = "blue"
    elseif k == "a" then
        real_key = "alpha"
    end
    if real_key ~= "" then
        return math.round(orig_index(s, real_key) * 255)
    end
end
color_mt.__tostring = function(s)
    return string.format("color_t(%d, %d, %d, %d)", s.r, s.g, s.b, s.a)
end

color_t.fade = function(a, b, t)
    return color_t.new(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t))
end
color_t.salpha = function(s, a)
    if not a then error("no alpha given to color_t:alpha", 2) end
    return color_t.new(s.r, s.g, s.b, math.clamp((s.a / 255) * a, 0, 255))
end
-- ---@param s color_t
-- color_t.alpha_diff = function(s, a, diff)
--     return s:salpha(((a / 255) * diff) + (255 - diff))
-- end
---@param s color_t
color_t.alpha_anim = function(s, a, from, to)
    return s:salpha(((a / 255) * (to - from)) + from)
end
return col
end)
__bundle_register("libs.vectors", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.advanced math")

---@class vec2_t
---@operator add(vec2_t): vec2_t
---@operator sub(vec2_t): vec2_t
---@operator mul(number|vec2_t): vec2_t
---@operator sub(number|vec2_t): vec2_t
---@operator unm(): vec2_t
---@operator len(): number
---@field clamp fun(self: vec2_t, min: vec2_t, max: vec2_t): vec2_t
---@field round fun(self: vec2_t): vec2_t

---@class vec3_t
---@operator add(vec3_t): vec3_t
---@operator sub(vec3_t): vec3_t
---@operator mul(number|vec3_t): vec3_t
---@operator sub(number|vec3_t): vec3_t
---@operator unm(): vec3_t
---@operator len(): number
---@field remove_nan fun(self: vec3_t): vec3_t
---@field dist_to fun(self: vec3_t, other: vec3_t): number
---@field round fun(self: vec3_t): vec3_t
---@field dot fun(self: vec3_t, other: vec3_t): number
---@field length_sqr fun(self: vec3_t): number
---@field normalize fun(self: vec3_t): vec3_t
---@field pairs fun(self: vec3_t): { x: number, y: number, z: number }
---@field angle_to fun(self: vec3_t, to: vec3_t): angle_t


---@type fun(x: number, y: number): vec2_t
local v2 = vec2_t.new
---@type fun(x: number, y: number, z: number): vec3_t
local v3 = vec3_t.new

vec2_t.__unm = function(a)
    return v2(-a.x, -a.y)
end
vec2_t.__tostring = function(a)
    return "vec2_t("..a.x..", "..a.y..")"
end
vec2_t.__len = function (a)
    return (a.x ^ 2 + a.y ^ 2) ^ 0.5
end
vec2_t.clamp = function(s, min, max)
    return v2(math.clamp(s.x, min.x, max.x), math.clamp(s.y, min.y, max.y))
end
vec2_t.round = function(s)
    return v2(math.round(s.x), math.round(s.y))
end
vec3_t.__unm = function(a)
    return v3(-a.x, -a.y, -a.z)
end
vec3_t.__tostring = function(a)
    return "vec3_t("..a.x..", "..a.y..", "..a.z..")"
end
vec3_t.dot = function(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end
vec3_t.length_sqr = function(self)
    return self:dot(self)
end
vec3_t.__len = function (self)
    return self:length_sqr() ^ 0.5
end
---@param to vec3_t
---@return angle_t
vec3_t.angle_to = function(self, to)
    local delta = to - self
    local yaw = math.deg(math.atan2(delta.y, delta.x))
    local pitch = math.deg(math.atan2(delta.z, #delta))
    return angle_t.new(pitch, yaw, 0)
end

vec3_t.remove_nan = function(self)
    if self.x ~= self.x then self.x = 0 end
    if self.y ~= self.y then self.y = 0 end
    if self.z ~= self.z then self.z = 0 end
    return self
end
---@param a vec3_t
vec3_t.dist_to = function(self, a)
    return #(self - a)
end
vec3_t.round = function(self)
    return v3(math.round(self.x), math.round(self.y), math.round(self.z))
end
vec3_t.pairs = function(self)
    return pairs({x = self.x, y = self.y, z = self.z})
end
vec3_t.normalize = function(self)
    local len = #self
    if len == 0 then return self end
    return self / len
end

---@class angle_t
---@field to_vec fun(self: angle_t): vec3_t

---@param self angle_t
angle_t.to_vec = function (self)
    local pitch, yaw = math.rad(self.pitch), math.rad(self.yaw)
    local pcos = math.cos(pitch)
    return v3(pcos * math.cos(yaw), pcos * math.sin(yaw), -math.sin(pitch)):remove_nan()
end

return function()
    return v2, v3
end

end)
__bundle_register("includes.logger", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
local v2 = require("libs.vectors")()
local col = require("libs.colors")
local anims = require("libs.anims")
local lib_engine = require("includes.engine")

local log_t = {
    __index = {
        remove = function(s)
            s.time = 0
        end,
    }
}
---@alias __logger_flags_t { infinite?: boolean, console?: boolean }|nil
local logger_font = render.font("C:/Windows/Fonts/trebuc.ttf", 14, 0)
local logger_t = {
    ---@class logger_t
    ---@field flags __logger_flags_t
    __index = {
        ---@param text string|{ [number]: {[1]: string, [2]: color_t} }
        ---@param time? number
        ---@param flags __logger_flags_t
        add = function(s, text, time, flags)
            flags = flags or {}
            local t = {}
            t.anims = anims.new({
                alpha = 0,
                y_offset = 0,
            })
            t.text = text
            for i = 1, #t.text do
                if not t.text[i][2] then
                    t.text[i][2] = col.white
                end
            end
            t.time = globalvars.get_real_time() + (time or 4000) / 1000
            if s.flags.infinite and not time then
                t.time = -1
            end
            if s.flags.console or flags.console then
                lib_engine.log(text)
            end
            if time == -1 then
                t.time = -1
            end
            setmetatable(t, log_t)
            s.list[#s.list+1] = t
        end,
        clean = function(s)
            for i = 1, #s.list do
                s.list[i]:remove()
            end
        end,
        is_animating = function (s)
            for i = 1, #s.list do
                local log = s.list[i]
                local alpha = log.anims.alpha()
                if alpha ~= 255 and alpha ~= 0 then
                    return true
                end
            end
        end,
        ---@param pos vec2_t
        draw = function(s, pos)
            local y = pos.y
            for i = #s.list, 1, -1 do
                local log = s.list[i]
                local active = globalvars.get_real_time() < log.time
                if log.time == -1 then active = true end
                local alpha = log.anims.alpha(active and 255 or 0)
                local y_offset = log.anims.y_offset((active or alpha > 0) and 15 or 0)
                local text = log.text
                for t = 1, #text do
                    text[t][2] = text[t][2]:alpha(alpha)
                end
                if alpha > 0 then
                    render.multi_color_text(log.text, logger_font, v2(pos.x, y), render.flags.X_ALIGN + render.flags.SHADOW)
                end
                y = y + y_offset
            end
        end,
    }
}
local logger = {
    ---@param flags __logger_flags_t
    new = function (flags)
        local t = {
            list = {},
            flags = flags or {}
        }
        return setmetatable(t, logger_t)
    end
}

return logger
end)
__bundle_register("includes.engine", function(require, _LOADED, __bundle_register, __bundle_modules)
local interface, class = require("libs.interfaces")()
require("libs.types")
local col = require("libs.colors")
local colors = require("includes.colors")
local v2, v3 = require("libs.vectors")()
ffi.cdef[[
    typedef struct {
        void* Client;
        void* User;
        void* Friends;
        void* Utils;
    } SteamAPIContext;
    typedef float Matrix4x4[4][4];
]]
local IEngineCVar = interface.new("vstdlib", "VEngineCvar007", {
    PrintColor = {25, "void(__cdecl*)(void*, const color_t&, PCSTR, ...)"},
})
local IEngineClient = interface.new("engine", "VEngineClient014", {
    GetNetChan = {78, "void*(__thiscall*)(void*)"},
    GetSteamContext = {185, "const SteamAPIContext*(__thiscall*)(void*)"},
    GetWorldToScreenMatrix = {37, "const Matrix4x4&(__thiscall*)(void*)"}
})
local IDebugOverlay = interface.new("engine", "VDebugOverlay004", {
    AddBoxOverlay = {1, "void(__thiscall*)(void*, const vector_t&, const vector_t&, const vector_t&, const vector_t&, int, int, int, int, float)"},
    AddLineOverlay = {5, "void(__thiscall*)(void*, const vector_t&, const vector_t&, int, int, int, bool, float)"},
    WorldToScreen = {13, "int(__thiscall*)(void*, const vector_t&, vector_t&)"}
})
local NetChanClass = class.new({
    GetName = {0, "PCSTR(__thiscall*)(void*)"},
    GetAddress = {1, "PCSTR(__thiscall*)(void*)"},
    SendNetMsg = {40, "bool(__thiscall*)(void*, void*, bool, bool)"}
})
local lib_engine = {}
lib_engine.get_csgo_folder = function()
    local source = debug.getinfo(1, "S").source:sub(2, -1)
    return source:match("^(.-)nix/") or source:match("^(.-)lua\\")
end
lib_engine.get_steam_context = function ()
    return IEngineClient:GetSteamContext()
end
lib_engine.print_color = function (text, clr, ...)
    local c = ffi.new("color_t")
    c.r, c.g, c.b, c.a = clr.r, clr.g, clr.b, clr.a
    IEngineCVar:PrintColor(c, text, ...)
end
lib_engine.print = function (text)
    for i = 1, #text do
        local args = {}
        for j = 3, #text[i] do
            args[#args+1] = text[i][j]
        end
        lib_engine.print_color(text[i][1] or "", text[i][2] or col.white, unpack(args))
    end
end
local brackets_color = col(242, 217, 170)
lib_engine.log = function (text)
    local t = {
        {"[ ", brackets_color},
        {"magnolia", colors.magnolia},
        {" ] ", brackets_color},
    }
    if type(text) == "string" then
        t[#t+1] = {text}
    else
        for i = 1, #text do
            t[#t+1] = text[i]
        end
    end
    t[#t+1] = {"\n"}
    lib_engine.print(t)
end
lib_engine.get_net_chan = function()
    if not engine.is_connected() then return end
    local netchan = IEngineClient:GetNetChan()
    if not netchan then return end
    netchan = NetChanClass(netchan)
    return netchan
end
---@return {ip: string, name: string}?
lib_engine.get_server_info = function ()
    if not engine.is_connected() then return end
    local netchan = IEngineClient:GetNetChan()
    if not netchan then return end
    netchan = NetChanClass(netchan)
    local address, name = netchan:GetAddress(), netchan:GetName()
    if name == nil or address == nil then return end
    return {
        ip = ffi.string(address),
        name = ffi.string(name),
    }
end
lib_engine.send_net_msg = function(msg)
    local netchan = lib_engine.get_net_chan()
    if not netchan then return end
    netchan:SendNetMsg(msg, false, true)
end
---@param pos vec3_t
---@return vec2_t?
lib_engine.world_to_screen = function(pos)
    local world_pos = ffi.new("vector_t[1]")
    world_pos[0].x, world_pos[0].y, world_pos[0].z = pos.x, pos.y, pos.z
    local screen_pos = ffi.new("vector_t[1]")
    IDebugOverlay:WorldToScreen(world_pos, screen_pos)
    return v2(screen_pos[0].x, screen_pos[0].y)
end

lib_engine.add_box_overlay = function(pos, time, color)
    local p = ffi.new("vector_t")
    p.x, p.y, p.z = pos.x, pos.y, pos.z
    local n = ffi.new("vector_t")
    n.x, n.y, n.z = -2, -2, -2
    local x = ffi.new("vector_t")
    x.x, x.y, x.z = 2, 2, 2
    local a = ffi.new("vector_t")
    a.x, a.y, a.z = 0, 0, 0
    IDebugOverlay:AddBoxOverlay(p, n, x, a, color.r, color.g, color.b, color.a, time)
end

lib_engine.add_line_overlay = function (from, to, time, color)
    local p = ffi.new("vector_t")
    p.x, p.y, p.z = from.x, from.y, from.z
    local d = ffi.new("vector_t")
    d.x, d.y, d.z = to.x, to.y, to.z
    IDebugOverlay:AddLineOverlay(p, d, color.r, color.g, color.b, true, time)
end

do
    local hitboxes = {
        [0] = "head", "head",
        "pelvis", "stomach",
        "lower chest", "chest", "upper chest",
        "left leg", "right leg",
        "left leg", "right leg",
        "left foot", "right foot",
        "left arm", "right arm",
        "left arm", "left arm",
        "right arm", "right arm",
        "wtf"
    }
    ---@param index number
    ---@return "head"|"pelvis"|"stomach"|"lower chest"|"chest"|"upper chest"|"left leg"|"right leg"|"left foot"|"right foot"|"left arm"|"right arm"|"wtf"
    lib_engine.get_hitbox_name = function(index)
        return hitboxes[index]
    end
    local hitgroups = {
        [0] = "generic",
        "head",
        "chest", "stomach",
        "left arm", "right arm",
        "left leg", "right leg",
        "wtf"
    }
    ---@param index number
    ---@return "generic"|"head"|"chest"|"stomach"|"left arm"|"right arm"|"left leg"|"right leg"|"wtf"
    lib_engine.get_hitgroup_name = function (index)
        return hitgroups[index]
    end
    local hitgroup_to_hitbox = {
        [0] = 5, --generic
        0, --head
        6, --chest
        4, --stomach
        16, --left arm
        18, --right arm
        7, --left leg,
        8, --right leg
        3 -- gear (wtf)
    }
    lib_engine.hitgroup_to_hitbox = function(i)
        return hitgroup_to_hitbox[i] or 5
    end
    local hitbox_to_hitgroup = {
        [0] = 1,
        2, 3, 2, 2, 2,
        6, 7, 6, 7, 6, 7,
        4, 5, 4, 4, 5, 5
    }
    lib_engine.hitbox_to_hitgroup = function(i)
        return hitbox_to_hitgroup[i] or 0
    end
end
lib_engine.time_to_ticks = function(time)
    return math.floor(time / globalvars.get_interval_per_tick() + 0.5)
end
lib_engine.ticks_to_time = function(ticks)
    return ticks * globalvars.get_interval_per_tick()
end
return lib_engine
end)
__bundle_register("includes.colors", function(require, _LOADED, __bundle_register, __bundle_modules)
local colors_t = {
    magnolia = color_t.new(242, 227, 201, 255),
    magnolia_tinted = color_t.new(31, 29, 26, 255),
    container_bg = color_t.new(23, 22, 20, 255),
}
return colors_t
end)
__bundle_register("libs.types", function(require, _LOADED, __bundle_register, __bundle_modules)
ffi.cdef[[
    typedef unsigned long DWORD;
    typedef unsigned short WORD;
    typedef unsigned long ULONG_PTR;
    typedef ULONG_PTR SIZE_T;
    typedef void* HANDLE;
    typedef int BOOL;
    typedef struct{
        char r, g, b, a;
    } color_t;
    typedef struct{
        float x, y, z;
    } vector_t;
    typedef const wchar_t* LPCWSTR;
    typedef LPCWSTR PCWSTR;
    typedef unsigned int UINT;
    typedef const char* PCSTR;
    typedef unsigned char BYTE;
]]
end)
__bundle_register("libs.interfaces", function(require, _LOADED, __bundle_register, __bundle_modules)
local errors = require("libs.error_handler")
-- local ffi = require("ffi")
local protected_ffi = require("libs.protected_ffi")
---@class class_t
---@field this ffi.ctype*
---@field ptr number
require("libs.types")
local class_t = {
    __call = errors.handler(function(s, classptr)
        local fns = s.__functions
        if not classptr then return end
        local ptr = ffi.cast("void***", classptr)
        if not s.__pointers then
            s.__pointers = {}
            for fn_name, data in pairs(fns) do
                ---@cast data {[1]: number, [2]: string}
                local index = data[1]
                local cast_type = data[2]
                local casted_fn = ffi.cast(cast_type, ptr[0][index])
                s.__pointers[fn_name] = function (class, ...)
                    return casted_fn(class.this, ...)
                end
            end
        end
        local result = setmetatable({}, { __index = s.__pointers })
        result.this = ptr
        result.ptr = ffi.cast("uintptr_t", ptr)
        return result
    end, "class_t.__call")
}
local class = {
    ---@generic T
    ---@param fns T
    ---@return (fun(classptr: ffi.ctype*|number): class_t|T)|{__functions: T}
    new = function(fns)
        local result = {}
        result.__functions = fns
        ---@diagnostic disable-next-line: return-type-mismatch
        return setmetatable(result, class_t)
    end
}

local interface = {
    ---@generic T
    ---@type fun(module: string, name: string, fns: T): class_t|T
    new = function(module, name, fns)
        local ptr = se.create_interface(module .. ".dll", name)
        if not ptr then
            return print("[error] can't find " .. name .. " interface in " .. module .. ".dll")
        end
        return class.new(fns)(ptr)
    end
}

return function()
    return interface, class
end
end)
__bundle_register("libs.protected_ffi", function(require, _LOADED, __bundle_register, __bundle_modules)
local offi = ffi
local is_hooked = function()
    --!ADD THE CHECK HERE
end
local protected_mt = {
    new = function(original_table)
        return {
            __index = function(_, k)
                local v = original_table[k]
                if type(v) == "function" then
                    return nil
                end
                return v
            end
        }
    end
}
local ffi = {
    cast = function(ctype, obj)
        local casted = offi.cast(ctype, obj)
        if type(casted) == "function" then
            return nil
        end
        return casted
    end,
    load = function(lib)
        return setmetatable({}, protected_mt.new(offi.load(lib)))
    end,
    C = setmetatable({}, protected_mt.new(offi.C)),
    typeof = offi.typeof,
    metatype = offi.metatype,
    new = offi.new,
    string = offi.string,
    sizeof = offi.sizeof,
    alignof = offi.alignof,
    offsetof = offi.offsetof,
    istype = offi.istype,
    copy = offi.copy,
    fill = offi.fill,
    cdef = offi.cdef,
    gc = offi.gc,
}

return ffi
end)
__bundle_register("libs.error_handler", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.types")
local col = require("libs.colors")

local IEngineCVar = ffi.cast("void***", se.create_interface("vstdlib.dll", "VEngineCvar007"))
local print_color_native = ffi.cast("void(__cdecl*)(void*, const color_t&, PCSTR, ...)", IEngineCVar[0][25])
local print_color = function (text, clr, ...)
    local c = ffi.new("color_t")
    c.r, c.g, c.b, c.a = clr.r, clr.g, clr.b, clr.a
    print_color_native(IEngineCVar, c, text, ...)
end
local print_multi = function (text)
    for i = 1, #text do
        local args = {}
        for j = 3, #text[i] do
            args[#args+1] = text[i][j]
        end
        print_color(text[i][1] or "", text[i][2] or color_t.new(255, 255, 255, 255), unpack(args))
    end
end
local brackets_color = color_t.new(242, 217, 170, 255)
local magnolia = color_t.new(242, 227, 201, 255)
local log = function (text)
    local t = {
        {"[ ", brackets_color},
        {"magnolia", magnolia},
        {" ] ", brackets_color},
    }
    if type(text) == "string" then
        t[#t+1] = {text}
    else
        for i = 1, #text do
            t[#t+1] = text[i]
        end
    end
    t[#t+1] = {"\n"}
    print_multi(t)
end

local errors = {}

---@param err string
---@param name? string
errors.report = function(err, name)
    local red = col(255, 75, 75)
    if name then
        log({
            {"[ ", red},
            {"error", col.red},
            {" ] in ", red},
            {name, col.red},
            {": ", red},
            {err, col.white}
        })
    else
        log({
            {"[ ", red},
            {"error", col.red},
            {" ] ", red},
            {err, col.white}
        })
    end
end

---@generic T
---@param fn T
---@param name? string
---@return T
errors.handler = function(fn, name)
    return function(...)
        local ok, err, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 = pcall(fn, ...)
        if not ok then
            --remove ...r-Strike Global Offensive\lua\ from the error message
            ---@cast err string
            -- err = err:gsub(".....r-Strike Global Offensive\\lua\\", "")
            if err:sub(1, 1) == "." then
                err = err:gsub("%.%.%..-\\lua\\", "")
            end
            --get traceback
            local traceback = debug.traceback()
            errors.report(err .. "\n" .. traceback, name)
        end
        return err, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
    end
end

---@generic T
---@param fn T
---@param name? string
errors.handle = function(fn, name)
    return errors.handler(fn, name)()
end

return errors
end)
__bundle_register("libs.easings", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	["linear"] = function(x) return x end,
	["sine"] = { --1
		["in"] = function(x) return 1 - math.cos((x * math.pi) / 2) end,
		["out"] = function(x) return math.sin((x * math.pi) / 2) end,
		["inout"] = function(x) return -(math.cos(math.pi * x) - 1) / 2 end,
	},
	["quad"] = { --2
		["in"] = function(x) return x * 2 end,
		["out"] = function(x) return 1 - ((1 - x) ^ 2) end,
		["inout"] = function(x) return (x < 0.5) and (2 * x * x) or (1 - ((-2 * x + 2) ^ 2) / 2) end,
	},
	["cubic"] = { --3
		["in"] = function(x) return x ^ 3 end,
		["out"] = function(x) return 1 - ((1 - x) ^ 3) end,
		["inout"] = function(x) return (x < 0.5) and (4 * (x ^ 3)) or (1 - ((-2 * x + 2) ^ 3) / 2) end,
	},
	["quart"] = { --4 самые красивые
		["in"] = function(x) return x ^ 4 end,
		["out"] = function(x) return 1 - ((1 - x) ^ 4) end,
		["inout"] = function(x) return (x < 0.5) and (8 * (x ^ 4)) or (1 - ((-2 * x + 2) ^ 4) / 2) end,
	},
	["quint"] = { --5
		["in"] = function(x) return x ^ 5 end,
		["out"] = function(x) return 1 - ((1 - x) ^ 5) end,
		["inout"] = function(x) return (x < 0.5) and (16 * (x ^ 5)) or (1 - ((-2 * x + 2) ^ 5) / 2) end,
	}
}
end)
__bundle_register("libs.once", function(require, _LOADED, __bundle_register, __bundle_modules)
local once = {
    ---@return fun(fn: fun(), name: string)
    new = function()
        local t = {}
        ---@diagnostic disable-next-line: return-type-mismatch
        return setmetatable(t, {
            __call = function(s, func, id)
                if not s[id] then
                    s[id] = true
                    func()
                end
            end,
        })
    end
}

return once
end)
__bundle_register("includes.security", function(require, _LOADED, __bundle_register, __bundle_modules)
local http = require("libs.http")
local offi = ffi
local json = require("libs.json")
local col = require("libs.colors")
local colors = require("includes.colors")
local errors = require("libs.error_handler")
local get_hwid = require("libs.hwid")
local once = require("libs.once").new()
local cbs = require("libs.callbacks")
local utf8 = require("libs.utf8")
local iengine = require("includes.engine")
local ws = require("libs.websocket")
local sockets = require("libs.sockets")
local win32 = require("libs.win32")
local set = require("libs.set")
local security = {
    debug_sockets = false,
    debug = true,
    debug_logs = true,
    release_server = false,
    key = "",
    progress = 0,
    logger = false, ---@type logger_t
    loaded = false,
    websocket = false, ---@type __websocket_t
    domain = "localhost",
    authorized = false,
    stopped = false,
    sub_expires = 0,
}
if security.release_server then
    security.domain = "site--main--44fhg5c78hhm.code.run"
end
security.url = "http://" .. security.domain .. "/server/"
security.socket_url = "ws://localhost:3000"
if security.release_server then
    security.socket_url = "wss://socket--main--44fhg5c78hhm.code.run:443"
end
security.is_file_exists = function(path)
    local file = io.open(path, "r")
    if file then file:close() return true end
    return false
end
-- security.download_resource = function(name)
--     local path = "nix/magnolia/" .. name
--     if security.is_file_exists(name) then return end
--     http.download(security.url .. "resources/" .. name, path)
-- end

security.decrypt = errors.handler(function(str)
    local key = security.key
    local c = 0
    return str:gsub("[G]-([0-9A-F]+)", function(a)
        c = c + 1
        return utf8.char(bit.bxor(tonumber(a, 16), key:byte(c % #key + 1)))
    end)
end, "security.decrypt")

security.encrypt = errors.handler(function(str)
    local key = security.key
    local c = 0
    return utf8.map(str, function(char)
        c = c + 1
        return string.format("%X", bit.bxor(utf8.byte(char) or 0, key:byte(c % #key + 1))) .. "G"
    end):sub(1, -2)
end, "security.encrypt")
security.get_info = function()
    return {
        username = client.get_username(),
        hwid = get_hwid(),
        info = {
            computer = win32.get_env("COMPUTERNAME"),
            username = win32.get_env("USERNAME"),
        },
    }
end

security.large_data = {}
security.handlers = {
    ---@type table<string, fun(socket: __websocket_t, data: any)>
    client = {},
    ---@type table<string, fun(socket: __websocket_t, data: any)>
    server = {},
}
security.handlers.client.auth = function(socket)
    local info = security.get_info()
    local stringified = json.encode({
        type = "auth",
        data = info
    })
    if security.debug_logs then
        -- lib_engine.log("sending auth request: " .. stringified)
    end
    socket:send(security.encrypt(stringified))
end
security.handlers.server.auth = function(socket, data)
    if data.result == "success" then
        security.authorized = true
        sockets.encrypt = security.encrypt
        sockets.init(socket)
    end
    security.loaded = true
    security.logger.flags.console = true
    if data.result == "sub" then
        security.logger:add({ { "your subcription ended. ", col.red }, { "consider buying " }, { "magnolia", colors.magnolia }, { "!" } })
        error("sub", 0)
    end
    if data.result == "banned" then
        security.logger:add({ {"lmao you were "} , { "banned", col.red } })
        error("banned", 0)
    end
    if data.result == "hwid" then
        security.logger:add({ { "hwid error. ", col.red }, { "hwid reset request created" } })
        error("hwid", 0)
    end
    if data.result == "not_found" then
        -- security.logger:add({ { "buy magnolia!", colors.magnolia } })
        -- error("user not found", 0)
    end
    security.logger.flags.console = true
end
security.handshake_success = false
security.handlers.server.handshake = function(socket, data)
    if data.result then
        -- security.logger:add({ { "handshake succeeded" } })
        security.handshake_success = true
        security.handlers.client.auth(socket)
    end
end
security.handlers.server.secret = function(socket, data)
    security.logger.flags.console = false
    security.logger:clean()
    security.logger:add({ {"paste it into the discord bot and get "}, { "free sub", colors.magnolia} })
    security.logger:add({ {"secret key was "}, {"copied to the clipboard", colors.magnolia}, {"!"} })
    security.logger.flags.console = true
    iengine.log({{"secret key: "}, {data.data, colors.magnolia}})
    security.loaded = true
    win32.copy_to_clipboard(data.data)
    error("secret", 0)
end
security.handlers.server.user = function(socket, data)
    security.sub_expires = data.expires
    security.discord_username = data.discord
end
security.handlers.client.handshake = function(socket, data)
    local split = {}
    for str in string.gmatch(data, "([^G]+)") do
        split[#split + 1] = str
    end
    for i = 1, #split, 2 do
        security.key = security.key .. string.char(tonumber(split[i], 16))
    end
    local handshake = ""
    for i = 2, #split, 2 do
        handshake = handshake .. split[i] .. "G"
    end
    handshake = security.decrypt(handshake:sub(1, -2))
    local encoded = json.encode({
        type = "handshake",
        data = handshake
    })
    socket:send(security.encrypt(encoded))
end

---@param socket __websocket_t
---@param data string
---@param length number
security.handle_data = function(socket, data, length)
    if security.key == "" then
        return security.handlers.client.handshake(socket, data)
    end
    if data == "handshake failed" then
        security.logger:add({ { "handshake failed", col.red } })
    end
    local first = data:sub(1, 1)
    local last = data:sub(-1)
    if first ~= "X" or last ~= "X" then
        security.large_data[#security.large_data + 1] = data
        if last == "X" then
            data = table.concat(security.large_data)
            security.large_data = {}
        else
            return
        end
    end
    local decrypted = security.decrypt(data:sub(2, -2))
    local _, decoded = pcall(json.decode, decrypted)
    if security.debug_logs then
        iengine.log("received: " .. decrypted)
    end
    if decoded then
        if set({"handshake", "auth", "secret", "user"})[decoded.type] then
            security.handlers.server[decoded.type](socket, decoded)
            return
        end
        if sockets.callbacks[decoded.type] then
            sockets.callbacks[decoded.type](decoded)
        end
    end
end
security.handshake_start = function(socket)
    socket:send("handshake")
end
do
    local got_sockets = false
    local websocket_path = nil
    local crypto_lib, ssl_lib = false, false
    local csgo = iengine.get_csgo_folder()
    security.get_sockets = function()
        once(function()
            http.download(security.url .. "resources/libcrypto-3.dll", csgo .. "libcrypto-3.dll", function (path)
                if not path then
                    security.logger:add({ { "failed to get libcrypto", col.red } })
                    security.error = true
                    return
                end
                crypto_lib = true
            end)
            http.download(security.url .. "resources/libssl-3.dll", csgo .. "libssl-3.dll", function (path)
                if not path then
                    security.logger:add({ { "failed to get libssl", col.red } })
                    security.error = true
                    return
                end
                ssl_lib = true
            end)
            if security.debug_sockets then
                websocket_path = "lua/sockets.dll"
                return
            end
            http.download(security.url .. "resources/sockets.dll", nil, function (path)
                if not path then
                    security.logger:add({ { "failed to get sockets", col.red } })
                    security.error = true
                end
                --!hack to not execute any long running code in the callback to avoid a crash
                websocket_path = path
            end)
        end, "download_sockets")
        return got_sockets
    end
    cbs.paint(function ()
        if websocket_path and crypto_lib and ssl_lib and not got_sockets then
            got_sockets = true
            local success, err = pcall(function()
                ws.init(websocket_path)
                security.logger:add({{"initialized sockets"}})
            end)
            os.remove(websocket_path)
            if not success then
                security.logger:add({ { "failed to load sockets", col.red } })
                security.error = true
                print(err)
            end
        end
    end)
end
do
    local connected = false
    security.connect = function()
        if not ws.initialized then return end
        once(function()
            local socket = ws.new(security.socket_url)
            socket:connect()
            security.websocket = socket
            cbs.paint(function()
                local status, err = pcall(function()
                    if not security.websocket then return end
                    for i = 1, #sockets.send_queue do
                        local data = sockets.send_queue[i]
                        if data then
                            security.websocket:send(data)
                        end
                    end
                    sockets.send_queue = {}
                    security.websocket:execute(function(s, code, data, length)
                        if code == 0 then
                            connected = true
                            security.logger:add({ { "connection established" } })
                            security.handshake_start(s)
                        elseif code == 1 then
                            security.handle_data(s, data, length)
                        elseif code == 2 then
                            security.logger:add({ { "connection closed" } })
                            security.error = true
                        elseif code == 3 then
                            security.logger:add({ { "connection failed", col.red } })
                            security.error = true
                        end
                    end)
                end)
                if not status then
                    security.error = err
                    -- error(err, 0)
                end
            end)
        end, "connect")
        return connected
    end
end
security.wait_for_handshake = function()
    if security.handshake_success then
        security.logger:add({{"handshake succeeded"}})
        return true
    end
end
security.wait_for_auth = function()
    if security.authorized then
        if security.debug then
            once(function ()
                gui.init()
                gui.can_be_visible = true
            end, "debug_init")
        end
        security.logger:add({ { "authorized" } })
        return true
    end
end
do
    local downloaded_count = 0
    local downloaded = false
    local download = function(list)
        for _, resource in pairs(list) do
            local path, to = resource[1], resource[2]
            http.download(security.url .. "resources/" .. path, to, function (result)
                if result then
                    downloaded_count = downloaded_count + 1
                    if downloaded_count == #list then
                        downloaded = true
                        security.logger:add({ { "downloaded resources" } })
                    end
                else
                    security.logger:add({ { "failed to get resources", col.red } })
                    security.error = true
                end
            end)
        end
    end
    local csgo = iengine.get_csgo_folder()
    security.download_resources = function ()
        if not security.authorized then return false end
        once(function()
            download({
                {"level2244.png", csgo .. "/csgo/materials/panorama/images/icons/xp/level2244.png"}
            })
        end, "download_resources")
        return downloaded
    end
end
do
    local step = function(name)
        return {
            name = name,
            done = false
        }
    end
    security.steps = {
        step("get_sockets"),
        step("connect"),
        step("wait_for_handshake"),
        step("wait_for_auth"),
        step("download_resources"),
    }
end
local is_fn_hooked = function(f)
    return pcall(string.dump, f)
end
local is_str_dmp_hooked = function()
    return tostring(string.dump):find("builtin") == nil
end
local are_objs_changed = function(obj)
    for _, o in pairs(obj) do
        for _, f in pairs(o) do
            if type(f) == "function" and is_fn_hooked(f) then
                return true
            end
        end
    end
end
local get_script_name = function()
    local info = debug.getinfo(1, "S")
    return info.source:match("([^\\]*)$"):sub(1, -5)
end
local is_script_required = function()
    local info = debug.getinfo(1, "S")
    local name = get_script_name()
    local is_in_lua_folder = info.source:find("\\lua\\") ~= nil
    local is_in_packages = package.loaded[name] ~= nil
    if name == "security" then
        is_in_lua_folder = false
    end
    return is_in_lua_folder or is_in_packages
end
security.ban = function()
    if security.banned then return end
    gui = nil
    security.banned = true
    if not security.logger then
        iengine.log("nice try :)")
    end
    security.logger:add({ { "nice try :)", col.red } })
    error("")
end
security.check_functions = function()
    -- if is_script_required() then return false end
    if is_str_dmp_hooked() then return false end
    if are_objs_changed({
        client, globalvars, debug, engine, io, offi, os, string,
        {
            tostring,
            pcall, --require
            loadstring
        }
    }) then return false end
    return true
end
security.init = function(logger)
    if not security.check_functions() then
        security.ban()
        return
    end
    if security.error then return end
    security.logger = logger
    local count = #security.steps
    local undone_index = 0
    for i, func in pairs(security.steps) do
        if undone_index == 0 and not func.done then
            undone_index = i
        end
    end
    if undone_index == 0 then
        security.progress = 100
        return
    end
    local func = security.steps[undone_index]
    local status, result = pcall(security[func.name])
    if not status then
        errors.report(result, "security." .. func.name)
        error("")
        security.error = true
    end
    security.steps[undone_index].done = result
    security.progress = math.ceil(((undone_index - 1) / count) * 100)
end
return security

end)
__bundle_register("libs.set", function(require, _LOADED, __bundle_register, __bundle_modules)
return function(...)
    local elems = select(1, ...)
    local t = {}
    if type(elems) == "table" then
        for _, v in pairs(elems) do
            t[v] = true end
        return t
    end
    for i = 1, select("#", ...) do
        t[select(i, ...)] = true
    end
    return t
end
end)
__bundle_register("libs.win32", function(require, _LOADED, __bundle_register, __bundle_modules)
local ffi = require("libs.protected_ffi")
local shell = ffi.load("Shell32")
local kernel32 = ffi.load("Kernel32")
local ucrtbase = ffi.load("ucrtbase")
local errors = require("libs.error_handler")
local interface = require("libs.interfaces")()
require("libs.types")
ffi.cdef[[
    void* __stdcall ShellExecuteA(void*, PCSTR, PCSTR, PCSTR, PCSTR, int);
    int MultiByteToWideChar(UINT, DWORD, PCSTR, int, wchar_t*, int);
    int WideCharToMultiByte(UINT, DWORD, const wchar_t*, int, char*, int, PCSTR, BOOL*);
    wchar_t* _wgetenv(const wchar_t*);
    int VirtualProtect(void*, DWORD, DWORD, DWORD*);
    void* VirtualAlloc(void*, DWORD, DWORD, DWORD);
    typedef struct {
        DWORD dwLowDateTime;
        DWORD dwHighDateTime;
    } FILETIME;
    typedef struct {
        DWORD    dwFileAttributes;
        FILETIME ftCreationTime;
        FILETIME ftLastAccessTime;
        FILETIME ftLastWriteTime;
        DWORD    nFileSizeHigh;
        DWORD    nFileSizeLow;
        DWORD    dwReserved0;
        DWORD    dwReserved1;
        wchar_t  cFileName[260];
        wchar_t  cAlternateFileName[14];
        DWORD    dwFileType;
        DWORD    dwCreatorType;
        WORD     wFinderFlags;
    } WIN32_FIND_DATA;
    void* FindFirstFileA(const char*, WIN32_FIND_DATA*);
    bool FindNextFileA(void* hFindFile, WIN32_FIND_DATA*);
    bool FindClose(void* hFindFile);
]]
local win32 = {}
win32.open_url = function(url)
    shell.ShellExecuteA(nil, "open", url, nil, nil, 1)
end
win32.to_wide = function(str)
    local len = ffi.C.MultiByteToWideChar(65001, 0, str, -1, nil, 0)
    local buf = ffi.new("wchar_t[?]", len)
    ffi.C.MultiByteToWideChar(65001, 0, str, -1, buf, len)
    return buf
end
win32.to_utf8 = function(wstr)
    local len = ffi.C.WideCharToMultiByte(65001, 0, wstr, -1, nil, 0, nil, nil)
    local str = ffi.new("char[?]", len)
    ffi.C.WideCharToMultiByte(65001, 0, wstr, -1, str, len, nil, nil)
    return ffi.string(str)
end
win32.get_env = function(name)
    local wname = win32.to_wide(name)
    local wvalue = ucrtbase._wgetenv(wname)
    return win32.to_utf8(wvalue)
end
win32.copy = function(dst, src, len)
    ffi.copy(ffi.cast('void*', dst), ffi.cast('const void*', src), len)
end
win32.VirtualProtect = function(addr, size, new_protect, old_protect)
    return ffi.C.VirtualProtect(ffi.cast('void*', addr), size, new_protect, old_protect)
end
win32.VirtualAlloc = function(addr, size, alloctype, protect, free)
    local alloc = ffi.C.VirtualAlloc(addr, size, alloctype, protect)
    return ffi.cast('intptr_t', alloc)
end
local save_name = function (file_data, extension, only_dirs)
    local name = ffi.string(ffi.cast("char*", file_data[0].cFileName))
    if name == "." or name == ".." then return end
    local is_folder = bit.band(file_data[0].dwFileAttributes, 0x10) ~= 0
    if not is_folder and extension then
        local ext = name:sub(-#extension, -1)
        if ext ~= extension then return end
    end
    if only_dirs and is_folder then
        return
    end
    return name, is_folder
end
win32.dir = function(path, only_dirs, extension, recursive)
    local files = {}
    local function add(name, is_folder)
        if not name then return end
        if recursive and is_folder then
            local list = win32.dir(path..name.."\\", false, extension, true)
            if list then
                for i = 1, #list do
                    files[#files+1] = name.."\\"..list[i]
                end
            end
        else
            files[#files+1] = name
        end
    end
    local file_data = ffi.new("WIN32_FIND_DATA[1]")
    local handle = ffi.C.FindFirstFileA(path.."*", file_data)
    if handle == -1 then return end

    local name, is_folder = save_name(file_data, extension, only_dirs)
    add(name, is_folder)
    while kernel32.FindNextFileA(handle, file_data) do
        name, is_folder = save_name(file_data, extension, only_dirs)
        add(name, is_folder)
    end
    kernel32.FindClose(handle)
    return files
end

local vgui2 = interface.new("vgui2", "VGUI_System010", {
    SetClipboardText = {9, "void(__thiscall*)(void*, const char*, int)"},
})
win32.copy_to_clipboard = errors.handler(function(text)
    text = tostring(text)
    vgui2:SetClipboardText(text, #text)
end)
return win32
end)
__bundle_register("libs.sockets", function(require, _LOADED, __bundle_register, __bundle_modules)
local json = require("libs.json")

---@class __sockets_t
---@field websocket __websocket_t
---@field encrypt fun(data: string): string
local sockets = {}
sockets.callbacks = {}
sockets.send_queue = {}
---@param type_name string
---@param callback fun(data: table<string, any>)
sockets.add = function(type_name, callback)
    if type_name == "on_socket_init" then
        sockets.callbacks[type_name] = sockets.callbacks[type_name] or {}
        return table.insert(sockets.callbacks[type_name], callback)
    end
    sockets.callbacks[type_name] = callback
end
sockets.init = function(websocket)
    sockets.websocket = websocket
    if sockets.callbacks.on_socket_init then
        for i = 1, #sockets.callbacks.on_socket_init do
            sockets.callbacks.on_socket_init[i]()
        end
    end
end
---@param data table
---@param direct? boolean
sockets.send = function(data, direct)
    if not sockets.websocket then return false end
    local encoded = json.encode(data)
    if not encoded then
        error("failed to encode data")
    end
    local encrypted = sockets.encrypt(encoded)
    if not encrypted or encrypted == "" then
        error("failed to encrypt data")
    end
    if direct then
        sockets.websocket:send(encrypted)
    else
        table.insert(sockets.send_queue, encrypted)
    end
end

return sockets
end)
__bundle_register("libs.json", function(require, _LOADED, __bundle_register, __bundle_modules)
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
    ["\\"] = "\\",
    ["\""] = "\"",
    ["\b"] = "b",
    ["\f"] = "f",
    ["\n"] = "n",
    ["\r"] = "r",
    ["\t"] = "t",
}

local escape_char_map_inv = { ["/"] = "/" }
for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
end


local function escape_char(c)
    return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end

local function encode_nil()
    return "null"
end

local function encode_table(val, stack)
    local res = {}
    stack = stack or {}

    -- Circular reference?
    if stack[val] then error("circular reference") end

    stack[val] = true

    if rawget(val, 1) ~= nil or next(val) == nil then
        -- Treat as array -- check keys are valid and it is not sparse
        local n = 0
        for k in pairs(val) do
            if type(k) ~= "number" then
                error("invalid table: mixed or invalid key types")
            end
            n = n + 1
        end
        if n ~= #val then
            error("invalid table: sparse array")
        end
        -- Encode
        for _, v in ipairs(val) do
            table.insert(res, encode(v, stack))
        end
        stack[val] = nil
        return "[" .. table.concat(res, ",") .. "]"

    else
        -- Treat as an object
        for k, v in pairs(val) do
            if type(k) ~= "string" then
                error("invalid table: mixed or invalid key types")
            end
            table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
        end
        stack[val] = nil
        return "{" .. table.concat(res, ",") .. "}"
    end
end

local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
    -- Check for NaN, -inf and inf
    if val ~= val or val <= -math.huge or val >= math.huge then
        error("unexpected number value '" .. tostring(val) .. "'")
    end
    return string.format("%.14g", val)
end

local type_func_map = {
    ["nil"] = encode_nil,
    ["table"] = encode_table,
    ["string"] = encode_string,
    ["number"] = encode_number,
    ["boolean"] = tostring,
}


encode = function(val, stack)
    local t = type(val)
    local f = type_func_map[t]
    if f then
        return f(val, stack)
    end
    error("unexpected type '" .. t .. "'")
end


function json.encode(val)
    return (encode(val))
end

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
    local res = {}
    for i = 1, select("#", ...) do
        res[select(i, ...)] = true
    end
    return res
end

local space_chars  = create_set(" ", "\t", "\r", "\n")
local delim_chars  = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals     = create_set("true", "false", "null")

local literal_map = {
    ["true"] = true,
    ["false"] = false,
    ["null"] = nil,
}


local function next_char(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
            return i
        end
    end
    return #str + 1
end

local function decode_error(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
        col_count = col_count + 1
        if str:sub(i, i) == "\n" then
            line_count = line_count + 1
            col_count = 1
        end
    end
    error(string.format("%s at line %d col %d", msg, line_count, col_count))
end

local function codepoint_to_utf8(n)
    -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
    local f = math.floor
    if n <= 0x7f then
        return string.char(n)
    elseif n <= 0x7ff then
        return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
        return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
        return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
            f(n % 4096 / 64) + 128, n % 64 + 128)
    end
    error(string.format("invalid unicode codepoint '%x'", n))
end

local function parse_unicode_escape(s)
    local n1 = tonumber(s:sub(1, 4), 16)
    local n2 = tonumber(s:sub(7, 10), 16)
    -- Surrogate pair?
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
        return codepoint_to_utf8(n1)
    end
end

local function parse_string(str, i)
    local res = ""
    local j = i + 1
    local k = j

    while j <= #str do
        local x = str:byte(j)

        if x < 32 then
            decode_error(str, j, "control character in string")

        elseif x == 92 then -- `\`: Escape
            res = res .. str:sub(k, j - 1)
            j = j + 1
            local c = str:sub(j, j)
            if c == "u" then
                local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                    or str:match("^%x%x%x%x", j + 1)
                    or decode_error(str, j - 1, "invalid unicode escape in string")
                res = res .. parse_unicode_escape(hex)
                j = j + #hex
            else
                if not escape_chars[c] then
                    decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
                end
                res = res .. escape_char_map_inv[c]
            end
            k = j + 1

        elseif x == 34 then -- `"`: End of string
            res = res .. str:sub(k, j - 1)
            return res, j + 1
        end

        j = j + 1
    end

    decode_error(str, i, "expected closing quote for string")
end

local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    if not n then
        decode_error(str, i, "invalid number '" .. s .. "'")
    end
    return n, x
end

local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then
        decode_error(str, i, "invalid literal '" .. word .. "'")
    end
    return literal_map[word], x
end

local function parse_array(str, i)
    local res = {}
    local n = 1
    i = i + 1
    while 1 do
        local x
        i = next_char(str, i, space_chars, true)
        -- Empty / end of array?
        if str:sub(i, i) == "]" then
            i = i + 1
            break
        end
        -- Read token
        x, i = parse(str, i)
        res[n] = x
        n = n + 1
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "]" then break end
        if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
    end
    return res, i
end

local function parse_object(str, i)
    local res = {}
    i = i + 1
    while 1 do
        local key, val
        i = next_char(str, i, space_chars, true)
        -- Empty / end of object?
        if str:sub(i, i) == "}" then
            i = i + 1
            break
        end
        -- Read key
        if str:sub(i, i) ~= '"' then
            decode_error(str, i, "expected string for key")
        end
        key, i = parse(str, i)
        -- Read ':' delimiter
        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) ~= ":" then
            decode_error(str, i, "expected ':' after key")
        end
        i = next_char(str, i + 1, space_chars, true)
        -- Read value
        val, i = parse(str, i)
        -- Set
        res[key] = val
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "}" then break end
        if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
    end
    return res, i
end

local char_func_map = {
    ['"'] = parse_string,
    ["0"] = parse_number,
    ["1"] = parse_number,
    ["2"] = parse_number,
    ["3"] = parse_number,
    ["4"] = parse_number,
    ["5"] = parse_number,
    ["6"] = parse_number,
    ["7"] = parse_number,
    ["8"] = parse_number,
    ["9"] = parse_number,
    ["-"] = parse_number,
    ["t"] = parse_literal,
    ["f"] = parse_literal,
    ["n"] = parse_literal,
    ["["] = parse_array,
    ["{"] = parse_object,
}


parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then
        return f(str, idx)
    end
    decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
    if type(str) ~= "string" then
        error("expected argument of type string, got " .. type(str))
    end
    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then
        decode_error(str, idx, "trailing garbage")
    end
    return res
end

return json

end)
__bundle_register("libs.websocket", function(require, _LOADED, __bundle_register, __bundle_modules)
local cbs = require("libs.callbacks")
local _, class = require("libs.interfaces")()
local ffi = require("libs.protected_ffi")
local websocket_library
require("libs.types")
ffi.cdef[[
    typedef struct {
        char code;
        char data[1024];
        int length;
    } DataStruct;
    __cdecl void* Create(PCSTR);
    __cdecl void Unload();
]]
local websocket_class = class.new({
    connect = { 0, "bool(__thiscall*)(void*)" },
    is_data_available = { 1, "bool(__thiscall*)(void*)" },
    get_data = { 2, "bool(__thiscall*)(void*, DataStruct*)" },
    send = { 3, "void(__thiscall*)(void*, PCSTR)" },
})
local websocket = {
    CONNECTED = 0,
    DATA = 1,
    DISCONNECTED = 2,
    ERROR = 3,
    initialized = false
}
---@class __websocket_t
---@field valid boolean
---@field connected boolean
local websocket_t = {
    --*dirty hack to make autocomplete work
    ws = websocket_class.__functions
}
---@param data string
---@return boolean
websocket_t.send = function(self, data)
    if not self.valid or not self.connected then return false end
    return self.ws:send(data)
end
websocket_t.connect = function(self)
    if not self.valid then return false end
    return self.ws:connect()
end
---@param callback fun(self: __websocket_t, code: number, data: string, length: number)
websocket_t.execute = function(self, callback)
    if not self.valid then return end
    if not self.ws:is_data_available() then return end
    local struct = ffi.new("DataStruct")
    local result = self.ws:get_data(struct)
    if not result then return end
    local code, length = struct.code, struct.length
    local data = ""
    if code == websocket.DATA and length > 0 then
        data = ffi.string(struct.data, math.min(length, 1024))
    elseif code == websocket.CONNECTED and not self.connected then
        self.connected = true
    elseif code == websocket.DISCONNECTED or code == websocket.ERROR then
        self.connected = false
    end
    callback(self, code, data, length)
end

websocket.new = function(url)
    if not websocket_library then
        error("websocket library not initialized")
    end
    local raw_socket = websocket_library.Create(url)
    local socket = setmetatable({
        ws = websocket_class(raw_socket),
        valid = true,
        connected = false,
    }, { __index = websocket_t })
    cbs.add("unload", function()
        socket.connected = false
        socket.valid = false
    end)
    return socket
end
websocket.init = function(lib)
    websocket_library = ffi.load(lib)
    websocket.initialized = true
end
cbs.critical("unload", function ()
    if not websocket_library then return end
    websocket_library.Unload()
end)
return websocket

end)
__bundle_register("libs.callbacks", function(require, _LOADED, __bundle_register, __bundle_modules)
local errors = require("libs.error_handler")
local v2, v3 = require("libs.vectors")()
local cbs = {
    list = {
        unload = {},
        paint = {},
        create_move = {},
        frame_stage_notify = {},
        shot_fired = {},
        override_view = {}
    },
    critical_list = {
        unload = {},
    }
}
---@param fn fun()
---@param name? string
cbs.paint = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.paint, t)
end
---@param fn fun(cmd: usercmd_t)
---@param name? string
cbs.create_move = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.create_move, t)
end
---@param fn fun(stage: number)
---@param name? string
cbs.frame_stage = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.frame_stage_notify, t)
end
---@param fn fun()
---@param name? string
cbs.unload = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.unload, t)
end
---@param fn fun(shot_info: shot_info_t)
---@param name? string
cbs.shot_fired = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.shot_fired, t)
end
---@param fn fun(view_setup: view_setup_t)
---@param name? string
cbs.override_view = function(fn, name)
    local t = { fn = fn }
    if name then t.name = name end
    table.insert(cbs.list.override_view, t)
end

cbs.add = function(name, fn)
    if not cbs.list[name] then
        cbs.list[name] = {}
    end
    local t = { fn = fn }
    table.insert(cbs.list[name], t)
end

cbs.critical = function(name, fn)
    if not cbs.critical_list[name] then
        cbs.critical_list[name] = {}
    end
    table.insert(cbs.critical_list[name], fn)
end

---@param event_name string
---@param fn fun(event: game_event_t)
---@param name? string
cbs.event = function(event_name, fn, name)
    client.register_callback(event_name, errors.handler(fn, name or event_name))
end

local shot_fired_callbacks = {}
---@param fn fun(shot: {from: vec3_t, to: vec3_t})
cbs.on_shot_fired = function(fn)
    table.insert(shot_fired_callbacks, fn)
end

return cbs
end)
__bundle_register("libs.utf8", function(require, _LOADED, __bundle_register, __bundle_modules)
local utf8 = {}
utf8.char = function(val)
    local c = string.char
    local bm = { { 0x7FF, 192 }, { 0xFFFF, 224 }, { 0x1FFFFF, 240 } }
    if val < 128 then return c(val) end
    local cbts = {}
    for bts, vals in ipairs(bm) do
        if val <= vals[1] then
            for b = bts + 1, 2, -1 do
                local mod = val % 64
                val = (val - mod) / 64
                cbts[b] = c(128 + mod)
            end
            cbts[1] = c(vals[2] + val)
            break
        end
    end
    return table.concat(cbts)
end
utf8.byte = function(char)
    local c = 0
    local bytes = { string.byte(char, 1, -1) }
    for _, v in ipairs(bytes) do
        if v > 127 then
            c = (c * 64) + (v % 64)
        else
            c = v
            break
        end
    end
    return c
end
local pattern = loadstring('return "[%z\\1-\\127\\194-\\244][\\128-\\191]*"')() --[%z\1-\127\194-\244][\128-\191]*
utf8.map = function(str, fn)
    return str:gsub(pattern, fn)
end
return utf8
end)
__bundle_register("libs.hwid", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.types")
ffi.cdef[[
    typedef struct {
        union {
            DWORD dwOemId;
            struct {
                WORD wProcessorArchitecture;
                WORD wReserved;
            } DUMMYSTRUCTNAME;
        } DUMMYUNIONNAME;
        DWORD dwPageSize;
        void* lpMinimumApplicationAddress;
        void* lpMaximumApplicationAddress;
        DWORD dwActiveProcessorMask;
        DWORD dwNumberOfProcessors;
        DWORD dwProcessorType;
        DWORD dwAllocationGranularity;
        WORD wProcessorLevel;
        WORD wProcessorRevision;
    } SYSTEM_INFO;
    void GetSystemInfo(SYSTEM_INFO*);
    BOOL GetVolumeInformationA(PCSTR, char*, DWORD, DWORD*, DWORD*, DWORD*, char*, DWORD);
]]
return function()
    local si = ffi.new("SYSTEM_INFO[1]")
    ffi.C.GetSystemInfo(si)
    local info = si[0]
    local hwid = {
        type = info.dwProcessorType,
        cores = info.dwNumberOfProcessors,
        proc_level = info.wProcessorLevel,
        revision = info.wProcessorRevision,
    }
    local hdd_id = ffi.new("DWORD[1]")
    ffi.C.GetVolumeInformationA("C:\\", nil, 0, hdd_id, nil, nil, nil, 0)
    hwid.hdd = hdd_id[0]
    return hwid
end
end)
__bundle_register("libs.http", function(require, _LOADED, __bundle_register, __bundle_modules)
local http_lib = require("libs.http_lib")
require("libs.types")
local http = {}
---@param url string
---@param path? string
---@param callback? fun(path?: string)
http.download = function (url, path, callback)
    if path ~= nil then
        local file = io.open(path, "rb")
        if file then
            file:close()
            if callback then
                return callback(path)
            end
            return
        end
    else
        path = os.tmpname()
    end
    http_lib.request("get", url, {}, function(success, response)
        if not success or not response.body then
            if callback then
                return callback()
            end
            error("couldn't download a file")
        end
        local file = io.open(path, "wb")
        if not file then return end
        file:write(response.body)
        file:close()
        if callback then
            callback(path)
        end
    end)
end
---@param url string
---@param callback fun(body: string)
http.get = function(url, callback)
    http_lib.request("get", url, {}, function(success, response)
        if not success or not response.body then return end
        callback(response.body)
    end)
end
return http
end)
__bundle_register("libs.http_lib", function(require, _LOADED, __bundle_register, __bundle_modules)
---@diagnostic disable
local a = require("libs.protected_ffi")
local function c(...)
    print(tostring(...))
end
local d, e, f
if not pcall(a.sizeof, "SteamAPICall_t") then
    a.cdef(
        [[
        typedef uint64_t SteamAPICall_t;
        struct SteamAPI_callback_base_vtbl {
            void(__thiscall *run1)(struct SteamAPI_callback_base *, void *, bool, uint64_t);
            void(__thiscall *run2)(struct SteamAPI_callback_base *, void *);
            int(__thiscall *get_size)(struct SteamAPI_callback_base *);
        };

        struct SteamAPI_callback_base {
            struct SteamAPI_callback_base_vtbl *vtbl;
            uint8_t flags;
            int id;
            uint64_t api_call_handle;
            struct SteamAPI_callback_base_vtbl vtbl_storage[1];
        };
    ]]
    )
end
local g = {
    [-1] = "No failure",
    [0] = "Steam gone",
    [1] = "Network failure",
    [2] = "Invalid handle",
    [3] = "Mismatched callback"
}
local h = a.typeof("struct SteamAPI_callback_base")
local i = a.sizeof(h)
local j = a.typeof("struct SteamAPI_callback_base[1]")
local k = a.typeof("struct SteamAPI_callback_base*")
local l = a.typeof("uintptr_t")
local m = {}
local n = {}
local o = {}
local function p(q)
    return tostring(tonumber(a.cast(l, q)))
end
local function r(self, s, t)
    if t then
        t = g[GetAPICallFailureReason(self.api_call_handle)] or "Unknown error"
    end
    self.api_call_handle = 0
    xpcall(
        function()
            local u = p(self)
            local v = m[u]
            if v ~= nil then
                xpcall(v, c, s, t)
            end
            if n[u] ~= nil then
                m[u] = nil
                n[u] = nil
            end
        end,
        c
    )
end
local function w(self, s, t, x)
    if x == self.api_call_handle then
        r(self, s, t)
    end
end
local function y(self, s)
    r(self, s, false)
end
local function z(self)
    return i
end
local function A(self)
    if self.api_call_handle ~= 0 then
        SteamAPI_UnregisterCallResult(self, self.api_call_handle)
        self.api_call_handle = 0
        local u = p(self)
        m[u] = nil
        n[u] = nil
    end
end
pcall(a.metatype, h, {__gc = A, __index = {cancel = A}})
local B = a.cast("void(__thiscall *)(struct SteamAPI_callback_base *, void *, bool, uint64_t)", w)
local C = a.cast("void(__thiscall *)(struct SteamAPI_callback_base *, void *)", y)
local D = a.cast("int(__thiscall *)(struct SteamAPI_callback_base *)", z)
function d(x, v, E)
    assert(x ~= 0)
    local F = j()
    local G = a.cast(k, F)
    G.vtbl_storage[0].run1 = B
    G.vtbl_storage[0].run2 = C
    G.vtbl_storage[0].get_size = D
    G.vtbl = G.vtbl_storage
    G.api_call_handle = x
    G.id = E
    local u = p(G)
    m[u] = v
    n[u] = F
    SteamAPI_RegisterCallResult(G, x)
    return G
end
function e(E, v)
    assert(o[E] == nil)
    local F = j()
    local G = a.cast(k, F)
    G.vtbl_storage[0].run1 = B
    G.vtbl_storage[0].run2 = C
    G.vtbl_storage[0].get_size = D
    G.vtbl = G.vtbl_storage
    G.api_call_handle = 0
    G.id = E
    local u = p(G)
    m[u] = v
    o[E] = F
    SteamAPI_RegisterCallback(G, E)
end
local function H(I, J, K, L, M)
    local N = client.find_pattern(I, J) or error("signature not found", 2)
    local O = a.cast("uintptr_t", N)
    if L ~= nil and L ~= 0 then
        O = O + L
    end
    if M ~= nil then
        for P = 1, M do
            O = a.cast("uintptr_t*", O)[0]
            if O == nil then
                return error("signature not found")
            end
        end
    end
    return a.cast(K, O)
end
local function Q(G, R, type)
    return a.cast(type, a.cast("void***", G)[0][R])
end
SteamAPI_RegisterCallResult =
    H(
    "steam_api.dll",
    "55 8B EC 83 3D ? ? ? ? ? 7E 0D 68 ? ? ? ? FF 15 ? ? ? ? 5D C3 FF 75 10",
    "void(__cdecl*)(struct SteamAPI_callback_base *, uint64_t)"
)
SteamAPI_UnregisterCallResult =
    H("steam_api.dll", " 55 8B EC FF 75 10 FF 75 0C", "void(__cdecl*)(struct SteamAPI_callback_base *, uint64_t)")
SteamAPI_RegisterCallback =
    H(
    "steam_api.dll",
    " 55 8B EC 83 3D ? ? ? ? ? 7E 0D 68 ? ? ? ? FF 15 ? ? ? ? 5D C3 C7 05",
    "void(__cdecl*)(struct SteamAPI_callback_base *, int)"
)
SteamAPI_UnregisterCallback =
    H("steam_api.dll", " 55 8B EC 83 EC 08 80 3D", "void(__cdecl*)(struct SteamAPI_callback_base *)")
f = H("client.dll", " B9 ? ? ? ? E8 ? ? ? ? 83 3D ? ? ? ? ? 0F 84", "uintptr_t", 1, 1)
local S = a.cast("uintptr_t*", f)[3]
local T = Q(S, 12, "int(__thiscall*)(void*, SteamAPICall_t)")
function GetAPICallFailureReason(U)
    return T(S, U)
end
client.register_callback(
    "unload",
    function()
        for u, V in pairs(n) do
            local G = a.cast(k, V)
            A(G)
        end
        for u, V in pairs(o) do
            local G = a.cast(k, V)
            SteamAPI_UnregisterCallback(G)
        end
    end
)
if not pcall(a.sizeof, "http_HTTPRequestHandle") then
    a.cdef(
        [[
        typedef uint32_t http_HTTPRequestHandle;
        typedef uint32_t http_HTTPCookieContainerHandle;

        enum http_EHTTPMethod {
            k_EHTTPMethodInvalid,
            k_EHTTPMethodGET,
            k_EHTTPMethodHEAD,
            k_EHTTPMethodPOST,
            k_EHTTPMethodPUT,
            k_EHTTPMethodDELETE,
            k_EHTTPMethodOPTIONS,
            k_EHTTPMethodPATCH,
        };

        struct http_ISteamHTTPVtbl {
            http_HTTPRequestHandle(__thiscall *CreateHTTPRequest)(uintptr_t, enum http_EHTTPMethod, const char *);
            bool(__thiscall *SetHTTPRequestContextValue)(uintptr_t, http_HTTPRequestHandle, uint64_t);
            bool(__thiscall *SetHTTPRequestNetworkActivityTimeout)(uintptr_t, http_HTTPRequestHandle, uint32_t);
            bool(__thiscall *SetHTTPRequestHeaderValue)(uintptr_t, http_HTTPRequestHandle, const char *, const char *);
            bool(__thiscall *SetHTTPRequestGetOrPostParameter)(uintptr_t, http_HTTPRequestHandle, const char *, const char *);
            bool(__thiscall *SendHTTPRequest)(uintptr_t, http_HTTPRequestHandle, SteamAPICall_t *);
            bool(__thiscall *SendHTTPRequestAndStreamResponse)(uintptr_t, http_HTTPRequestHandle, SteamAPICall_t *);
            bool(__thiscall *DeferHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
            bool(__thiscall *PrioritizeHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
            bool(__thiscall *GetHTTPResponseHeaderSize)(uintptr_t, http_HTTPRequestHandle, const char *, uint32_t *);
            bool(__thiscall *GetHTTPResponseHeaderValue)(uintptr_t, http_HTTPRequestHandle, const char *, uint8_t *, uint32_t);
            bool(__thiscall *GetHTTPResponseBodySize)(uintptr_t, http_HTTPRequestHandle, uint32_t *);
            bool(__thiscall *GetHTTPResponseBodyData)(uintptr_t, http_HTTPRequestHandle, uint8_t *, uint32_t);
            bool(__thiscall *GetHTTPStreamingResponseBodyData)(uintptr_t, http_HTTPRequestHandle, uint32_t, uint8_t *, uint32_t);
            bool(__thiscall *ReleaseHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
            bool(__thiscall *GetHTTPDownloadProgressPct)(uintptr_t, http_HTTPRequestHandle, float *);
            bool(__thiscall *SetHTTPRequestRawPostBody)(uintptr_t, http_HTTPRequestHandle, const char *, uint8_t *, uint32_t);
            http_HTTPCookieContainerHandle(__thiscall *CreateCookieContainer)(uintptr_t, bool);
            bool(__thiscall *ReleaseCookieContainer)(uintptr_t, http_HTTPCookieContainerHandle);
            bool(__thiscall *SetCookie)(uintptr_t, http_HTTPCookieContainerHandle, const char *, const char *, const char *);
            bool(__thiscall *SetHTTPRequestCookieContainer)(uintptr_t, http_HTTPRequestHandle, http_HTTPCookieContainerHandle);
            bool(__thiscall *SetHTTPRequestUserAgentInfo)(uintptr_t, http_HTTPRequestHandle, const char *);
            bool(__thiscall *SetHTTPRequestRequiresVerifiedCertificate)(uintptr_t, http_HTTPRequestHandle, bool);
            bool(__thiscall *SetHTTPRequestAbsoluteTimeoutMS)(uintptr_t, http_HTTPRequestHandle, uint32_t);
            bool(__thiscall *GetHTTPRequestWasTimedOut)(uintptr_t, http_HTTPRequestHandle, bool *pbWasTimedOut);
        };
    ]]
    )
end
local W = {
    get = a.C.k_EHTTPMethodGET,
    head = a.C.k_EHTTPMethodHEAD,
    post = a.C.k_EHTTPMethodPOST,
    put = a.C.k_EHTTPMethodPUT,
    delete = a.C.k_EHTTPMethodDELETE,
    options = a.C.k_EHTTPMethodOPTIONS,
    patch = a.C.k_EHTTPMethodPATCH
}
local X = {
    [100] = "Continue",
    [101] = "Switching Protocols",
    [102] = "Processing",
    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [203] = "Non-Authoritative Information",
    [204] = "No Content",
    [205] = "Reset Content",
    [206] = "Partial Content",
    [207] = "Multi-Status",
    [208] = "Already Reported",
    [250] = "Low on Storage Space",
    [226] = "IM Used",
    [300] = "Multiple Choices",
    [301] = "Moved Permanently",
    [302] = "Found",
    [303] = "See Other",
    [304] = "Not Modified",
    [305] = "Use Proxy",
    [306] = "Switch Proxy",
    [307] = "Temporary Redirect",
    [308] = "Permanent Redirect",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [402] = "Payment Required",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [406] = "Not Acceptable",
    [407] = "Proxy Authentication Required",
    [408] = "Request Timeout",
    [409] = "Conflict",
    [410] = "Gone",
    [411] = "Length Required",
    [412] = "Precondition Failed",
    [413] = "Request Entity Too Large",
    [414] = "Request-URI Too Long",
    [415] = "Unsupported Media Type",
    [416] = "Requested Range Not Satisfiable",
    [417] = "Expectation Failed",
    [418] = "I'm a teapot",
    [420] = "Enhance Your Calm",
    [422] = "Unprocessable Entity",
    [423] = "Locked",
    [424] = "Failed Dependency",
    [424] = "Method Failure",
    [425] = "Unordered Collection",
    [426] = "Upgrade Required",
    [428] = "Precondition Required",
    [429] = "Too Many Requests",
    [431] = "Request Header Fields Too Large",
    [444] = "No Response",
    [449] = "Retry With",
    [450] = "Blocked by Windows Parental Controls",
    [451] = "Parameter Not Understood",
    [451] = "Unavailable For Legal Reasons",
    [451] = "Redirect",
    [452] = "Conference Not Found",
    [453] = "Not Enough Bandwidth",
    [454] = "Session Not Found",
    [455] = "Method Not Valid in This State",
    [456] = "Header Field Not Valid for Resource",
    [457] = "Invalid Range",
    [458] = "Parameter Is Read-Only",
    [459] = "Aggregate Operation Not Allowed",
    [460] = "Only Aggregate Operation Allowed",
    [461] = "Unsupported Transport",
    [462] = "Destination Unreachable",
    [494] = "Request Header Too Large",
    [495] = "Cert Error",
    [496] = "No Cert",
    [497] = "HTTP to HTTPS",
    [499] = "Client Closed Request",
    [500] = "Internal Server Error",
    [501] = "Not Implemented",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
    [504] = "Gateway Timeout",
    [505] = "HTTP Version Not Supported",
    [506] = "Variant Also Negotiates",
    [507] = "Insufficient Storage",
    [508] = "Loop Detected",
    [509] = "Bandwidth Limit Exceeded",
    [510] = "Not Extended",
    [511] = "Network Authentication Required",
    [551] = "Option not supported",
    [598] = "Network read timeout error",
    [599] = "Network connect timeout error"
}
local Y = {"params", "body", "json"}
local Z = 2101
local _ = 2102
local a0 = 2103
local function a1()
    local a2 = a.cast("uintptr_t*", f)[12]
    if a2 == 0 or a2 == nil then
        return error("find_isteamhttp failed")
    end
    local a3 = a.cast("struct http_ISteamHTTPVtbl**", a2)[0]
    if a3 == 0 or a3 == nil then
        return error("find_isteamhttp failed")
    end
    return a2, a3
end
local function a4(a5, a6)
    return function(...)
        return a5(a6, ...)
    end
end
local a7 =
    a.typeof(
    [[
    struct {
        http_HTTPRequestHandle m_hRequest;
        uint64_t m_ulContextValue;
        bool m_bRequestSuccessful;
        int m_eStatusCode;
        uint32_t m_unBodySize;
    } *
    ]]
)
local a8 =
    a.typeof(
    [[
    struct {
        http_HTTPRequestHandle m_hRequest;
        uint64_t m_ulContextValue;
    } *
    ]]
)
local a9 =
    a.typeof(
    [[
    struct {
        http_HTTPRequestHandle m_hRequest;
        uint64_t m_ulContextValue;
        uint32_t m_cOffset;
        uint32_t m_cBytesReceived;
    } *
    ]]
)
local aa = a.typeof([[
    struct {
        http_HTTPCookieContainerHandle m_hCookieContainer;
    }
    ]])
local ab = a.typeof("SteamAPICall_t[1]")
local ac = a.typeof("const char[?]")
local ad = a.typeof("uint8_t[?]")
local ae = a.typeof("unsigned int[?]")
local af = a.typeof("bool[1]")
local ag = a.typeof("float[1]")
local ah, ai = a1()
local aj = a4(ai.CreateHTTPRequest, ah)
local ak = a4(ai.SetHTTPRequestContextValue, ah)
local al = a4(ai.SetHTTPRequestNetworkActivityTimeout, ah)
local am = a4(ai.SetHTTPRequestHeaderValue, ah)
local an = a4(ai.SetHTTPRequestGetOrPostParameter, ah)
local ao = a4(ai.SendHTTPRequest, ah)
local ap = a4(ai.SendHTTPRequestAndStreamResponse, ah)
local aq = a4(ai.DeferHTTPRequest, ah)
local ar = a4(ai.PrioritizeHTTPRequest, ah)
local as = a4(ai.GetHTTPResponseHeaderSize, ah)
local at = a4(ai.GetHTTPResponseHeaderValue, ah)
local au = a4(ai.GetHTTPResponseBodySize, ah)
local av = a4(ai.GetHTTPResponseBodyData, ah)
local aw = a4(ai.GetHTTPStreamingResponseBodyData, ah)
local ax = a4(ai.ReleaseHTTPRequest, ah)
local ay = a4(ai.GetHTTPDownloadProgressPct, ah)
local az = a4(ai.SetHTTPRequestRawPostBody, ah)
local aA = a4(ai.CreateCookieContainer, ah)
local aB = a4(ai.ReleaseCookieContainer, ah)
local aC = a4(ai.SetCookie, ah)
local aD = a4(ai.SetHTTPRequestCookieContainer, ah)
local aE = a4(ai.SetHTTPRequestUserAgentInfo, ah)
local aF = a4(ai.SetHTTPRequestRequiresVerifiedCertificate, ah)
local aG = a4(ai.SetHTTPRequestAbsoluteTimeoutMS, ah)
local aH = a4(ai.GetHTTPRequestWasTimedOut, ah)
local aI, aJ = {}, false
local aK, aL = false, {}
local aM, aN = false, {}
local aI, aJ = {}, false
local aK, aL = false, {}
local aM, aN = false, {}
local aO = setmetatable({}, {__mode = "k"})
local aP, aQ = setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "v"})
local aR = {}
local aS = {__index = function(aT, aU)
        local aV = aP[aT]
        if aV == nil then
            return
        end
        aU = tostring(aU)
        if aV.m_hRequest ~= 0 then
            local aW = ae(1)
            if as(aV.m_hRequest, aU, aW) then
                if aW ~= nil then
                    aW = aW[0]
                    if aW < 0 then
                        return
                    end
                    local aX = ad(aW)
                    if at(aV.m_hRequest, aU, aX, aW) then
                        aT[aU] = a.string(aX, aW - 1)
                        return aT[aU]
                    end
                end
            end
        end
    end, __metatable = false}
local aY = {__index = {set_cookie = function(aZ, a_, b0, aU, V)
            local U = aO[aZ]
            if U == nil or U.m_hCookieContainer == 0 then
                return
            end
            aC(U.m_hCookieContainer, a_, b0, tostring(aU) .. "=" .. tostring(V))
        end}, __metatable = false}
local function b1(U)
    if U.m_hCookieContainer ~= 0 then
        aB(U.m_hCookieContainer)
        U.m_hCookieContainer = 0
    end
end
local function b2(aV)
    if aV.m_hRequest ~= 0 then
        ax(aV.m_hRequest)
        aV.m_hRequest = 0
    end
end
local function b3(b4, ...)
    ax(b4)
    return error(...)
end
local function b5(aV, b6, b7, b8, ...)
    local b9 = aQ[aV.m_hRequest]
    if b9 == nil then
        b9 = setmetatable({}, aS)
        aQ[aV.m_hRequest] = b9
    end
    aP[b9] = aV
    b8.headers = b9
    aJ = true
    xpcall(b6, c, b7, b8, ...)
    aJ = false
end
local function ba(s, t)
    if s == nil then
        return
    end
    local aV = a.cast(a7, s)
    if aV.m_hRequest ~= 0 then
        local b6 = aI[aV.m_hRequest]
        if b6 ~= nil then
            aI[aV.m_hRequest] = nil
            aN[aV.m_hRequest] = nil
            aL[aV.m_hRequest] = nil
            if b6 then
                local b7 = t == false and aV.m_bRequestSuccessful
                local bb = aV.m_eStatusCode
                local bc = {status = bb}
                local bd = aV.m_unBodySize
                if b7 and bd > 0 then
                    local aX = ad(bd)
                    if av(aV.m_hRequest, aX, bd) then
                        bc.body = a.string(aX, bd)
                    end
                elseif not aV.m_bRequestSuccessful then
                    local be = af()
                    aH(aV.m_hRequest, be)
                    bc.timed_out = be ~= nil and be[0] == true
                end
                if bb > 0 then
                    bc.status_message = X[bb] or "Unknown status"
                elseif t then
                    bc.status_message = string.format("IO Failure: %s", t)
                else
                    bc.status_message = bc.timed_out and "Timed out" or "Unknown error"
                end
                b5(aV, b6, b7, bc)
            end
            b2(aV)
        end
    end
end
local function bf(s, t)
    if s == nil then
        return
    end
    local aV = a.cast(a8, s)
    if aV.m_hRequest ~= 0 then
        local b6 = aL[aV.m_hRequest]
        if b6 then
            b5(aV, b6, t == false, {})
        end
    end
end
local function bg(s, t)
    if s == nil then
        return
    end
    local aV = a.cast(a9, s)
    if aV.m_hRequest ~= 0 then
        local b6 = aN[aV.m_hRequest]
        if aN[aV.m_hRequest] then
            local b8 = {}
            local bh = ag()
            if ay(aV.m_hRequest, bh) then
                b8.download_progress = tonumber(bh[0])
            end
            local aX = ad(aV.m_cBytesReceived)
            if aw(aV.m_hRequest, aV.m_cOffset, aX, aV.m_cBytesReceived) then
                b8.body = a.string(aX, aV.m_cBytesReceived)
            end
            b5(aV, b6, t == false, b8)
        end
    end
end
---@alias callback_function fun(success: boolean, result: { status?: number, body?: string, timed_out?: boolean })
---@param method "get"|"head"|"post"|"put"|"delete"|"options"|"patch"
---@param url string
---@param options? { absolute_timeout?: number, body?: string, cookie_container?: table, headers?: table<string, string>, json?: table, network_timeout?: number, params?: table, priority?: "defer"|"prioritize", require_ssl?: boolean, stream_response?: boolean, user_agent_info?: string }
---@param callbacks { completed?: callback_function, headers_received?: callback_function, data_received?: callback_function }|callback_function
local function bi(method, url, options, callbacks)
    if type(options) == "function" and callbacks == nil then
        callbacks = options
        options = {}
    end
    options = options or {}
    local bj = W[string.lower(tostring(method))]
    if bj == nil then
        return error("invalid HTTP method")
    end
    if type(url) ~= "string" then
        return error("URL has to be a string")
    end
    local bm, bn, bo
    if type(callbacks) == "function" then
        bm = callbacks
    elseif type(callbacks) == "table" then
        bm = callbacks.completed or callbacks.complete
        bn = callbacks.headers_received or callbacks.headers
        bo = callbacks.data_received or callbacks.data
        if bm ~= nil and type(bm) ~= "function" then
            return error("callbacks.completed callback has to be a function")
        elseif bn ~= nil and type(bn) ~= "function" then
            return error("callbacks.headers_received callback has to be a function")
        elseif bo ~= nil and type(bo) ~= "function" then
            return error("callbacks.data_received callback has to be a function")
        end
    else
        return error("callbacks has to be a function or table")
    end
    local b4 = aj(bj, url)
    if b4 == 0 then
        return error("Failed to create HTTP request")
    end
    local bp = false
    for P, u in ipairs(Y) do
        if options[u] ~= nil then
            if bp then
                return error("can only set options.params, options.body or options.json")
            else
                bp = true
            end
        end
    end
    local bq
    local bs = options.network_timeout
    if bs == nil then
        bs = 10
    end
    if type(bs) == "number" and bs > 0 then
        if not al(b4, bs) then
            return b3(b4, "failed to set network_timeout")
        end
    elseif bs ~= nil then
        return b3(b4, "options.network_timeout has to be of type number and greater than 0")
    end
    local bt = options.absolute_timeout
    if bt == nil then
        bt = 30
    end
    if type(bt) == "number" and bt > 0 then
        if not aG(b4, bt * 1000) then
            return b3(b4, "failed to set absolute_timeout")
        end
    elseif bt ~= nil then
        return b3(b4, "options.absolute_timeout has to be of type number and greater than 0")
    end
    local bu = bq ~= nil and "application/json" or "text/plain"
    local bv
    local b9 = options.headers
    if type(b9) == "table" then
        for aU, V in pairs(b9) do
            aU = tostring(aU)
            V = tostring(V)
            local bw = string.lower(aU)
            if bw == "content-type" then
                bu = V
            elseif bw == "authorization" then
                bv = true
            end
            if not am(b4, aU, V) then
                return b3(b4, "failed to set header " .. aU)
            end
        end
    elseif b9 ~= nil then
        return b3(b4, "options.headers has to be of type table")
    end
    local bx = options.authorization
    if type(bx) == "table" then
    elseif bx ~= nil then
        return b3(b4, "options.authorization has to be of type table")
    end
    local by = bq or options.body
    if type(by) == "string" then
        local bz = string.len(by)
        if not az(b4, bu, a.cast("unsigned char*", by), bz) then
            return b3(b4, "failed to set post body")
        end
    elseif by ~= nil then
        return b3(b4, "options.body has to be of type string")
    end
    local bA = options.params
    if type(bA) == "table" then
        for aU, V in pairs(bA) do
            aU = tostring(aU)
            if not an(b4, aU, tostring(V)) then
                return b3(b4, "failed to set parameter " .. aU)
            end
        end
    elseif bA ~= nil then
        return b3(b4, "options.params has to be of type table")
    end
    local bB = options.require_ssl
    if type(bB) == "boolean" then
        if not aF(b4, bB == true) then
            return b3(b4, "failed to set require_ssl")
        end
    elseif bB ~= nil then
        return b3(b4, "options.require_ssl has to be of type boolean")
    end
    local bC = options.user_agent_info
    if type(bC) == "string" then
        if not aE(b4, tostring(bC)) then
            return b3(b4, "failed to set user_agent_info")
        end
    elseif bC ~= nil then
        return b3(b4, "options.user_agent_info has to be of type string")
    end
    local bD = options.cookie_container
    if type(bD) == "table" then
        local U = aO[bD]
        if U ~= nil and U.m_hCookieContainer ~= 0 then
            if not aD(b4, U.m_hCookieContainer) then
                return b3(b4, "failed to set user_agent_info")
            end
        else
            return b3(b4, "options.cookie_container has to a valid cookie container")
        end
    elseif bD ~= nil then
        return b3(b4, "options.cookie_container has to a valid cookie container")
    end
    local bE = ao
    local bF = options.stream_response
    if type(bF) == "boolean" then
        if bF then
            bE = ap
            if bm == nil and bn == nil and bo == nil then
                return b3(b4, "a 'completed', 'headers_received' or 'data_received' callback is required")
            end
        else
            if bm == nil then
                return b3(b4, "'completed' callback has to be set for non-streamed requests")
            elseif bn ~= nil or bo ~= nil then
                return b3(b4, "non-streamed requests only support 'completed' callbacks")
            end
        end
    elseif bF ~= nil then
        return b3(b4, "options.stream_response has to be of type boolean")
    end
    if bn ~= nil or bo ~= nil then
        aL[b4] = bn or false
        if bn ~= nil then
            if not aK then
                e(_, bf)
                aK = true
            end
        end
        aN[b4] = bo or false
        if bo ~= nil then
            if not aM then
                e(a0, bg)
                aM = true
            end
        end
    end
    local bG = ab()
    if not bE(b4, bG) then
        ax(b4)
        if bm ~= nil then
            bm(false, {status = 0, status_message = "Failed to send request"})
        end
        return
    end
    if options.priority == "defer" or options.priority == "prioritize" then
        local a5 = options.priority == "prioritize" and ar or aq
        if not a5(b4) then
            return b3(b4, "failed to set priority")
        end
    elseif options.priority ~= nil then
        return b3(b4, "options.priority has to be 'defer' of 'prioritize'")
    end
    aI[b4] = bm or false
    if bm ~= nil then
        d(bG[0], ba, Z)
    end
end
local function bH(bI)
    if bI ~= nil and type(bI) ~= "boolean" then
        return error("allow_modification has to be of type boolean")
    end
    local bJ = aA(bI == true)
    if bJ ~= nil then
        local U = aa(bJ)
        a.gc(U, b1)
        local u = setmetatable({}, aY)
        aO[u] = U
        return u
    end
end
local bK = {request = bi, create_cookie_container = bH}
for bj in pairs(W) do
    bK[bj] = function(...)
        return bi(bj, ...)
    end
end
return bK
end)
__bundle_register("libs.delay", function(require, _LOADED, __bundle_register, __bundle_modules)
local cbs = require("libs.callbacks")
local fns = {}
cbs.paint(function()
    for i = 1, #fns do
        if fns[i] and fns[i].time <= globalvars.get_real_time() then
            fns[i].fn()
            table.remove(fns, i)
        end
    end
end)

return {
    add = function(fn, time)
        fns[#fns+1] = {
            fn = fn,
            time = globalvars.get_real_time() + time / 1000,
        }
    end,
}
end)
__bundle_register("includes.gui", function(require, _LOADED, __bundle_register, __bundle_modules)
local drag = require("libs.drag")
local v2 = require("libs.vectors")()
local anims = require("libs.anims")
local errors = require("libs.error_handler")
local render = require("libs.render")
local cbs = require("libs.callbacks")
local col = require("libs.colors")
local click_effect = require("includes.gui.click_effect")
local input = require("libs.input")

gui = {
    size = v2(560, 380),
    drag = drag.new("magnolia", v2(0.5, 0.5), false),
    ---@type gui_tab_t[]
    elements = {},
    anims = anims.new({
        main_alpha = 0
    }),
    initialized = false,
    can_be_visible = false,
    active_tab = 1,
    current_options = nil,
    hovered = false,
    paddings = {
        menu_padding = 14,
        subtab_list_width = 114,
        options_container_padding = 10,
        inline_padding = 4,
    }
}

gui.get_path = errors.handler(function(name)
    local tab = gui.elements[#gui.elements] or {name = "main", subtabs = {{name = "main"}}}
    local path = {
        tab.name,
        tab.subtabs[#tab.subtabs].name,
        name
    }
    if gui.current_options then
        path = {
            gui.current_options.path,
            #gui.current_options.parent.inline,
            name
        }
    end
    return table.concat(path, "_")
end, "gui.get_path")

gui.add_element = errors.handler(function (element)
    if gui.current_options then
        table.insert(gui.current_options.columns[#gui.current_options.columns].elements, element)
        return element
    end
    local tab = gui.elements[#gui.elements]
    local subtab = tab.subtabs[#tab.subtabs]

    -- element.tab = #gui.elements
    -- element.subtab = #tab.subtabs
    table.insert(subtab.columns[#subtab.columns].elements, element)
    return element
end, "gui.add_element")

require("includes.gui.fonts")
require("includes.gui.tab")
local subtab_t = require("includes.gui.subtab")
local container_t = require("includes.gui.container")
local popouts_t = require("includes.gui.popouts")
require("includes.gui.column")
local header_t = require("includes.gui.header")

gui.init = function()
    gui.initialized = true
end

require("includes.gui.elements")

gui.is_another_dragging = function()
    for _, elem in pairs(drag.__elements) do
        if elem.dragging and elem.key ~= gui.drag.key then
            return true
        end
    end
end
gui.is_input_allowed = errors.handler(function()
    if header_t.is_popout_open() then return false end
    local tab = gui.elements[gui.active_tab]
    for j = 1, #tab.subtabs do
        local subtab = tab.subtabs[j]
        if subtab.active then
            for _, column in ipairs(subtab.columns) do
                if not column:input_allowed() then
                    return false
                end
            end
        end
    end
    if gui.is_another_dragging() then
        return false
    end
    return true
end, "gui.is_input_allowed")

---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
gui.draw = errors.handler(function (pos, alpha, input_allowed)
    local background_color = col(18, 17, 16, (alpha / 255) * 250)

    render.rounded_rect(pos + v2(1, 1), pos + gui.size, background_color, 7, true)
    render.rounded_rect(pos, pos + gui.size, col.black:alpha(200):salpha(alpha), 7.5)

    header_t.draw(pos, alpha, input_allowed)
    container_t.draw(pos, alpha, input_allowed)
    subtab_t.draw(pos, alpha, input_allowed)
end, "gui.draw")

cbs.paint(errors.handler(function()
    if not gui or not gui.initialized or not gui.can_be_visible then return end
    local main_alpha = gui.anims.main_alpha(ui.is_visible() and 255 or 0, 20)
    if main_alpha == 0 then return end
    local input_allowed = gui.is_input_allowed()
    local is_hovered
    local pos = gui.drag:run(function(pos)
        is_hovered = input_allowed and drag.hover_absolute(pos - gui.size / 2, pos - gui.size / 2 + v2(gui.size.x, 48))
        return is_hovered
    end)
    gui.hovered = drag.hover_absolute(pos - gui.size / 2, pos + gui.size / 2)
    if (is_hovered and not input.is_key_pressed(1)) or gui.drag.dragging then
        drag.set_cursor(drag.move_cursor)
    end
    pos = (pos - gui.size / 2):round()
    gui.pos = pos
    gui.draw(pos, main_alpha, input_allowed and not gui.drag.dragging)
    popouts_t.draw()
    header_t.draw_popout(main_alpha)
    click_effect.draw()
end, "gui.paint"))


return gui
end)
__bundle_register("includes.gui.elements", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.entity")
require("libs.ragebot_lib")
local ffi = require("libs.protected_ffi")
local render = require("libs.render")
local col = require("libs.colors")
local input = require("libs.input")
local fonts = require("includes.gui.fonts")
local v2, v3 = require("libs.vectors")()
local shared = require("features.shared")
local cbs = require("libs.callbacks")
local iengine = require("includes.engine")
local anims = require("libs.anims")
local hooks = require("libs.hooks")
local win32 = require("libs.win32")
local set = require("libs.set")
local colors = require("includes.colors")
local errors = require("libs.error_handler")
local drag = require("libs.drag")
local delay = require("libs.delay")
require("features.create_move_hk")
require("features.revealer")
require("features.grenade_prediction")
-- local feature_animbreaker = require("features.animbreaker")

gui.tab("Aimbot", "B")
gui.subtab("General")
do
    gui.checkbox("Jumpscout"):options(function ()
        gui.slider("Jumpscout hitchance", 40, 100, false, 60)
        gui.checkbox("Autostop in air")
    end):create_move(function (cmd, el)
        ui.get_key_bind("antihit_accurate_walk_bind"):set_type(1)
        local lp = entitylist.get_local_player()
        if not lp or not lp:is_alive() or lp:is_on_ground() then return end
        if lp:get_weapon().group ~= "scout" then return end
        local hitchance = el:get_slider("Jumpscout hitchance"):value()
        ragebot.override_hitchance(hitchance)
        local autostop = el:get_checkbox("Autostop in air"):value()
        if not autostop or input.is_key_pressed(32) then return end
        if not lp:can_shoot() then return end
        local max_distance = 350 / (hitchance / 100)
        for _, entity in pairs(entitylist.get_players(0)) do
            if entity:is_alive() and entity:is_hittable_by(lp) then
                local distance = lp.m_vecOrigin:dist_to(entity.m_vecOrigin)
                if distance > max_distance then
                    return
                end
                ui.get_key_bind("antihit_accurate_walk_bind"):set_type(0)
                ui.get_check_box("antihit_accurate_walk"):set_value(true)
                return
            end
        end
    end)
end
gui.column()
-- gui.checkbox("Hitbox override")
-- gui.checkbox("HP conditions")

gui.subtab("Exploits")
-- gui.checkbox("Ideal tick")
-- gui.checkbox("Improve speed")
-- gui.checkbox("Auto teleport")
gui.subtab("Misc")
gui.tab("Anti-Aim", "C")
gui.subtab("General")
require("features.antiaim")

gui.tab("Visuals", "D")
gui.subtab("Players")
gui.subtab("World")
do
    local bullet_tracers = require("features.bullet_tracers")
    local tracers = gui.checkbox("Bullet tracers"):options(function()
        gui.slider("Time", 1, 10, 1, 4)
    end):update(function(el)
        ui.get_check_box("visuals_esp_local_enable"):set_value(el:value())
        ui.get_check_box("visuals_esp_local_tracers"):set_value(el:value())
    end)
    local impacts = gui.checkbox("Bullet impacts"):options(function()
        gui.slider("Time", 1, 10, 1, 4)
    end)
    gui.column()
    cbs.event("bullet_impact", function(event)
        if not impacts:value() then return end
        local lp = entitylist.get_local_player()
        if not lp or not lp:is_alive() then return end
        local userid = lp:get_info().user_id
        if event:get_int("userid", 0) ~= userid then return end
        local pos = v3(event:get_float("x", 0), event:get_float("y", 0), event:get_float("z", 0))
        iengine.add_box_overlay(pos, impacts:get_slider("Time"):value(), col.blue:alpha(127))
    end)
    client.register_callback("shot_fired", function (shot_info)
        if not impacts:value() then return end
        iengine.add_box_overlay(shot_info.aim_point, impacts:get_slider("Time"):value(), col.red:alpha(127))
    end)
    bullet_tracers.callback = function(from, to)
        if tracers:value() then
            iengine.add_line_overlay(from, to, tracers:get_slider("Time"):value(), col.white:alpha(255))
            return true
        end
        return false
    end
    -- ---@type { from: vec3_t, to: vec3_t, time: number, anims: __anims_mt }[]
    -- local tracers_list = {}
    -- cbs.on_shot_fired(function(shot)
    --     -- tracers_list[#tracers_list+1] = {
    --     --     from = shot.from,
    --     --     to = shot.to,
    --     --     time = globalvars.get_real_time(),
    --     --     anims = anims.new({
    --     --         alpha = 255
    --     --     })
    --     -- }
    -- end)
    -- cbs.paint(function (cmd)
        -- if not tracers:value() then return end
        -- local time = tracers:get_slider("Time"):value()
        -- local current_time = globalvars.get_real_time()
        -- for i = 1, #tracers_list do
        --     local tracer = tracers_list[i]
        --     local alpha = tracer.anims.alpha(current_time < tracer.time + time and 255 or 0)
        --     local from, to = iengine.world_to_screen(tracer.from), iengine.world_to_screen(tracer.to)
        --     if from and to then
        --         renderer.line(from, to, col.white:alpha(alpha))
        --     end
        -- end
        -- for i = 1, #tracers_list do
        --     local tracer = tracers_list[i]
        --     if tracer and tracer.anims.alpha() <= 0 then
        --         table.remove(tracers_list, i)
        --     end
        -- end
    -- end)
    -- gui.checkbox("Move lean"):callback("frame_stage_notify", function (stage, el)
    --     local lp = entitylist.get_local_player()
    --     if not lp or not lp:is_alive() then return end
    --     local animlayer = lp:get_animlayer(12)
    --     --get address of animlayer.weight
    --     -- print(tostring(animlayer))
    --     if not animlayer then return end
    --     -- animlayer.weight = 1 
    -- end)
    -- local offset = client.find_pattern("client.dll", "? ? ? ? F8 81 ? ? ? ? ? 53 56 8B F1 57 89 74 24 1C")
    -- local offset = client.find_pattern("client.dll", "? ? ? ? ? F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B")
    -- if offset ~= 0 then
    --     print("found")
    --     local bytes = ffi.cast("unsigned char*", offset)
    --     local new_bytes = ffi.new("uint8_t[?]", 5, {0x55, 0x8B, 0xEC, 0x83, 0xE4})
    --     local old_protect = ffi.new("DWORD[1]")
    --     win32.VirtualProtect(bytes, 5, 0x40, old_protect)
    --     win32.copy(bytes, new_bytes, 5)
    --     win32.VirtualProtect(bytes, 5, old_protect[0], old_protect)
    --     local hook
    --     local hk_setupbones = function(this, out, max, mask, time)
    --         -- if ecx then

    --         -- end
    --         print("hello")
    --         return hook(this, out, max, mask, time)
    --     end
    --     hook = hooks.jmp.new("bool(__thiscall*)(void* this, void* out, int max, int mask, float time)", hk_setupbones, offset)
    --     client.register_callback("unload", function()
    --         hook.stop()
    --     end)
    -- end
end
gui.subtab("Local")
gui.checkbox("Custom model"):options(function ()
    local list = {
        {"Local T Agent", "tm_phoenix"},
    	{"Local CT Agent", "ctm_sas"},
    	{"Blackwolf | Sabre", "tm_balkan_variantj"},
    	{"Rezan The Ready | Sabre", "tm_balkan_variantg"},
    	{"Maximus | Sabre", "tm_balkan_varianti"},
    	{"Dragomir | Sabre", "tm_balkan_variantf"},
    	{"Lt. Commander Ricksaw | NSWC SEAL", "ctm_st6_varianti"},
    	{"'Two Times' McCoy | USAF TACP", "ctm_st6_variantm"},
    	{"Buckshot | NSWC SEAL", "ctm_st6_variantg"},
    	{"Seal Team 6 Soldier | NSWC SEAL", "ctm_st6_variante"},
    	{"3rd Commando Company | KSK", "ctm_st6_variantk"},
    	{"'The Doctor' Romanov | Sabre", "tm_balkan_varianth"},
    	{"Michael Syfers  | FBI Sniper", "ctm_fbi_varianth"},
    	{"Markus Delrow | FBI HRT", "ctm_fbi_variantg"},
    	{"Operator | FBI SWAT", "ctm_fbi_variantf"},
    	{"Slingshot | Phoenix", "tm_phoenix_variantg"},
    	{"Enforcer | Phoenix", "tm_phoenix_variantf"},
    	{"Soldier | Phoenix", "tm_phoenix_varianth"},
    	{"The Elite Mr. Muhlik | Elite Crew", "tm_leet_variantf"},
    	{"Prof. Shahmat | Elite Crew", "tm_leet_varianti"},
    	{"Osiris | Elite Crew", "tm_leet_varianth"},
    	{"Ground Rebel | Elite Crew", "tm_leet_variantg"},
    	{"Special Agent Ava | FBI", "ctm_fbi_variantb"},
    	{"B Squadron Officer | SAS", "ctm_sas_variantf"},
    	{"Anarchist", "tm_anarchist"},
    	{"Anarchist (A)", "tm_anarchist_varianta"},
    	{"Anarchist (B)", "tm_anarchist_variantb"},
    	{"Anarchist (C)", "tm_anarchist_variantc"},
    	{"Anarchist (D)", "tm_anarchist_variantd"},
    	{"Pirate", "tm_pirate"},
    	{"Pirate (A)", "tm_pirate_varianta"},
    	{"Pirate (B)", "tm_pirate_variantb"},
    	{"Pirate (C)", "tm_pirate_variantc"},
    	{"Pirate (D)", "tm_pirate_variantd"},
    	{"Professional", "tm_professional"},
    	{"Professional (1)", "tm_professional_var1"},
    	{"Professional (2)", "tm_professional_var2"},
    	{"Professional (3)", "tm_professional_var3"},
    	{"Professional (4)", "tm_professional_var4"},
    	{"Separatist", "tm_separatist"},
    	{"Separatist (A)", "tm_separatist_varianta"},
    	{"Separatist (B)", "tm_separatist_variantb"},
    	{"Separatist (C)", "tm_separatist_variantc"},
    	{"Separatist (D)", "tm_separatist_variantd"},
    	{"GIGN", "ctm_gign"},
    	{"GIGN (A)", "ctm_gign_varianta"},
    	{"GIGN (B)", "ctm_gign_variantb"},
    	{"GIGN (C)", "ctm_gign_variantc"},
    	{"GIGN (D)", "ctm_gign_variantd"},
    	{"GSG-9", "ctm_gsg9"},
    	{"GSG-9 (A)", "ctm_gsg9_varianta"},
    	{"GSG-9 (B)", "ctm_gsg9_variantb"},
    	{"GSG-9 (C)", "ctm_gsg9_variantc"},
    	{"GSG-9 (D)", "ctm_gsg9_variantd"},
    	{"IDF", "ctm_idf"},
    	{"IDF (B)", "ctm_idf_variantb"},
    	{"IDF (C)", "ctm_idf_variantc"},
    	{"IDF (D)", "ctm_idf_variantd"},
    	{"IDF (E)", "ctm_idf_variante"},
    	{"IDF (F)", "ctm_idf_variantf"},
    	{"SWAT", "ctm_swat"},
    	{"SWAT (A)", "ctm_swat_varianta"},
    	{"SWAT (B)", "ctm_swat_variantb"},
    	{"SWAT (C)", "ctm_swat_variantc"},
    	{"SWAT (D)", "ctm_swat_variantd"},
    	{"SAS", "ctm_sas_varianta"},
    	{"ST6", "ctm_st6"},
    	{"ST6 (A)", "ctm_st6_varianta"},
    	{"ST6 (B)", "ctm_st6_variantb"},
    	{"ST6 (C)", "ctm_st6_variantc"},
    	{"ST6 (D)", "ctm_st6_variantd"},
    	{"Balkan (E)", "tm_balkan_variante"},
    	{"Balkan (A)", "tm_balkan_varianta"},
    	{"Balkan (B)", "tm_balkan_variantb"},
    	{"Balkan (C)", "tm_balkan_variantc"},
    	{"Balkan (D)", "tm_balkan_variantd"},
    	{"Jumpsuit (A)", "tm_jumpsuit_varianta"},
    	{"Jumpsuit (B)", "tm_jumpsuit_variantb"},
    	{"Jumpsuit (C)", "tm_jumpsuit_variantc"},
    	{"Phoenix Heavy", "tm_phoenix_heavy"},
    	{"Heavy", "ctm_heavy"},
    	{"Leet (A)", "tm_leet_varianta"},
    	{"Leet (B)", "tm_leet_variantb"},
    	{"Leet (C)", "tm_leet_variantc"},
    	{"Leet (D)", "tm_leet_variantd"},
    	{"Leet (E)", "tm_leet_variante"},
    	{"Phoenix", "tm_phoenix"},
    	{"Phoenix (A)", "tm_phoenix_varianta"},
    	{"Phoenix (B)", "tm_phoenix_variantb"},
    	{"Phoenix (C)", "tm_phoenix_variantc"},
    	{"Phoenix (D)", "tm_phoenix_variantd"},
    	{"FBI", "ctm_fbi"},
    	{"FBI (A)", "ctm_fbi_varianta"},
    	{"FBI (C)", "ctm_fbi_variantc"},
    	{"FBI (D)", "ctm_fbi_variantd"},
    	{"FBI (E)", "ctm_fbi_variante"},
    }
    for i = 1, #list do
        list[i][2] = "legacy/" .. list[i][2]
    end
    local custom_models_path_relative = "models/player/custom_player/"
    local custom_models_path = "csgo/" .. custom_models_path_relative
    local ext = ".mdl"
    local custom_model_dirs = win32.dir(custom_models_path, false, ext, true)
    if not custom_model_dirs then
        gui.label("No custom models found")
        return
    end
    local is_allowed = function(name, param)
        return not name:find("_" .. param) and not name:find(param .. "_")
    end
    for i = #custom_model_dirs, 1, -1 do
        local name = custom_model_dirs[i]:sub(1, -#ext-1)
        if is_allowed(name, "arms")
        and is_allowed(name, "emote")
        and is_allowed(name, "bone")
        and not name:find("anims") then
            table.insert(list, 1, {name, name})
        end
    end
    local name_index_list = {}
    local model_names = {}
    for i = 1, #list do
        local name = list[i][1]
        if #name > 31 then
            --get last 31 characters
            name = "..." .. name:sub(-28)
        end
        list[i][1] = name
        model_names[i] = name
        name_index_list[name] = i
    end
    gui.label("You can use down and up arrow keys to change")
    gui.label("All default models are in the bottom")
    local ct_agent = gui.dropdown("CT agent", model_names)
    local ct_agent_textinput = ui.add_text_input("ct_agent_textinput", "ct_agent_textinput", "")
    ct_agent_textinput:set_visible(false)
    local t_agent = gui.dropdown("T agent", model_names)
    local t_agent_textinput = ui.add_text_input("t_agent_textinput", "t_agent_textinput", "")
    t_agent_textinput:set_visible(false)
    cbs.frame_stage(function()
        if not ui.is_visible() then return end
        local ct_agent_value, t_agent_value = ct_agent_textinput:get_value(), t_agent_textinput:get_value()
        if name_index_list[ct_agent_value] then
            local val = name_index_list[ct_agent_value] - 1
            if val ~= ct_agent:val_index() then
                ct_agent.el:set_value(val)
            end
        end
        if name_index_list[t_agent_value] then
            local val = name_index_list[t_agent_value] - 1
            if val ~= t_agent:val_index() then
                t_agent.el:set_value(val)
            end
        end
    end)
    delay.add(function()
        ct_agent:update(function(el)
            ct_agent_textinput:set_value(el:value())
        end)
        t_agent:update(function(el)
            t_agent_textinput:set_value(el:value())
        end)
    end, 300)
    cbs.frame_stage(function(stage)
        if stage ~= 2 then return end
        local lp = entitylist.get_local_player()
        if not lp then return end
        local ct_model = ct_agent:val_index()
        local t_model = t_agent:val_index()
        if ct_model < 0 and t_model < 0 then return end
        local ct_model_name = list[ct_model][2]
        local t_model_name = list[t_model][2]
        local ct_model_path = custom_models_path_relative .. ct_model_name .. ext
        local t_model_path = custom_models_path_relative .. t_model_name .. ext
        local teamnum = lp.m_iTeamNum
        local model_path
        if teamnum == 2 then
            model_path = t_model_path
        elseif teamnum == 3 then
            model_path = ct_model_path
        end
        if not model_path then return end
        lp:set_model(model_path)
    end, "custom_model.frame_stage")
end)
do
    local setup_bones = require("features.animbreaker")
    local leg_movement = ui.get_combo_box("antihit_leg_movement")
    gui.label("Animbreaker"):options(function ()
        setup_bones.walk_legs = gui.dropdown("Walking legs", {"Default", "Slide", "Walking"})
        setup_bones.air_legs = gui.dropdown("Air legs", {"Default", "Static", "Walking"})
    end):create_move(function(cmd)
        local walk_legs = setup_bones.walk_legs:value()
        if walk_legs == "Slide" then
            local choked = clientstate.get_choked_commands() > 0
            leg_movement:set_value(choked and 2 or 1)
        elseif walk_legs == "Walking" then
            leg_movement:set_value(1)
        end
    end)
end
gui.column()


gui.subtab("Widgets")
do
    local logs = gui.checkbox("Ragebot logs"):options(function ()
        gui.checkbox("Under crosshair"):options(function ()
            gui.dropdown("Type", {"Text", "Box"})
            gui.dropdown("Sort", {"Newest at top", "Oldest at top"})
            gui.dropdown("Appear position", {"Top", "Bottom"})
        end)
    end)
    local unfiltred_other_events = {}
    ---@type { short_text: table, text: table, time: number, color: color_t, anims: { alpha: __anim_mt, active: __anim_mt } }[]
    local events = {}
    ---@param pos vec2_t
    ---@param size vec2_t
    ---@param color color_t
    ---@param alpha number
    ---@param active_anim number
    local render_container = function(pos, size, color, alpha, active_anim)
        pos, size = pos:round(), size:round()
        local radius = 5
        local accent_color = color:alpha(alpha)
        local active_color = accent_color:salpha(active_anim / 2 + 127)
        render.box_shadow(pos, pos + size, active_color, radius)
        render.rounded_rect(pos, pos + size, col.black:alpha(alpha / 1.25), radius, true)
        local margin = 20
        render.circle(pos + v2(radius, radius), radius + 0.1, accent_color, 190, 270, false)
        render.circle(pos + size - v2(radius + 1, radius + 1), radius + 0.1, accent_color, 10, 90, false)
        local width = margin + (size.x - margin) * active_anim / 255
        do
            local from = pos + v2(radius + 1, 0)
            renderer.rect_filled_fade(from, from + v2(width, 1), accent_color, accent_color:alpha(0), accent_color:alpha(0), accent_color)
        end
        do
            local from = pos + size - v2(radius, 0)
            renderer.rect_filled_fade(from, from - v2(width, 1), accent_color, accent_color:alpha(0), accent_color:alpha(0), accent_color)
        end
        do
            local from = pos + v2(0, radius)
            renderer.rect_filled_fade(from, from + v2(1, size.y - radius * 2 - 1), accent_color, accent_color, accent_color:alpha(0), accent_color:alpha(0))
        end
        do
            local from = pos + v2(size.x - 1, radius + 1)
            renderer.rect_filled_fade(from, from + v2(1, size.y - radius * 2 - 1), accent_color:alpha(0), accent_color:alpha(0), accent_color, accent_color)
        end
    end
    local logs_drag = drag.new("rage_logs", v2(0.5, 0.6), true)
    local under_crosshair = logs:get_options("Under crosshair"):paint(function (el)
        local drag_size = v2(250, 100)
        local pos, highlight = logs_drag:run(drag.hover_fn(drag_size, true), function (pos, alpha)
            drag.highlight(pos - v2(drag_size.x / 2, 0), drag_size, alpha)
        end)
        -- render.dot(pos, col.red, 10)
        -- local type = el:get_dropdown("Type")
        local sort = el:get_dropdown("Sort")
        local reverse_sort = sort:value() ~= "Newest at top"
        local start_i = reverse_sort and 1 or #events
        local end_i = not reverse_sort and 1 or #events
        local loop_step = reverse_sort and 1 or -1
        local y = 0
        for i = start_i, end_i, loop_step do
            local event = events[i]
            if event then
                local alpha = event.anims.alpha()
                local active_anim = event.anims.active()
                local text_size = render.multi_text_size(event.short_text, fonts.gamesense) + v2(20, 0)
                render_container(pos + v2(-text_size.x / 2, y), v2(text_size.x, 26), event.color, alpha, active_anim)
                render.multi_color_text(event.short_text, fonts.gamesense, pos + v2(0, y + 7), render.flags.X_ALIGN + render.flags.SHADOW, alpha)

                y = y + math.round(30 * alpha / 255)
            end
        end
        highlight()
    end)
    cbs.paint(function ()
        local realtime = globalvars.get_real_time()
        local timeout = 2
        for i = 1, #events do
            local event = events[i]
            if event then
                local fading_out = #events - i > 9 or event.time + timeout < realtime
                event.anims.active(math.clamp(event.time + timeout - realtime, 0, timeout) / timeout * 255)
                local alpha = event.anims.alpha(not fading_out and 255 or 0)
                if alpha <= 0 then
                    table.remove(events, i)
                end
            end
        end
    end)
    local human_readable = {
        hegrenade = "explosion",
        smokegrenade = "grenade punch (lol)",
        inferno = "fire",
        decoy = "decoy punch or explosion (lol)",
        flashbang = "flashbang punch (lol)",
        taser = "taser",
        knife = "knife",
        molotov = "molotov punch (lol)"
    }
    cbs.event("player_hurt", function (event)
        local lp = entitylist.get_local_player()
        if entitylist.get_entity_by_userid(event:get_int("attacker", 0)) ~= lp then return end
        local killed = event:get_int("health", 0) < 1
        local uid = event:get_int("userid", 0)
        local entity = entitylist.get_entity_by_userid(uid)
        if not entity then return end
        if entity == lp then return end
        local color = colors.magnolia
        if killed then color = col.green end
        local weapon = event:get_string("weapon", "")
        local human_readable_weapon = human_readable[weapon]
        if not human_readable_weapon then return end
        local dmg = event:get_int("dmg_health", 0)
        local entity_name = entity:get_info().name
        local short_text = {
            {entity_name, col.white},
            {" -", color},
            {tostring(dmg), color},
        }
        local tickcount = globalvars.get_tick_count()
        unfiltred_other_events[tickcount] = unfiltred_other_events[tickcount] or {}
        unfiltred_other_events[tickcount][uid] = unfiltred_other_events[tickcount][uid] or {}
        if unfiltred_other_events[tickcount][uid][weapon] then
            unfiltred_other_events[tickcount][uid][weapon].dmg = unfiltred_other_events[tickcount][uid][weapon].dmg + dmg
            if killed then
                unfiltred_other_events[tickcount][uid][weapon].killed = true
            end
        else
            unfiltred_other_events[tickcount][uid][weapon] = {
                entity = event:get_int("userid", 0),
                type = weapon,
                short_text = short_text,
                time = globalvars.get_real_time(),
                tickcount = tickcount,
                dmg = dmg,
                killed = killed,
                color = color,
            }
        end
    end)
    cbs.frame_stage(function(stage)
        if stage ~= 5 then return end
        if not logs:value() then return end
        for _, entities in pairs(unfiltred_other_events) do
            for _, types in pairs(entities) do
                for _, event in pairs(types) do
                    local entity_name = entitylist.get_entity_by_userid(event.entity):get_info().name
                    local human_readable_weapon = human_readable[event.type]
                    local color = colors.magnolia
                    if event.killed then color = col.green end
                    local text = {
                        {event.killed and "killed " or "hit ", col.white},
                        {entity_name, color},
                        {" for ", col.white},
                        {tostring(event.dmg), color},
                        {" with ", col.white},
                        {human_readable_weapon, color},
                    }
                    local short_text = {
                        {entity_name, col.white},
                        {" -", col.white},
                        {tostring(event.dmg), color},
                    }
                    events[#events+1] = {
                        short_text = short_text,
                        text = text,
                        time = globalvars.get_real_time(),
                        anims = anims.new({
                            alpha = 0,
                            active = 255,
                        }),
                        color = color,
                    }
                    iengine.log(text)
                end
            end
        end
        unfiltred_other_events = {}
    end)
    local prepend_info = function (info, text, color)
        if #info > 0 then
            text[#text + 1] = {" ["}
            for i = 1, #info do
                text[#text + 1] = {info[i], color}
                if i ~= #info then
                    text[#text + 1] = {" | "}
                end
            end
            text[#text + 1] = {"]"}
        end
        return text
    end
    ---@param shot_info shot_info_t
    client.register_callback("shot_fired", errors.handler(function (shot_info)
        if shot_info.manual then return end
        local entity = entitylist.get_entity_by_index(shot_info.target_index)
        local name = entity:get_info().name
        local additional_info = {}
        local short_text, text
        local color
        if shot_info.result ~= "hit" then
            local target_hitbox = iengine.get_hitbox_name(shot_info.hitbox)
            ---@type string
            local reason = shot_info.result
            if reason == "unk" then
                reason = "?"
            elseif reason == "spread" then
                additional_info[#additional_info + 1] = tostring(shot_info.hitchance) .. "⁒"
            elseif reason == "desync" then
                reason = "resolver"
                if shot_info.safe_point then
                    additional_info[#additional_info + 1] = "safe"
                end
            end
            additional_info[#additional_info + 1] = tostring(shot_info.client_damage) .. "dmg"
            additional_info[#additional_info + 1] = tostring(shot_info.backtrack) .. "t"
            color = col.red
            text = {
                {"missed ", col.white},
                {name, color},
                {"'s ", col.white},
                {target_hitbox, color},
                {" due to ", col.white},
                {reason, color}
            }
            short_text = {
                {name, col.white},
                {" ", col.white},
                {target_hitbox, color},
                {" [", col.white},
                {reason,color},
                {"]", col.white}
            }
            text = prepend_info(additional_info, text)
            iengine.log(text)
        else
            if shot_info.server_hitgroup == 0 then return end
            local mismatch_info = {}
            local killed = entity.m_iHealth < 1
            color = killed and col.green or colors.magnolia
            local client_hitgroup = iengine.hitbox_to_hitgroup(shot_info.hitbox)
            local damage_mismatch = not killed and (shot_info.client_damage - shot_info.server_damage > 3)
            local hitgroup_mismatch = client_hitgroup ~= shot_info.server_hitgroup
            if damage_mismatch then
                mismatch_info[#mismatch_info + 1] = tostring(shot_info.client_damage) .. " dmg"
            end
            if hitgroup_mismatch then
                mismatch_info[#mismatch_info + 1] = iengine.get_hitgroup_name(client_hitgroup)
            end
            if damage_mismatch or hitgroup_mismatch then
                additional_info[#additional_info + 1] = tostring(shot_info.hitchance) .. "⁒"
                if shot_info.safe_point then
                    additional_info[#additional_info + 1] = "safe"
                end
            end
            local server_hitgroup = iengine.get_hitgroup_name(shot_info.server_hitgroup)
            additional_info[#additional_info + 1] = tostring(shot_info.backtrack) .. "t"
            text = {
                {killed and "killed " or "hit ", col.white},
                {name, color},
                {" in ", col.white},
                {server_hitgroup, color},
                {" for ", col.white},
                {tostring(shot_info.server_damage), color},
            }
            text = prepend_info(additional_info, text)
            if #mismatch_info > 0 then
                text[#text+1] = {" mismatch:", col.red}
                text = prepend_info(mismatch_info, text, col.red)
            end
            short_text = {
                {name, col.white},
                {" ", col.white},
                {server_hitgroup, color},
                {" -", col.white},
                {tostring(shot_info.server_damage), color},
            }
            iengine.log(text)
        end
        events[#events+1] = {
            short_text = short_text,
            text = text,
            time = globalvars.get_real_time(),
            color = color,
            anims = anims.new({
                alpha = 0,
                active = 255,
            })
        }
    end, "rage_logs.shot_fired"))
end
gui.subtab("Misc")
do
    local cvar = se.get_convar("fov_cs_debug")
    gui.checkbox("Viewmodel in scope"):paint(function (el)
        local value = el:value() and 90 or 0
        if cvar:get_int() ~= value then
            cvar:set_int(value)
        end
    end)
end
do
    local cvar = se.get_convar("cam_idealdist")
    local distance
    gui.checkbox("Thirdperson"):options(function ()
        distance = gui.slider("Distance", 0, 200, 0, 50)
    end):paint(function(el)
        local value = distance:value()
        if ui.get_key_bind("visuals_thirdperson_bind"):is_active() and cvar:get_int() ~=  value then
            cvar:set_int(value)
        end
    end)
end

gui.column()

gui.tab("Misc", "E")
gui.subtab("General")
do
    local primary, secondary, other
    local buybot = gui.checkbox("Buybot"):options(function()
        primary = gui.dropdown("Primary", {"None", "Scout", "AWP", "Auto", "AK47 / M4A1", "Nova", "XM1014", "MAG-7", "MAC10 / MP9", "MP7", "UMP45", "P90", "Bizon"})
        secondary = gui.dropdown("Secondary", {"None", "Deagle / R8", "Dualies", "P250", "Tec-9 / Five-SeveN", "Glock-18 / USP-S"})
        other = gui.dropdown("Other", {"Armor", "HE", "Molotov", "Smoke", "Flashbang", "Zeus", "Defuse kit"}, {})
    end)
    local buybot_fn = function()
        if not buybot:value() then return end
        local lp = entitylist.get_local_player()
        if not lp then return end
        if lp.m_iAccount <= 800 then return end
        local pistols_list = {
            ".deagle;.revolver",
            ".elite", ".p250",
            ".tec9;.fiveseven",
            ".glock;.hkp2000;.usp_silencer",
        }
        local weapons_list = {
            ".ssg08", ".awp", ".scar20;.g3sg1",
            ".ak47;.m4a1;.m4a1_silencer",
            ".nova", ".xm1014", ".mag7",
            ".mac10;.mp9",
            ".mp7", ".ump45", ".p90", ".bizon"
        }
        local other_list = {
            ".vesthelm",
            ".hegrenade", ".molotov;.incgrenade", ".smokegrenade", ".flashbang",
            ".taser", ".defuser"
        }
        local cmd_table = {}
        local weapon = primary:val_index()
        local pistol = secondary:val_index()
        if weapon ~= 1 then cmd_table[#cmd_table + 1] = weapons_list[weapon - 1] end
        if pistol ~= 1 then cmd_table[#cmd_table + 1] = pistols_list[pistol - 1] end
        local others  = ""
        for i = 1, #other_list do
            others = others .. (other:val_index(i) and (other_list[i] .. ";") or "")
        end
        if others ~= "" then cmd_table[#cmd_table+1] = others end
        local cmd = table.concat(cmd_table, ";"):gsub("%.", "buy ")
        engine.execute_client_cmd(cmd)
    end
    cbs.event("round_prestart", buybot_fn)
    cbs.event("round_start", buybot_fn)
end
gui.checkbox("Console filter"):update(function (el)
    local value = el:value()
    se.get_convar("con_filter_enable"):set_int(value and 1 or 0)
    se.get_convar("con_filter_text"):set_string(value and "magnoliamagnoliamagnolia" or "")
end)
gui.column()
gui.checkbox("Autostrafer+"):create_move(function ()
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    if ui.is_visible() then
        return ui.get_check_box("misc_autostrafer"):set_value(true)
    end
    local velocity = lp.m_vecVelocity
    ui.get_check_box("misc_autostrafer"):set_value(#v2(velocity.x, velocity.y) > 10)
end)
end)
__bundle_register("features.animbreaker", function(require, _LOADED, __bundle_register, __bundle_modules)
-- local interface, class = require("libs.interfaces")()
local cbs = require("libs.callbacks")
local hooks = require("libs.hooks")
local ffi = require("libs.protected_ffi")
local errors = require("libs.error_handler")
require("libs.types")
-- local nixware = require("libs.nixware")
-- ffi.cdef[[
--     typedef struct {
--     	vector_t origin;
--     	vector_t angles; 
--         char pad[4];
--     	void* renderable;
--     	const model_t* model;
--     	const void* model_to_world;
--     	const void* lightning_offset;
--     	const vector_t* lightning_origin;
--     	int flags;
--     	int entity_index;
--     	int skin;
--     	int body;
--     	int hitboxset;
--     	WORD instance;
--     } ModelRenderInfo_t;
-- ]]

local elements = {
    ---@type gui_dropdown_t
    walk_legs = nil,
    ---@type gui_dropdown_t
    air_legs = nil,
}

local function animbreaker()
    local lp = entitylist.get_local_player()
    local in_air = not lp:is_on_ground()
    if not elements.walk_legs or not elements.air_legs then
        return
    end
    local walk_legs, air_legs = elements.walk_legs:value(), elements.air_legs:value()
    local MOVEMENT_MOVE = lp:get_animlayer(6)
    if walk_legs == "Slide" then
        lp:set_poseparam(0, -180, -179)
    end
    if #lp.m_vecVelocity > 3 and (in_air and (air_legs == "Walking") or (not in_air and walk_legs == "Walking")) then
        MOVEMENT_MOVE.weight = 1
        lp:set_poseparam(7, -180, -179) --BODY_YAW
    end
    if air_legs == "Static" then
        lp:set_poseparam(6, 0.9, 1)
    end

    -- lp:get_animlayer(12).weight = 2.5
end

local ready_to_unhook = true
-- local offset = client.find_pattern("client.dll", "? ? ? ? ? F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B")

-- local CCSPlayer = hooks.vmt.new(ffi.cast("int*",
-- (client.find_pattern("client.dll", "55 8B EC 83 E4 F8 83 EC 18 56 57 8B F9 89 7C 24 0C") or error("wrong ccsplayer sig")) + 0x47))
-- local update_client_side_animations_orig
-- local update_client_side_animations_hk = function(this)
--     ready_to_unhook = false
--     local lp = entitylist.get_local_player()
--     local is_lp = false
--     errors.handle(function()
--         if not lp then return end
--         is_lp = this == ffi.cast("void*", lp[0])
--         if not is_lp then return end
--         print("hello")
--         lp:set_poseparam(0, -180, -179)
--         lp:set_poseparam(6, 0.9, 1)
--     end, "update_client_side_animations.pre_hook")
--     errors.handle(function()
--         if not is_lp then return end
--         lp:restore_poseparam()
--     end, "update_client_side_animations.post_hook")
--     ready_to_unhook = true
--     return update_client_side_animations_orig(this)
-- end
-- update_client_side_animations_orig = CCSPlayer:hookMethod("void(__thiscall*)(void*)", update_client_side_animations_hk, 224)


-- local IVEngineModel = hooks.vmt.new(se.create_interface("engine.dll", "VEngineModel016"))
-- local draw_model_execute_orig
-- ---@param info { renderable: any, model: any, origin: any, angles: any, flags: number, entity_index: number, skin: number, body: number, hitboxset: number, instance: number }
-- local draw_model_execute_hk = function(this, ctx, state, info, custom_bone_to_world)
--     local lp = entitylist.get_local_player()
--     errors.handle(function()
--         if not lp then return end
--         if lp:get_index() ~= info.entity_index then return end
--         lp:set_poseparam(0, -180, -179)
--         lp:set_poseparam(6, 0.9, 1)
--     end, "draw_model_execute_pre_hk")
--     ready_to_unhook = false
--     local ret_value = draw_model_execute_orig(this, ctx, state, info, custom_bone_to_world)
--     errors.handle(function()
--         if not lp then return end
--         lp:restore_poseparam()
--     end, "draw_model_execute_pre_hk")
--     ready_to_unhook = true
--     return ret_value
-- end
-- draw_model_execute_orig = IVEngineModel:hookMethod("void(__thiscall*)(void*, void*, void*, const ModelRenderInfo_t&, void*)", draw_model_execute_hk, 21)

-- local setup_bones_addr = client.find_pattern("client.dll", "? ? ? ? ? F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B") --SetupBones 55 8B EC 83 E4 F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B
-- if setup_bones_addr == 0 then return end
-- local setup_bones_jmp_addr = hooks.jmp2.rel_jmp(setup_bones_addr)
-- if not setup_bones_addr then return end

local setup_bones_addr = client.find_pattern("client.dll", "55 8B EC 57 8B F9 8B ? ? ? ? ? 8B 01 8B ? ? ? ? ? FF")
if setup_bones_addr == 0 then error("couldn't find setup_bones") end

local setup_bones_hk = function(original, ccsplayer, edx, bone_to_world_out, max_bones, bone_mask, current_time)
    ready_to_unhook = false
    local lp = entitylist.get_local_player()
    local is_lp = false
    errors.handle(function ()
        if not lp or not lp:is_alive() then return end
        is_lp = ccsplayer == ffi.cast("void*", lp[0])
        if not is_lp then return end
        animbreaker()
    end, "setup_bones.pre_hook")
    local result = original(ccsplayer, edx, bone_to_world_out, max_bones, bone_mask, current_time)
    errors.handle(function ()
        if not is_lp then return end
        lp:restore_poseparam()
    end, "setup_bones.post_hook")
    ready_to_unhook = true
    return result
end

local setup_bones_orig = hooks.jmp2.new("bool(__fastcall*)(void*, void*, void*, int, int, float)", setup_bones_hk, setup_bones_addr)

-- local hook_setup = false
-- local IClientRenderable_vmt
-- cbs.paint(function()
--     if IClientRenderable_vmt or hook_setup then return end
--     local lp = entitylist.get_local_player()
--     if not lp or not lp:is_alive() then return end
--     local client_renderable = lp:get_class():GetClientRenderable()
--     if not client_renderable then return end
--     -- local vmt = ffi.cast("void***", client_renderable)
--     -- if not vmt then return end
--     -- local setup_bones_native = vmt[0][13]
--     -- print(tostring(setup_bones_native))
--     -- if not nixware.is_in_range(setup_bones_native) then return end
--     -- iengine.log("setup bones initialized")
--     hook_setup = true
--     IClientRenderable_vmt = hooks.vmt.new(client_renderable)
--     setup_bones_orig = IClientRenderable_vmt:hookMethod("bool(__thiscall*)(int, void*, int, int, float)", setup_bones_hk, 13)
-- end)

-- cbs.frame_stage(function()
--     local lp = entitylist.get_local_player()
--     if not lp or not lp:is_alive() then return end
--     
--     
--     
--     
--     
-- end)

cbs.unload(function()
    local lp = entitylist.get_local_player()
    if lp then
        lp:restore_poseparam()
    end
    while not ready_to_unhook do
        print("waiting till unhook is possible")
    end

    setup_bones_orig:unhook()
    -- CCSPlayer:unHookAll()
    -- IVEngineModel:unHookAll()
end)

return elements
end)
__bundle_register("libs.hooks", function(require, _LOADED, __bundle_register, __bundle_modules)
local win32 = require("libs.win32")
local vmt_hook = {
    __index = {
        ---@generic T
        ---@param cast string
        ---@param func T
        ---@param method number
        ---@return T
        hookMethod = function(h, cast, func, method)
            h.hook[method] = func
            jit.off(h.hook[method], true)
            h.orig[method] = h.vt[method]
            win32.VirtualProtect(h.vt + method, 4, 0x4, h.prot)
            h.vt[method] = ffi.cast('intptr_t', ffi.cast(cast, h.hook[method]))
            win32.VirtualProtect(h.vt + method, 4, h.prot[0], h.prot)
            return ffi.cast(cast, h.orig[method])
        end,
        unHookMethod = function(h, method)
            if not h.orig[method] then return end
            h.hook[method] = function() end
            win32.VirtualProtect(h.vt + method, 4, 0x4, h.prot)
            local alloc_addr = win32.VirtualAlloc(nil, 5, 0x1000, 0x40, false)
            if not alloc_addr then return end
            local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)
            trampoline_bytes[0] = 0xE9
            ffi.cast('int32_t*', trampoline_bytes + 1)[0] = h.orig[method] - tonumber(alloc_addr) - 5
            win32.copy(alloc_addr, trampoline_bytes, 5)
            h.vt[method] = ffi.cast('intptr_t', alloc_addr)
            win32.VirtualProtect(h.vt + method, 4, h.prot[0], h.prot)
            h.orig[method] = nil
        end,
        unHookAll = function(h)
            for method, _ in pairs(h.orig) do h:unHookMethod(method) end
        end
    },
}
vmt_hook.new = function(vt)
    if not vt or vt == 0 or vt == nil then
        error('vmt_hook.new: invalid vtable pointer')
    end
    return setmetatable({
        orig = {},
        vt = ffi.cast('intptr_t**', vt)[0],
        prot = ffi.new('unsigned long[1]'),
        hook = {}
    }, vmt_hook)
end

local jmp_hook = {
    hooks = {},
    ---@class jmp_hook_t
    -- __index = {
    --     set_status = function(s, bool)
    --         s.status = bool
    --         VirtualProtect(s.address, s.size, 0x40, s.old_protect)
    --         copy(s.address, bool and s.hook_bytes or s.org_bytes, s.size)
    --         VirtualProtect(s.address, s.size, s.old_protect[0], s.old_protect)
    --     end,
    --     stop = function(s) s:set_status(false) end,
    --     start = function(s) s:set_status(true) end,
    --     __call = function(s, ...)
    --         if s.trampoline then
    --             return s.call(...)
    --         end
    --         s:stop()
    --         local res = s.call(...)
    --         s:start()
    --         return res
    --     end
    -- }
}

---@param cast string
---@param callback fun(...): any
---@param address ffi.ctype*|number|nil
---@param size? number
function jmp_hook.new(cast, callback, address, size)
    jit.off(callback, true)
    size = size or 5
    local new_hook = {}
    local detour_addr = tonumber(ffi.cast('intptr_t', ffi.cast('void*', ffi.cast(cast, callback))))
    local void_addr = ffi.cast('void*', address)
    local old_prot = ffi.new('unsigned long[1]')
    local org_bytes = ffi.new('uint8_t[?]', size)
    ffi.copy(org_bytes, void_addr, size)
    local hook_bytes = ffi.new('uint8_t[?]', size, 0x90)
    hook_bytes[0] = 0xE9
    ffi.cast('uint32_t*', hook_bytes + 1)[0] = detour_addr - tonumber(ffi.cast("intptr_t", address)) - 5
    new_hook.call = ffi.cast(cast, address)
    new_hook.status = false
    local function set_status(bool)
        new_hook.status = bool
        win32.VirtualProtect(void_addr, size, 0x40, old_prot)
        win32.copy(void_addr, bool and hook_bytes or org_bytes, size)
        win32.VirtualProtect(void_addr, size, old_prot[0], old_prot)
    end
    new_hook.stop = function() set_status(false) end
    new_hook.start = function() set_status(true) end
    new_hook.start()
    table.insert(jmp_hook.hooks, new_hook)
    return setmetatable(new_hook, {
        __call = function(self, ...)
            self.stop()
            local res = self.call(...)
            self.start()
            return res
        end
    })
end

-- ---@param cast string
-- ---@param callback fun(orig: fun(...): any): fun(...)
-- ---@param address ffi.ctype*|number|nil
-- jmp_hook.new_new = function(cast, callback, address)
--     if address == nil then return end
--     -- local hook_bytes = {0x04, 0xF0, 0x1F, 0xE5, 0xDE, 0xAD, 0xBE, 0xEF}
--     local hook_bytes = {0xE9}
--     local s = setmetatable({
--         old_protect = ffi.new('unsigned long[1]'),
--         address = address,
--         size = #hook_bytes + 4,
--     }, jmp_hook)
--     local original_fn = ffi.cast(cast, address)
--     local call = function(...)
--         s:stop()
--         local res = original_fn(...)
--         s:start()
--         return res
--     end
--     local hook_fn = ffi.cast(cast, callback(call))
--     local offset = ffi.cast("intptr_t", hook_fn) - ffi.cast("intptr_t", address) - #hook_bytes - 4
--     s.hook_bytes = ffi.new('uint8_t[?]', s.size, hook_bytes)
--     ffi.cast("uint32_t*", s.hook_bytes + #hook_bytes)[0] = ffi.cast('intptr_t', offset)

--     s.org_bytes = ffi.new('uint8_t[?]', s.size)
--     copy(s.org_bytes, address, s.size)

--     s:set_status(true)
--     return s
-- end

local jmp_hook_2 = {
    list = {},
    rel_jmp = function(address)
        local addr = ffi.cast("uintptr_t", address)
        local jmp_addr = ffi.cast("uintptr_t", addr)
        local jmp_disp = ffi.cast("int32_t*", jmp_addr + 0x1)[0]
        return ffi.cast("uintptr_t", jmp_addr + 0x5 + jmp_disp)
    end
}
local hook = ffi.cast("int(__cdecl*)(void*, void*, void*, int)", client.find_pattern("gameoverlayrenderer.dll", "55 8B EC 51 8B 45 10 C7"))
local unhook = ffi.cast("void(__cdecl*)(void*, bool)", jmp_hook_2.rel_jmp(client.find_pattern("gameoverlayrenderer.dll", "E8 ? ? ? ? 83 C4 08 FF 15 ? ? ? ?")))
---@param cast string
---@param callback fun(orig: function, ...): function
---@param address any
jmp_hook_2.new = function(cast, callback, address)
    local addr_pointer = ffi.cast("void*", address)
    local typedef = ffi.typeof(cast)

    local callback_fn = ffi.cast(typedef, callback)
    local original_pointer = ffi.typeof("$[1]", callback_fn)()

    local function actual_callback(...)
        local original = original_pointer[0]

        local call, result = pcall(callback, original, ...)
        if not call then
            return original(...)
        end

        return result
    end

    local callback_type = ffi.cast(typedef, actual_callback)

    local result = hook(addr_pointer, callback_type, original_pointer, 0)
    if result == 1 then

    elseif result == 0 then
        if type(address) ~= "number" then
            return print(("[EPIC FAIL] Failed to hook function! Unknown calling conv.!"))
        end

        print(("[EPIC FAIL] Failed to hook function! Addr: 0x%x!!!"):format(address or 0))
    end

    return {
        unhook = function()
            unhook(addr_pointer, true)
        end
    }
end

return {
    vmt = vmt_hook,
    jmp = jmp_hook,
    jmp2 = jmp_hook_2
}

end)
__bundle_register("features.bullet_tracers", function(require, _LOADED, __bundle_register, __bundle_modules)
local v2, v3 = require("libs.vectors")()
local hooks = require("libs.hooks")
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local beams = {
    ---@type fun(from: vec3_t, to: vec3_t): boolean
    callback = nil,
}
require("libs.types")
ffi.cdef[[
    struct beam_info_t {
        int         type;
        void*       start_ent;
        int         start_attachment;
        void*       end_ent;
        int         end_attachment;
        vector_t    start;
        vector_t    to;
        int         model_index;
        PCSTR       model_name;
        int         halo_index;
        PCSTR       halo_name;
        float       haldo_scale;
        float       life;
        float       width;
        float       end_width;
        float       fade_length;
        float       amplitude;
        float       brightness;
        float       speed;
        int         start_frame;
        float       frame_rate;
        float       red;
        float       green;
        float       blue;
        bool        renderable;
        int         num_segments;
        int         flags;
        vector_t    center;
        float       start_radius;
        float       end_radius;
    };
]]
local beams_vmt = hooks.vmt.new(ffi.cast("void****", ffi.cast("char*", client.find_pattern("client.dll", "B9 ? ? ? ? A1 ? ? ? ? FF 10 A1 ? ? ? ? B9")) + 1)[0])
local create_beam_orig
---@param beam_info { type: number, start_ent: any, start_attachment: number, end_ent: any, end_attachment: number, start: vec3_t, to: vec3_t, model_index: number, model_name: PCSTR, halo_index: number, halo_name: PCSTR, haldo_scale: number, life: number, width: number, end_width: number, fade_length: number, amplitude: number, brightness: number, speed: number, start_frame: number, frame_rate: number, red: number, green: number, blue: number, renderable: boolean, num_segments: number, flags: number, center: vec3_t, start_radius: number, end_radius: number }
create_beam_orig = beams_vmt:hookMethod("void*(__thiscall*)(void*, struct beam_info_t&)", function (this, beam_info)
    errors.handler(function()
        if beam_info.life == 2.5 then
            local from = v3(beam_info.start.x, beam_info.start.y, beam_info.start.z + 3)
            local to = v3(beam_info.to.x, beam_info.to.y, beam_info.to.z)
            if beams.callback(from, to) then
                beam_info.renderable = false
            end
        end
    end)()
    return create_beam_orig(this, beam_info)
end, 12)
cbs.unload(function ()
    beams_vmt:unHookAll()
end)
return beams
end)
__bundle_register("features.antiaim", function(require, _LOADED, __bundle_register, __bundle_modules)
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local nixware = require("libs.nixware")
local ffi = require("libs.protected_ffi")
local hooks = require("libs.hooks")
local create_move_fn = client.find_pattern("client.dll", "55 8B EC 83 E4 F8 81 EC ? ? ? ? 8B 45 08 89 0C 24")
ffi.cdef[[
    struct UserCmd {
        void*       vmt;
        int         commandNumber;
        int         tickCount;
        vector_t    viewangles;
        vector_t    aimdirection;
        float       forwardmove;
        float       sidemove;
        float       upmove;
        int         buttons;
        char        impulse;
        int         weaponselect;
        int         weaponsubtype;
        int         randomSeed;
        short       mousedx;
        short       mousedy;
        bool        hasbeenpredicted;
        vector_t    viewanglesBackup;
        int         buttonsBackup;
    };
]]
local hook
require("libs.advanced math")

gui.subtab("Builder")
local is_enabled = gui.checkbox("Enable")
---@alias anti_aim_condition_t "Shared"|"Stand"|"Move"|"Air"|"Air duck"|"Duck"|"Walk"|"Use"
local conditions = {"Shared", "Stand", "Move", "Air", "Air duck", "Duck", "Walk", "Use"}
local current_condition = gui.dropdown("Condition", conditions):master(is_enabled)
gui.column()
---@type table<anti_aim_condition_t, { enabled?: gui_checkbox_t, yaw_modifiers: gui_dropdown_t, yaw_offset: gui_slider_t, max_dormant_time: gui_slider_t, yaw_inverted: gui_slider_t, jitter_type: gui_dropdown_t, jitter_range: gui_slider_t, jitter_delay: gui_slider_t, spin_speed: gui_slider_t, spin_range: gui_slider_t, pitch: gui_dropdown_t, pitch_custom: gui_slider_t, desync_delay: gui_slider_t, desync_type: gui_dropdown_t, desync_length: gui_slider_t, inverted_desync_length: gui_slider_t}>
local settings = {}
for i = 1, #conditions do
    local condition = conditions[i]
    local setting = {}
    local get_name = function(name)
        return name .. " | " .. condition
    end
    local main_master_fn = function()
        return is_enabled:value() and condition == current_condition:value()
    end
    if condition ~= "Shared" then
        setting.enabled = gui.checkbox("Enable " .. condition):master(main_master_fn)
    end
    local master_elements = {}
    master_elements.yaw = gui.label(get_name("Yaw")):options(function ()
        setting.yaw_modifiers = gui.dropdown("Modifiers", {"At targets", "Inverted offset", "Jitter", "Spin"}, {})
        setting.yaw_offset = gui.slider("Yaw offset", -180, 180, false, 0)
        setting.yaw_inverted = gui.slider("Inverted yaw offset", -180, 180, false, 0):master(function()
            return setting.yaw_modifiers:value("Inverted offset")
        end)
        setting.max_dormant_time = gui.slider("Max time in dormant", 0, 10, true, 3):master(function()
            return setting.yaw_modifiers:value("At targets")
        end)
        gui.label("Jitter"):options(function()
            setting.jitter_type = gui.dropdown("Jitter type", {"Center", "Offset", "Random"})
            setting.jitter_range = gui.slider("Jitter range", -90, 90, false, 0)
            setting.jitter_delay = gui.slider("Jitter delay", 0, 10)
        end):master(function()
            return setting.yaw_modifiers:value("Jitter")
        end)
        gui.label("Spin"):options(function ()
            setting.spin_speed = gui.slider("Spin speed", 1, 10)
            setting.spin_range = gui.slider("Spin range", 0, 360)
        end):master(function()
            return setting.yaw_modifiers:value("Spin")
        end)
    end)
    master_elements.desync = gui.label(get_name("Desync")):options(function ()
        setting.desync_type = gui.dropdown("Desync type", {"Static", "Jitter", "Random"})
        setting.desync_length = gui.slider("Desync length", -60, 60, false, 60)
        setting.inverted_desync_length = gui.slider("Inverted desync length", -60, 60)
        setting.desync_delay = gui.slider("Desync switch delay", 0, 10):master(function()
            return setting.desync_type:value("Jitter")
        end)
    end)
    master_elements.pitch = gui.label(get_name("Pitch")):options(function ()
        setting.pitch = gui.dropdown("Pitch", {"Off", "Down", "Up", "Zero", "Random", "Custom"}, "Down")
        setting.pitch_custom = gui.slider("Custom pitch", -89, 89, false, 0):master(function()
            return setting.pitch:value("Custom")
        end)
    end)
    master_elements.defensive_aa = gui.label(get_name("Defensive AA")):options(function ()

    end)
    local master_fn = function()
        return main_master_fn() and (setting.enabled and setting.enabled:value() or not setting.enabled)
    end
    for k, v in pairs(master_elements) do
        v:master(master_fn)
    end
    settings[condition] = setting
end
local anti_aim = {
    last_target_index = -1,
    last_best_angle = nil,
    target_player_index = -1,
    exploit_uncharged = false,
    next_jitter_update = 0,
    jitter_inverted = false,
    next_desync_update = 0,
    desync_inverted = false,
}
---@param max_dormant_time number
---@param at_targets_enabled boolean
local get_best_angle = function(max_dormant_time, at_targets_enabled)
    if clientstate.get_choked_commands() > 0 then
        anti_aim.target_player_index = anti_aim.last_target_index
        return anti_aim.last_best_angle
    end
    local best_player, best_player_pos = nil, nil
    local best_angle = 0
    local lp = entitylist.get_local_player()
    local viewangles = engine.get_view_angles()
    if at_targets_enabled then
        local lowest_fov = 2147483647
        local interval_per_tick = globalvars.get_interval_per_tick()
        local origin = lp.m_vecOrigin + lp.m_vecVelocity * interval_per_tick
        local viewangles_vec = viewangles:to_vec()
        local max_dormant_ticks = max_dormant_time / interval_per_tick
        for _, enemy in pairs(entitylist.get_players(0)) do
            errors.handle(function ()
                if enemy:get_ticks_in_dormant() > max_dormant_ticks then
                    return
                end
                local pos = enemy.m_vecOrigin + enemy.m_vecVelocity * interval_per_tick
                local fov = #(origin:angle_to(pos):to_vec() - viewangles_vec)
                if fov < lowest_fov then
                    lowest_fov = fov
                    best_player = enemy
                    best_player_pos = pos
                end
            end, "anti_aim.get_target_angle.for_loop")
        end
        if best_player_pos then
            local difference = origin:angle_to(best_player_pos)
            if difference then
                best_angle = difference.yaw
            end
        end
    end
    anti_aim.last_target_index = best_player and best_player:get_index() or -1
    anti_aim.target_player_index = anti_aim.last_target_index
    if not best_player or not best_player_pos then
        anti_aim.target_player_index = nil
        best_angle = viewangles.yaw
    end
    anti_aim.last_best_angle = best_angle
    return best_angle
end
local right_yaw_offset_address = nixware.find_pattern("F3 0F 10 47 10 F3 0F 5C C1 F3 0F 11 47 10 E9 ? ? ? ? B8")
if right_yaw_offset_address == 0 then
    error("failed to find internal pattern")
end
local patch_bytes =     { 0xB8, 0x00, 0x00, 0xB4, 0xC2, 0x66, 0x0F, 0x6E, 0xC0 }
local original_bytes =  { 0xF3, 0x0F, 0x10, 0x47, 0x10, 0xF3, 0x0F, 0x5C, 0xC1 }
local anti_aim_base_yaw = ui.get_combo_box("antihit_antiaim_yaw")
nixware.write_memory_bytes(right_yaw_offset_address, patch_bytes)
cbs.unload(function()
    nixware.write_memory_bytes(right_yaw_offset_address, original_bytes)
    anti_aim_base_yaw:set_value(1)
end)
local internal_yaw_offset = ffi.cast("float*", right_yaw_offset_address + 1)
local set_yaw = function(yaw)
    anti_aim_base_yaw:set_value(3)
    nixware.write_memory_callback(right_yaw_offset_address + 1, 4, function ()
        ffi.copy(internal_yaw_offset, ffi.new("float[1]", math.normalize_yaw(yaw)), 4)
    end)
end
local accurate_walk_enabled = ui.get_check_box("antihit_accurate_walk")
local accurate_walk = ui.get_key_bind("antihit_accurate_walk_bind")
local anti_aim_enabled = ui.get_check_box("antihit_antiaim_enable")
local at_targets_enabled = ui.get_check_box("antihit_antiaim_at_targets")
local yaw_jitter = ui.get_slider_int("antihit_antiaim_yaw_jitter")
local anti_aim_pitch = ui.get_combo_box("antihit_antiaim_pitch")
local desync_length = ui.get_slider_int("antihit_antiaim_desync_length")
local menu_desync_type = ui.get_combo_box("antihit_antiaim_desync_type")
local desync_inverter = ui.get_key_bind("antihit_antiaim_flip_bind")
local pitch_settings = {
    Off = 0,
    Down = 1,
    Zero = 2,
    Up = 3,
    Custom = 0,
    Random = 0,
}
local create_move_hk = function(original, this, cmd)
    errors.handle(function()
        if not is_enabled:value() then return end
        set_yaw(180)
        local lp = entitylist.get_local_player()
        if not lp or not lp:is_alive() then return end
        local condition = lp:get_condition() ---@type anti_aim_condition_t
        local is_walking = accurate_walk_enabled:get_value() and accurate_walk:is_active()
        if condition == "Move" and is_walking then
            condition = "Walk"
        end
        if bit.band(cmd.buttons, 32) ~= 0 then
            condition = "Use"
        end
        local setting = settings[condition]
        if not setting then return end
        if setting.enabled and not setting.enabled:value() then
            condition = "Shared"
            setting = settings[condition]
        end

        cmd.buttons = bit.band(cmd.buttons, bit.bnot(32))

        anti_aim_enabled:set_value(true)
        yaw_jitter:set_value(0)
        at_targets_enabled:set_value(false)

        local at_targets_setting = setting.yaw_modifiers:value("At targets")
        local yaw = get_best_angle(setting.max_dormant_time:value(), at_targets_setting) + setting.yaw_offset:value() + 180

        local pitch_setting = setting.pitch:value()
        local pitch = pitch_settings[pitch_setting]
        if pitch then
            anti_aim_pitch:set_value(pitch)
        end
        if pitch_setting == "Custom" then
            anti_aim_pitch:set_value(0)
            pitch = setting.pitch_custom:value()
            cmd.viewangles.pitch = pitch
        end

        local jitter_type, jitter_range, jitter_delay = setting.jitter_type:value(), setting.jitter_range:value(), setting.jitter_delay:value()
        local choked = clientstate.get_choked_commands()
        local jitter_angle = jitter_range
        local desync_type = setting.desync_type:value()
        if choked ~= 0 then
            if anti_aim.next_jitter_update <= 0 then
                anti_aim.next_jitter_update = jitter_delay
                anti_aim.jitter_inverted = not anti_aim.jitter_inverted
            else
                anti_aim.next_jitter_update = anti_aim.next_jitter_update - 1
            end
            if anti_aim.jitter_inverted then
                jitter_angle = -jitter_angle
            end

            if desync_type == "Jitter" then
                if anti_aim.next_desync_update <= 0 then
                    anti_aim.next_desync_update = setting.desync_delay:value()
                    anti_aim.desync_inverted = not anti_aim.desync_inverted
                else
                    anti_aim.next_desync_update = anti_aim.next_desync_update - 1
                end
            else
                anti_aim.desync_inverted = false
            end
            local current_desync = anti_aim.desync_inverted and setting.inverted_desync_length:value() or setting.desync_length:value()
            desync_length:set_value(math.abs(current_desync))
            menu_desync_type:set_value(0)
            desync_inverter:set_type(current_desync > 0 and 1 or 0)
            desync_inverter:set_key(0)
        end

        if jitter_type == "Center" then
            yaw = yaw + jitter_angle / 2
        end

        local is_charged = ragebot.is_charged()
        if is_charged then
            anti_aim.exploit_uncharged = false
        elseif not anti_aim.exploit_uncharged then
            anti_aim.exploit_uncharged = true
            at_targets_enabled:set_value(setting.yaw_modifiers:value("At targets"))
        end

        set_yaw(yaw)
    end, "anti_aim.create_move_hk")
    return original(this, cmd)
end
hook = hooks.jmp2.new("int(__thiscall*)(void* this, struct UserCmd* a2)", create_move_hk, create_move_fn)
client.register_callback("unload", function()
    hook:unhook()
end)
end)
__bundle_register("libs.nixware", function(require, _LOADED, __bundle_register, __bundle_modules)
local ffi = require("libs.protected_ffi")
require("libs.types")
local errors = require("libs.error_handler")
ffi.cdef[[
    typedef struct {
        void*   BaseAddress;
        void*   AllocationBase;
        DWORD   AllocationProtect;
        WORD    PartitionId;
        SIZE_T  RegionSize;
        DWORD   State;
        DWORD   Protect;
        DWORD   Type;
    } MEMORY_BASIC_INFORMATION;
    size_t VirtualQueryEx(void*, const void*, MEMORY_BASIC_INFORMATION*, size_t);
    void* GetCurrentProcess();
    BOOL ReadProcessMemory(void*, const void*, void*, SIZE_T, SIZE_T*);
    BOOL WriteProcessMemory(void*, void*, const void*, SIZE_T, SIZE_T*);
    BOOL VirtualProtectEx(void*, void*, SIZE_T, DWORD, DWORD*);
]]

local setup_bones = client.find_pattern("client.dll", "? ? ? ? ? F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B")
if setup_bones == 0 then return end
local hook_func = ffi.cast("uintptr_t*", setup_bones + 1)
if not hook_func then return end
local jmp_address = hook_func[0] + setup_bones + 5

local module_start = 0
local module_end = 0


do
    local mbi = ffi.new("MEMORY_BASIC_INFORMATION[1]")
    local size = ffi.sizeof("MEMORY_BASIC_INFORMATION")
    local proc = ffi.C.GetCurrentProcess()
    ffi.C.VirtualQueryEx(proc, ffi.cast("void*", jmp_address), mbi, size)

    module_start = tonumber(ffi.cast("uintptr_t", mbi[0].AllocationBase))

    local old_allocation_base = mbi[0].AllocationBase
    local last_address = mbi[0].AllocationBase

    for i = 1, 999 do
        ffi.C.VirtualQueryEx(proc, ffi.cast("void*", last_address), mbi, size)
        last_address = ffi.cast("uintptr_t", mbi[0].BaseAddress) + 1024 * 1024
        if mbi[0].AllocationBase ~= nil and mbi[0].AllocationBase ~= old_allocation_base then
            module_end = tonumber(ffi.cast("uintptr_t", mbi[0].AllocationBase))
            break
        end
    end
end
local split = function (inputstr, sep)
    if sep == nil then
        sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str) end
    return t
end
local find_pattern_in_region = function(from, to, pattern)
    local ptr = ffi.cast("void*", from)
    local search_size = to - from
    local buffer = ffi.new("BYTE[?]", search_size)
    if ffi.C.ReadProcessMemory(ffi.C.GetCurrentProcess(), ptr, buffer, search_size, nil) == 0 then
        return 0
    end
    local bytes = split(pattern, " ")
    for i = 1, #bytes do
        if bytes[i] == "?" or bytes[i] == "??" then
            bytes[i] = nil
        else
            bytes[i] = tonumber(bytes[i], 16)
        end
    end
    local matched = 0
    for i = 0, search_size - 1 do
        if buffer[i] == bytes[matched + 1] or bytes[matched + 1] == nil then
            matched = matched + 1
            if matched == #bytes then
                return from + i - #bytes + 1
            end
        else
            matched = 0
        end
    end
    return 0
end
local nixware_t = {
    is_in_range = function(addr)
        local address = tonumber(ffi.cast("uintptr_t", addr))
        return address >= module_start and address <= module_end
    end,
    find_pattern = function(pattern)
        local mbi = ffi.new("MEMORY_BASIC_INFORMATION[1]")
        local size = ffi.sizeof("MEMORY_BASIC_INFORMATION")
        local proc = ffi.C.GetCurrentProcess()
        ffi.C.VirtualQueryEx(proc, ffi.cast("void*", module_start), mbi, size)
        local base_address, region_size
        for i = 1, 99999 do
            base_address = tonumber(ffi.cast("uintptr_t", mbi[0].BaseAddress))
            region_size = tonumber(ffi.cast("uintptr_t", mbi[0].RegionSize))
            local result = find_pattern_in_region(base_address, base_address + region_size, pattern)
            if result ~= 0 then
                return result
            end
            if base_address + region_size >= module_end then return end
            ffi.C.VirtualQueryEx(proc, ffi.cast("void*", base_address + region_size), mbi, size)
        end
    end,
    ---@param address any
    ---@param callback function
    write_memory_callback = function(address, size, callback)
        local proc = ffi.C.GetCurrentProcess()
        local old_protect = ffi.new("DWORD[1]")
        ffi.C.VirtualProtectEx(proc, ffi.cast("void*", address), size, 0x40, old_protect)
        callback()
        ffi.C.VirtualProtectEx(proc, ffi.cast("void*", address), size, old_protect[0], nil)
    end
}
nixware_t.write_memory_bytes = function(address, bytes)
    local size = #bytes
    local addr = ffi.cast("void*", address)
    nixware_t.write_memory_callback(addr, size, function()
        local bytes_buffer = ffi.new("BYTE[?]", size, bytes)
        ffi.copy(addr, bytes_buffer, size)
    end)
end

return nixware_t


end)
__bundle_register("features.grenade_prediction", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.entity")
require("libs.advanced math")
local iengine = require("includes.engine")
local cbs = require("libs.callbacks")
local v2, v3 = require("libs.vectors")()
local errors = require("libs.error_handler")
local fonts = require("includes.gui.fonts")
local render = require("libs.render")
local col = require("libs.colors")
local colors = require("includes.colors")

local molotov_throw_detonate_time = se.get_convar("molotov_throw_detonate_time")
local sv_gravity = se.get_convar("sv_gravity")
local weapon_molotov_maxdetonateslope = se.get_convar("weapon_molotov_maxdetonateslope")
local samples_per_second = 30

---@class grenade_prediction_t
---@field tickcount number
---@field curtime number
---@field next_think_tick number
---@field collision_group number
---@field detonate_time number
---@field spawn_time number
---@field offset number
---@field bounces number
---@field grenade_type "flashbang"|"he"|"smoke"|"decoy"|"molotov"|nil
---@field last_update_tick number
---@field expire_time number
---@field detonated boolean
---@field collision_entity entity_t
---@field origin vec3_t
---@field velocity vec3_t
---@field entity_index number
---@field owner_index number
---@field broken boolean[]
---@field path { [1]: vec3_t, [2]: number }[]
local grenade_prediction_mt = {}
---@param bounced boolean
grenade_prediction_mt.update_path = function (self, bounced)
    self.path[#self.path + 1] = { self.origin + v3(0, 0, 0), self.curtime }
    self.last_update_tick = self.tickcount
end
---@param bounced boolean
grenade_prediction_mt.detonate = function (self, bounced)
    self.detonated = true
    self:update_path(bounced)
end
---@param time number
grenade_prediction_mt.set_next_think = function (self, time)
    self.next_think_tick = iengine.time_to_ticks(time)
end
grenade_prediction_mt.think = function (self)
    if self.grenade_type == "smoke" and #self.velocity <= 0.1 then
        self:detonate(false)
    elseif self.grenade_type == "decoy" and #self.velocity <= 0.2 then
        self:detonate(false)
    elseif (self.grenade_type == "flashbang"
        or self.grenade_type == "he"
        or self.grenade_type == "molotov")
        and (self.curtime >= (self.detonate_time + self.offset))
    then
        self:detonate(false)
    end

    self:set_next_think(self.curtime + 0.2)
end
---@param entity entity_t
grenade_prediction_mt.is_broken = function (self, entity)
    if not entity then
        return false
    end
    local handle = entity[0]
    if not handle then
        return false
    end
    local broken = self.broken[handle]
    self.broken[handle] = true
    if not broken then
        return false
    end
    return true
end
grenade_prediction_mt.physics_run_think = function (self)
    if self.next_think_tick > self.tickcount then
		return
    end
    self:think()
end
---@return vec3_t
grenade_prediction_mt.physics_add_gravity_move = function (self)
    local interval_per_tick = globalvars.get_interval_per_tick()
    local gravity = sv_gravity:get_float() * 0.4
    local move = self.velocity * interval_per_tick


	local z = self.velocity.z - (gravity * interval_per_tick)

	move.z = ((self.velocity.z + z) / 2) * interval_per_tick
	self.velocity.z = z

    return move
end
---@param self grenade_prediction_t
---@param start vec3_t
---@param dest vec3_t
---@param mins vec3_t
---@param maxs vec3_t
---@param mask number
---@return trace_t
local trace_hull = function(self, start, dest, mins, maxs, mask)
    local ignore_index = entitylist.get_entity_by_index(self.owner_index) and self.owner_index or -1
    return trace.hull(mask, start, dest, mins, maxs, self.collision_group, function (entity_index, contents_mask)
        if entity_index == ignore_index then
            return false
        end
        if entity_index then
            local entity = entitylist.get_entity_by_index(entity_index)
            if entity and entity:is_grenade() then
                return false
            end
        end
        return true
    end)
end
---@param start vec3_t
---@param dest vec3_t
---@param mask number
---@return trace_t
grenade_prediction_mt.trace_line = function(self, start, dest, mask)
    local null_v3 = v3(0, 0, 0)
    return trace_hull(self, start, dest, null_v3, null_v3, mask)
end
---@param start vec3_t
---@param dest vec3_t
---@param mask number
---@return trace_t
grenade_prediction_mt.trace_entity = function(self, start, dest, mask)
    local mins, maxs = v3(-2, -2, -2), v3(2, 2, 2)
    return trace_hull(self, start, dest, mins, maxs, mask)
end

---@param start vec3_t
---@param dest vec3_t
---@param mask number
---@return trace_t
grenade_prediction_mt.physics_trace_entity = function(self, start, dest, mask)
    local trace_info = self:trace_entity(start, dest, mask)

    if trace_info.startsolid and bit.band(trace_info.contents, 0x80000) then --CONTENTS_CURRENT_90
        trace_info = self:trace_entity(start, dest, bit.band(mask, bit.bnot(0x80000))) --~CONTENTS_CURRENT_90
    end

    if trace_info.fraction < 1 or trace_info.allsolid or trace_info.startsolid then
        if trace_info.hit_entity_index ~= 0 then
            local hit_entity = entitylist.get_entity_by_index(trace_info.hit_entity_index)
            if hit_entity and hit_entity:is_player() then
                trace_info = self:trace_line(start, dest, mask)
            end
        end
    end

    return trace_info
end
---@param start vec3_t
---@param delta vec3_t
---@return trace_t
grenade_prediction_mt.physics_check_sweep = function (self, start, delta)
    local mask
    if self.collision_group == 1 then --COLLISION_GROUP_DEBRIS
        mask = 540683 --(MASK_SOLID | CONTENTS_CURRENT_90) & ~CONTENTS_MONSTER
    else
        mask = 1107845259 --(MASK_SOLID | CONTENTS_OPAQUE | CONTENTS_IGNORE_NODRAW_OPAQUE | CONTENTS_CURRENT_90| CONTENTS_HITBOX)
    end
    return self:physics_trace_entity(start, start + delta, mask)
end
-- -@param entity entity_t
---@param normal_z number
grenade_prediction_mt.touch = function (self, normal_z)
    if self.grenade_type == "molotov" then
        if normal_z >= math.cos(math.rad(weapon_molotov_maxdetonateslope:get_float())) then
            self:detonate(true)
        end
    -- -- elseif self.grenade_type == "tagranade" then
    -- --     if not entity:is_player() then
    -- --         self:detonate(true)
    -- --     end
    end
end
-- -@param entity entity_t
---@param normal_z number
grenade_prediction_mt.physics_impact = function (self, normal_z)--entity
    -- self:touch(entity, normal_z)
    self:touch(normal_z)
end
---@param push vec3_t
---@return trace_t
grenade_prediction_mt.physics_push_entity = function(self, push)
    local trace_info = self:physics_check_sweep(self.origin, push)

    if trace_info.startsolid then
        self.collision_group = 3 --COLLISION_GROUP_INTERACTIVE_DEBRIS
        trace_info = self:trace_line(self.origin - push, self.origin + push, 540683) --(MASK_SOLID | CONTENTS_CURRENT_90) & ~CONTENTS_MONSTER
    end

    if trace_info.fraction ~= 0 then
        self.origin = trace_info.endpos
    end
    if trace_info.fraction ~= 1 then
        -- local hit_entity = entitylist.get_entity_by_index(trace_info.hit_entity_index)
        -- if hit_entity then
            -- self:physics_impact(hit_entity, trace_info.normal.z)
        -- end
        self:physics_impact(trace_info.normal.z)
    end

    return trace_info
end
---@param vector vec3_t
---@param normal vec3_t
---@param overbounce number
---@return vec3_t
local clip_velocity = function(vector, normal, overbounce)
    local STOP_EPSILON = 0.1
    local backoff = vector:dot(normal) * overbounce
    local out = v3(0, 0, 0)
    for k, _ in vector:pairs() do
        local change = normal[k] * backoff
        out[k] = vector[k] - change
        if out[k] > -STOP_EPSILON and out[k] < STOP_EPSILON then
            out[k] = 0
        end
    end
    return out
end
---@param trace_info trace_t
grenade_prediction_mt.perform_fly_collision_resolution = function(self, trace_info)
    local surface_elacticity = 1
    if trace_info.hit_entity_index ~= 0 then
        local hit_entity = entitylist.get_entity_by_index(trace_info.hit_entity_index)
        if hit_entity then
            if hit_entity:is_breakable() and not self:is_broken(hit_entity) then
                self.velocity = self.velocity * 0.4
                return
            end
            if hit_entity:is_player() then
                surface_elacticity = 0.3
            end

            --if did not hit world
            if self.collision_entity == hit_entity then
                if hit_entity:is_player() then
                    self.collision_group = 1 --COLLISION_GROUP_DEBRIS
                    return
                end
            end
            self.collision_entity = hit_entity
        end
    end
    local total_elasticity = math.clamp(0.45 * surface_elacticity, 0, 0.9)
    local velocity = clip_velocity(self.velocity, trace_info.normal, 2) * total_elasticity

    local interval_per_tick = globalvars.get_interval_per_tick()
    if trace_info.normal.z > 0.7 then
        local speed_sqr = velocity:length_sqr()
        if speed_sqr > 96000 then
            local l = velocity:normalize():dot(trace_info.normal)
            if l > 0.5 then
                velocity = velocity * (1 - l + 0.5)
            end
        end
        if speed_sqr < 400 then
            self.velocity = v3(0, 0, 0)
        else
            self.velocity = velocity
            self:physics_push_entity(velocity * ((1 - trace_info.fraction) * interval_per_tick))
        end
        --!HACK
    else
        self.velocity = velocity
        self:physics_push_entity(velocity * ((1 - trace_info.fraction) * interval_per_tick))
    end
    if self.bounces > 20 then
        self:detonate(true)
    else
        self.bounces = self.bounces + 1
    end
end
grenade_prediction_mt.physics_simulate = function(self)
    self:physics_run_think()

    if self.detonated then
        return
    end

    local move = self:physics_add_gravity_move()
    local trace_info = self:physics_push_entity(move)

    if self.detonated then
        return
    end

    if trace_info.fraction ~= 1 then
        self:update_path(true)
        self:perform_fly_collision_resolution(trace_info)
    end

    -- self:physics_check_water_transition()
end
grenade_prediction_mt.predict = function(self)
    -- self:throw_grenade(grenade, origin, throw_angle)
    local interval_per_tick = globalvars.get_interval_per_tick()
    local sample_tick = math.round(1 / samples_per_second / interval_per_tick)
    self.last_update_tick = -sample_tick
    self.path = {}
    while self.curtime < 65 do
        if self.curtime > 60 then
            iengine.log("The grenade lives more than a minute. Too much time spent predicting!\n")
            break
        end
        -- if self.tickcount >= self.offset then
            errors.handler(function()
                if self.last_update_tick + sample_tick < self.tickcount then
                    self:update_path(false)
                end

                self:physics_simulate()
            end, "grenade_prediction_t.predict.while_loop")()
        -- end
        if self.detonated then
            break
        end
        self.tickcount = self.tickcount + 1
        self.curtime = self.curtime + interval_per_tick
    end
    self.expire_time = self.spawn_time + iengine.ticks_to_time(self.tickcount)
end


local grenade_prediction_t = {
    ---@param entity entity_t
    ---@param origin vec3_t
    ---@param velocity vec3_t
    ---@param owner entity_t
    ---@param grenade_type "flashbang"|"he"|"smoke"|"decoy"|"molotov"|nil
    ---@param spawn_time number
    ---@param offset number
    ---@return grenade_prediction_t
    new = function (entity, origin, velocity, owner, grenade_type, spawn_time, offset)
        local detonate_time = 1.5
        if grenade_type == "molotov" then
            detonate_time = molotov_throw_detonate_time:get_float()
        end
        local s = setmetatable({
            tickcount = 0,
            curtime = 0,
            next_think_tick = 0,
            collision_group = 13, --COLLISION_GROUP_PROJECTILE
            detonate_time = detonate_time,
            bounces = 0,
            grenade_type = grenade_type,
            last_update_tick = 0,
            detonated = false,
            collision_entity = nil,
            velocity = velocity,
            origin = origin,
            offset = offset,
            owner_index = owner:get_index(),
            entity_index = entity:get_index(),
            spawn_time = spawn_time,
            broken = {},
        }, { __index = grenade_prediction_mt })
        s:predict()
        return s
    end
}

---@type grenade_prediction_t[]
local list = { }

cbs.paint(function()
    local highest_index = entitylist.get_highest_entity_index()
    for i = 1, highest_index do
        errors.handler(function()
            local entity = entitylist.get_entity_by_index(i)
            if entity == nil or entity:is_dormant() then
                return
            end
            local grenade_type = entity:get_grenade_type()

            if grenade_type ~= "he" and grenade_type ~= "molotov" then
                return
            end
            -- if not grenade_type then
            --     return
            -- end

            local handle = entity[0]
            if not handle then return end
            local thrower = entity.m_hThrower
            if not thrower then return end
            if entity.m_nExplodeEffectTickBegin ~= 0 then
                list[handle] = nil
                return
            end
            local spawn_time = entity.m_nGrenadeSpawnTime
            local offset = entity.m_flSimulationTime - globalvars.get_current_time()
            if not list[handle] then
                list[handle] = grenade_prediction_t.new(
                    entity,
                    entity.m_vecOrigin,
                    entity.m_vecVelocity,
                    thrower,
                    grenade_type,
                    spawn_time,
                    offset
                )
            else
                list[handle].offset = offset
                list[handle].spawn_time = spawn_time
            end
        end, "grenade_prediction_t.loop")()
    end

    for _, grenade in pairs(list) do
        errors.handler(function()
            local current_time = globalvars.get_current_time()
            if grenade.expire_time <= current_time then
                list[_] = nil
                return
            end
            if not grenade.path[1] then
                return
            end
            local valid_index = 1
            for i = #grenade.path, 1, -1 do
                if grenade.path[i][2] + grenade.spawn_time < current_time then
                    break
                end
                valid_index = i
            end
            local entity = entitylist.get_entity_by_index(grenade.entity_index)
            if not entity then return end
            local origin = entity:get_abs_origin()
            if not origin then return end
            local previous_w2s = se.world_to_screen(origin)
            for i = valid_index, #grenade.path do
                local w2s = se.world_to_screen(grenade.path[i][1])
                if previous_w2s and w2s then
                    renderer.line(previous_w2s, w2s, colors.magnolia)
                end
                previous_w2s = w2s
            end
            local dist_w2s = se.world_to_screen(grenade.path[#grenade.path][1])
            if not dist_w2s then return end
            dist_w2s = dist_w2s:round()
            local size = v2(28, 24)
            local from = dist_w2s - (size / 2)
            local to = dist_w2s + (size / 2)
            local icon_name = "j"
            if grenade.grenade_type == "molotov" then
                icon_name = "l"
            end
            ---value from 0 to 1 that represents the time left until the grenade explodes
            local time_modifier = 1 - (grenade.expire_time - current_time) / grenade.detonate_time
            if dist_w2s then
                render.box_shadow(from, to, colors.magnolia:alpha(time_modifier * 255), 1.5, 100, 6, 1.3)
                render.rounded_rect(from, to - v2(1, 1), colors.magnolia:alpha(200), 3, false)
                render.rounded_rect(from + v2(1, 1), to - v2(1, 1), colors.container_bg:alpha(240), 3, true)
                render.text(icon_name, fonts.nade_warning, dist_w2s + v2(1, 0), col.white:fade(colors.magnolia, time_modifier), render.flags.CENTER)
                -- render.text("!", fonts.menu, dist_w2s, col.white, render.flags.CENTER)
            end
        end, "grenade_prediction_t.draw")()
    end
end)
end)
__bundle_register("libs.entity", function(require, _LOADED, __bundle_register, __bundle_modules)
local v2, v3 = require("libs.vectors")()
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local interface, class = require("libs.interfaces")()
-- local hooks = require("libs.hooks")
local ffi = require("libs.protected_ffi")

---@class entity_t
---@field m_bEligibleForScreenHighlight number 
---@field m_flMaxFallVelocity number 
---@field m_flLastMadeNoiseTime number 
---@field m_flUseLookAtAngle number 
---@field m_flFadeScale number 
---@field m_fadeMaxDist number 
---@field m_fadeMinDist number 
---@field m_bIsAutoaimTarget number 
---@field m_bSpottedByMask table 
---@field m_bSpottedBy table 
---@field m_bSpotted number 
---@field m_bAlternateSorting number 
---@field m_bAnimatedEveryTick number 
---@field m_bSimulatedEveryTick number 
---@field m_iTextureFrameIndex number 
---@field m_Collision table
---@field m_flPoseParameter table
---@field m_vecSpecifiedSurroundingMaxs vec3_t 
---@field m_vecSpecifiedSurroundingMins vec3_t 
---@field m_triggerBloat number 
---@field m_nSurroundType number 
---@field m_usSolidFlags number 
---@field m_nSolidType number 
---@field m_vecMaxs vec3_t 
---@field m_vecMins vec3_t 
---@field movetype number 
---@field m_iName string 
---@field m_iParentAttachment number 
---@field m_hEffectEntity entity_t 
---@field m_hOwnerEntity entity_t 
---@field m_CollisionGroup number 
---@field m_iPendingTeamNum number 
---@field m_iTeamNum number 
---@field m_clrRender number 
---@field m_nRenderFX number 
---@field m_nRenderMode number 
---@field m_fEffects number 
---@field m_nModelIndex number 
---@field m_angRotation vec3_t 
---@field m_vecOrigin vec3_t 
---@field m_cellZ number 
---@field m_cellY number 
---@field m_cellX number 
---@field m_cellbits number 
---@field m_flSimulationTime number 
---@field m_flAnimTime number 
---@field m_viewtarget vec3_t 
---@field m_blinktoggle number 
---@field m_flexWeight table 
---@field m_nWaterLevel number 
---@field m_flDuckSpeed number 
---@field m_flDuckAmount number 
---@field m_bShouldDrawPlayerWhileUsingViewEntity number 
---@field m_hViewEntity entity_t 
---@field m_vphysicsCollisionState number 
---@field m_hColorCorrectionCtrl entity_t 
---@field m_hPostProcessCtrl entity_t 
---@field m_ladderSurfaceProps number 
---@field m_vecLadderNormal vec3_t 
---@field m_szLastPlaceName string 
---@field m_iCoachingTeam number 
---@field m_hObserverTarget entity_t 
---@field m_iDeathPostEffect number 
---@field m_uCameraManGraphs number 
---@field m_bCameraManScoreBoard number 
---@field m_bCameraManOverview number 
---@field m_bCameraManXRay number 
---@field m_bActiveCameraMan number 
---@field m_iObserverMode number 
---@field m_fFlags number 
---@field m_flMaxspeed number 
---@field m_iBonusChallenge number 
---@field m_iBonusProgress number 
---@field m_iAmmo table 
---@field m_lifeState number 
---@field m_iHealth number 
---@field m_hGroundEntity entity_t 
---@field m_hUseEntity entity_t 
---@field m_hVehicle entity_t
---@field m_afPhysicsFlags number 
---@field m_hZoomOwner entity_t 
---@field m_iDefaultFOV number 
---@field m_flFOVTime number 
---@field m_iFOVStart number 
---@field m_iFOV number 
---@field m_hTonemapController number 
---@field m_flLaggedMovementValue number 
---@field m_fForceTeam number 
---@field m_flNextDecalTime number 
---@field m_flDeathTime number 
---@field m_bConstraintPastRadius number 
---@field m_flConstraintSpeedFactor number 
---@field m_flConstraintWidth number 
---@field m_flConstraintRadius number 
---@field m_vecConstraintCenter vec3_t 
---@field m_hConstraintEntity entity_t 
---@field m_vecBaseVelocity vec3_t 
---@field m_vecVelocity vec3_t 
---@field m_hLastWeapon entity_t
---@field m_nNextThinkTick number 
---@field m_nTickBase number 
---@field m_fOnTarget number 
---@field m_flFriction number 
---@field m_vecViewOffset vec3_t
---@field m_bAllowAutoMovement number 
---@field m_flStepSize number 
---@field m_bPoisoned number 
---@field m_bWearingSuit number 
---@field m_bDrawViewmodel number 
---@field m_aimPunchAngleVel vec3_t 
---@field m_aimPunchAngle vec3_t 
---@field m_viewPunchAngle vec3_t 
---@field m_flFallVelocity number 
---@field m_nJumpTimeMsecs number 
---@field m_nDuckJumpTimeMsecs number 
---@field m_nDuckTimeMsecs number 
---@field m_bInDuckJump number 
---@field m_flLastDuckTime number 
---@field m_bDucking number 
---@field m_bDucked number 
---@field m_flFOVRate number 
---@field m_iHideHUD number 
---@field m_chAreaPortalBits table 
---@field m_chAreaBits table 
---@field m_hMyWearables entity_t[]
---@field m_hMyWeapons entity_t[]
---@field m_nRelativeDirectionOfLastInjury number 
---@field m_flTimeOfLastInjury number 
---@field m_hActiveWeapon entity_t
---@field m_LastHitGroup number 
---@field m_flNextAttack number 
---@field m_flLastExoJumpTime number 
---@field m_flHealthShotBoostExpirationTime number 
---@field m_hSurvivalAssassinationTarget entity_t 
---@field m_nSurvivalTeam number 
---@field m_vecSpawnRappellingRopeOrigin vec3_t 
---@field m_bIsSpawnRappelling number 
---@field m_bHideTargetID number 
---@field m_flThirdpersonRecoil number 
---@field m_bStrafing number 
---@field m_flLowerBodyYawTarget number 
---@field m_unTotalRoundDamageDealt number 
---@field m_iNumRoundKillsHeadshots number 
---@field m_bIsLookingAtWeapon number 
---@field m_bIsHoldingLookAtWeapon number 
---@field m_nDeathCamMusic number 
---@field m_nLastConcurrentKilled number 
---@field m_nLastKillerIndex number 
---@field m_bHud_RadarHidden number 
---@field m_bHud_MiniScoreHidden number 
---@field m_bIsAssassinationTarget number 
---@field m_flAutoMoveTargetTime number 
---@field m_flAutoMoveStartTime number 
---@field m_vecAutomoveTargetEnd vec3_t 
---@field m_iControlledBotEntIndex number 
---@field m_bCanControlObservedBot number 
---@field m_bHasControlledBotThisRound number 
---@field m_bIsControllingBot number 
---@field m_unFreezetimeEndEquipmentValue number 
---@field m_unRoundStartEquipmentValue number 
---@field m_unCurrentEquipmentValue number 
---@field m_cycleLatch number 
---@field m_hPlayerPing number 
---@field m_hRagdoll entity_t
---@field m_flProgressBarStartTime number 
---@field m_iProgressBarDuration number 
---@field m_flFlashMaxAlpha number 
---@field m_flFlashDuration number 
---@field m_nHeavyAssaultSuitCooldownRemaining number 
---@field m_bHasHeavyArmor number 
---@field m_bHasHelmet number 
---@field m_unMusicID number 
---@field m_bHasParachute number 
---@field m_passiveItems table 
---@field m_rank table 
---@field m_iMatchStats_EnemiesFlashed table 
---@field m_iMatchStats_UtilityDamage table 
---@field m_iMatchStats_CashEarned table 
---@field m_iMatchStats_Objective table 
---@field m_iMatchStats_HeadShotKills table 
---@field m_iMatchStats_Assists table 
---@field m_iMatchStats_Deaths table 
---@field m_iMatchStats_LiveTime table 
---@field m_iMatchStats_KillReward table 
---@field m_iMatchStats_MoneySaved table 
---@field m_iMatchStats_EquipmentValue table 
---@field m_nPersonaDataPublicLevel table
---@field m_iMatchStats_Damage table 
---@field m_iMatchStats_Kills table 
---@field m_bIsPlayerGhost number 
---@field m_flDetectedByEnemySensorTime number 
---@field m_flGuardianTooFarDistFrac number 
---@field m_isCurrentGunGameTeamLeader number 
---@field m_isCurrentGunGameLeader number 
---@field m_bCanMoveDuringFreezePeriod number 
---@field m_flGroundAccelLinearFracLastTime number 
---@field m_bIsRescuing number 
---@field m_hCarriedHostageProp entity_t 
---@field m_hCarriedHostage entity_t 
---@field m_szArmsModel string 
---@field m_fMolotovDamageTime number 
---@field m_fMolotovUseTime number 
---@field m_iNumRoundKills number 
---@field m_iNumGunGameKillsWithCurrentWeapon number 
---@field m_iNumGunGameTRKillPoints number 
---@field m_iGunGameProgressiveWeaponIndex number 
---@field m_bMadeFinalGunGameProgressiveKill number 
---@field m_bHasMovedSinceSpawn number 
---@field m_bGunGameImmunity number 
---@field m_fImmuneToGunGameDamageTime number 
---@field m_bResumeZoom number 
---@field m_nIsAutoMounting number 
---@field m_bIsWalking number 
---@field m_bIsScoped number 
---@field m_iBlockingUseActionInProgress number 
---@field m_bIsGrabbingHostage number 
---@field m_bIsDefusing number 
---@field m_bInHostageRescueZone number 
---@field m_bHasNightVision number 
---@field m_bNightVisionOn number 
---@field m_bHasDefuser number 
---@field m_angEyeAngles vec3_t 
---@field m_ArmorValue number 
---@field m_iClass number 
---@field m_iMoveState number 
---@field m_bKilledByTaser number 
---@field m_bInNoDefuseArea number 
---@field m_bInBuyZone number 
---@field m_bInBombZone number 
---@field m_totalHitsOnServer number 
---@field m_iStartAccount number 
---@field m_iAccount number 
---@field m_iPlayerState number 
---@field m_bIsRespawningForDMBonus number 
---@field m_bWaitForNoAttack number 
---@field m_iThrowGrenadeCounter number 
---@field m_iSecondaryAddon number 
---@field m_iPrimaryAddon number 
---@field m_iAddonBits number 
---@field m_iWeaponPurchasesThisMatch table 
---@field m_nQuestProgressReason number 
---@field m_unActiveQuestId number 
---@field m_iWeaponPurchasesThisRound table 
---@field m_bPlayerDominatingMe table 
---@field m_bPlayerDominated table 
---@field m_flVelocityModifier number 
---@field m_bDuckOverride number 
---@field m_nNumFastDucks number 
---@field m_iShotsFired number 
---@field m_iDirection number 
---@field m_flStamina number 
---@field m_flNextPrimaryAttack number
---@field m_flNextSecondaryAttack number
---@field m_fLastShotTime number
---@field m_hThrower entity_t
---@field m_nExplodeEffectTickBegin number
---@field m_nGrenadeSpawnTime number
---@field m_vInitialVelocity vec3_t

local IClientEntityList = interface.new("client", "VClientEntityList003", {
    GetClientEntity = {3, "uintptr_t(__thiscall*)(void*, int)"},
})
local CBaseEntity = class.new({
    GetCollideable = {3, "uintptr_t(__thiscall*)(void*)"},
    GetNetworkable = {4, "uintptr_t(__thiscall*)(void*)"},
    GetClientRenderable = {5, "uintptr_t(__thiscall*)(void*)"},
    GetClientEntity = {6, "uintptr_t(__thiscall*)(void*)"},
    GetBaseEntity = {7, "uintptr_t(__thiscall*)(void*)"},
    GetClientThinkable = {8, "uintptr_t(__thiscall*)(void*)"},
    SetModelIndex = {75, "void(__thiscall*)(void*,int)"},
    IsPlayer = {158, "bool(__thiscall*)(void*)"},
    IsWeapon = {166, "bool(__thiscall*)(void*)"},
})
ffi.cdef[[
    struct ClientClass {
        void*   m_pCreateFn;
        void*   m_pCreateEventFn;
        char*   network_name;
        void*   m_pRecvTable;
        void*   m_pNext;
        int     class_id;
    };
]]
local CClientNetworkable = class.new({
    -- GetClientUnknown = {0, "uintptr_t(__thiscall*)(void*)"},
    -- GetClientClass = {2, "struct ClientClass*(__thiscall*)(void*)"},
})

---@param index number
---@return ffi.ctype*
entitylist.get_client_entity = function(index)
    ---@diagnostic disable-next-line: undefined-field
    return IClientEntityList:GetClientEntity(index)
end
local entitylist_get_players_o = entitylist.get_players
entitylist.get_players = function (type)
    local players = entitylist_get_players_o(type)
    local new = {}
    for i = 1, #players do
        new[i] = players[i]
    end
    return new
end
---@param steam_id string
---@return entity_t?
entitylist.get_entity_by_steam_id = function (steam_id)
    for _, player in pairs(entitylist.get_players(2)) do
        if player:get_info().steam_id64 == steam_id then
            return player
        end
    end
end
---@param userid number
---@return entity_t?
entitylist.get_entity_by_userid = function (userid)
    for _, player in pairs(entitylist.get_players(2)) do
        local info = player:get_info()
        if info and info.user_id == userid then
            return player
        end
    end
end
---@return entity_t?
entitylist.get_local_player_or_observed_player = function()
    local lp = entitylist.get_local_player()
    if not lp then return end
    if lp:is_alive() then
        return lp
    else
        return lp.m_hObserverTarget
    end
end

---@param flag number
entity_t.get_flag = function (self, flag)
    return bit.band(self.m_fFlags, flag) ~= 0
end

---@return boolean
entity_t.is_on_ground = function (self)
    return self:get_flag(1)
end

-- ---@return vec3_t
-- entity_t.get_velocity = function (self)
--     return self.m_vecVelocity
-- end

-- ---@return vec3_t
-- entity_t.get_origin = function (self)
--     return self.m_vecOrigin
-- end

entity_t.update = function(self)
    return entitylist.get_entity_by_index(self:get_index())
end

entity_t.get_info = function (self)
    return engine.get_player_info(self:get_index())
end

do
    ---@return "flashbang"|"he"|"smoke"|"decoy"|"molotov"|nil
    entity_t.get_grenade_type = function(self)
        local client_class = self:get_client_class()
        if not client_class then return end
        local index = client_class.class_id
        local name
        if index == 9 then
            local model = self:get_model()
            if not model then return end
            local model_name = ffi.string(model.name)
            if not model_name:find("fraggrenade_dropped") then
                name = "flashbang"
            else
                name = "he"
            end
        elseif index == 157 then
            name = "smoke"
        elseif index == 48 then
            name = "decoy"
        elseif index == 114 then -- class name CIncendiaryGrenade
            name = "molotov"
        end
        return name
    end
end

do
    local ticks = {}
    ---@return number
    entity_t.get_ticks_in_dormant = function(self)
        local info = self:get_info()
        if not info then return 0 end
        local id = info.user_id
        if not ticks[id] then
            ticks[id] = 0 end
        return ticks[id]
    end
    cbs.create_move(function()
        for _, entity in pairs(entitylist.get_players(2)) do
            if entity then
                local info = entity:get_info()
                if info then
                    local id = info.user_id
                    if not ticks[id] then
                        ticks[id] = 0
                    end
                    if entity:is_dormant() then
                        ticks[id] = ticks[id] + 1
                    else
                        ticks[id] = 0
                    end
                end
            end
        end
    end)
    cbs.event("round_prestart", function ()
        for k, _ in pairs(ticks) do
            ticks[k] = math.huge
        end
    end)
end

entity_t.get_class = function (self)
    return CBaseEntity(self[0])
end

entity_t.get_networkable = function (self)
    return ffi.cast("uintptr_t*", self[0] + 8)[0]
end

entity_t.get_studio_hdr = function(self)
    local studio_hdr = ffi.cast("void**", self[0] + 0x2950) or error("failed to get studio_hdr")
    studio_hdr = studio_hdr[0] or error("failed to get studio_hdr")
    return studio_hdr
end

ffi.cdef[[
    typedef struct {
        char pad[8];
	    float m_start;
	    float m_end;
        float m_state;
    } m_flposeparameter_t;
]]
do
    local get_poseparam_sig = client.find_pattern('client.dll', '55 8B EC 8B 45 08 57 8B F9 8B 4F 04 85 C9 75 15')
    local native_get_poseparam = ffi.cast('m_flposeparameter_t*(__thiscall*)(void*, int)', get_poseparam_sig)
    if not get_poseparam_sig or not native_get_poseparam then error('failed to find get_poseparam_sig') end
    ---@param index number
    ---@return { m_start: number, m_end: number, m_state: number }
    entity_t.get_poseparam = function(self, index)
        local studio_hdr = self:get_studio_hdr()
        local param = native_get_poseparam(studio_hdr, index)
        if not param then error("failed to get pose param " .. tostring(index)) end
        return param
    end
    ---@param index number
    ---@param m_start number
    ---@param m_end number
    ---@param m_state? number
    entity_t.set_poseparam = function(self, index, m_start, m_end, m_state)
        local param = self:get_poseparam(index)
        local state = m_state
        if state == nil then
            state = ((m_start + m_end) / 2)
        end
        param.m_start, param.m_end, param.m_state = m_start, m_end, state
    end
    entity_t.restore_poseparam = function(self)
        self:set_poseparam(0, -180, 180)
        self:set_poseparam(12, -90, 90)
        self:set_poseparam(6, 0, 1, 0)
        self:set_poseparam(7, -180, 180)
    end
end

do
    ---@return "Stand"|"Move"|"Air"|"Air duck"|"Duck"|nil
    entity_t.get_condition = function(self)
        local velocity = #self.m_vecVelocity
        local is_on_ground = self:is_on_ground()
        local is_ducking = self.m_flDuckAmount > 0.25
        if velocity < 2 and is_on_ground then
            if is_ducking then
                return "Duck"
            end
            return "Stand"
        elseif velocity >= 2 and is_on_ground then
            if is_ducking then
                return "Duck"
            end
            return "Move"
        elseif velocity >= 2 and not is_on_ground then
            if is_ducking then
                return "Air duck"
            end
            return "Air"
        end
    end
end

---@return { network_name: string, class_id: number }?
entity_t.get_client_class = function (self)
    local networkable = self:get_networkable()
    if not networkable then return end
    local client_class = ffi.cast("struct ClientClass**", ffi.cast("uintptr_t*", networkable + 2 * 4)[0] + 1)[0]
    -- if not client_class then return end
    return {
        network_name = ffi.string(client_class.network_name),
        class_id = client_class.class_id,
    }
end

local is_breakable_fn = ffi.cast("bool(__thiscall*)(void*)", client.find_pattern("client.dll", "55 8B EC 51 56 8B F1 85 F6 74 68")) or error("can't find is_breakable")
entity_t.is_breakable = function(self)
    local ptr = ffi.cast("void*", self[0])
    if is_breakable_fn(ptr) then
        return true
    end
    -- local client_class = self:get_client_class()
    -- if not client_class then
    --     return false
    -- end
    return false
end

entity_t.is_player = function(self)
    return self:get_client_class().class_id == 40
end

entity_t.is_weapon = function(self)
    return self:get_class():IsWeapon()
end

entity_t.is_grenade = function(self)
    return self:get_grenade_type() ~= nil
end

entity_t.can_shoot = function (self)
    local tickbase = self.m_nTickBase * globalvars.get_interval_per_tick()
    if self.m_flNextAttack > tickbase then
        return false
    end
    local weapon = self:get_weapon()
    if not weapon then return false end
    if weapon.entity.m_flNextPrimaryAttack > tickbase then
        return false
    end
    if weapon.entity.m_flNextSecondaryAttack > tickbase then
        return false
    end
    return true
end

do
    local ccsplayer = ffi.cast("int*",
        (client.find_pattern("client.dll", "55 8B EC 83 E4 F8 83 EC 18 56 57 8B F9 89 7C 24 0C") or error("wrong ccsplayer sig")) + 0x47)
    local raw_get_abs_origin = ffi.cast("float*(__thiscall*)(void*)", ffi.cast("int*", ccsplayer[0] + 0x28)[0])
    ---@return vec3_t?
    entity_t.get_abs_origin = function (self)
        local address = self[0]
        if address == 0 then return end
        local origin = raw_get_abs_origin(ffi.cast("void*", address))
        return v3(origin[0], origin[1], origin[2])
    end
end

entity_t.get_eye_pos = function(self)
    return self:get_abs_origin() + self.m_vecViewOffset
end

ffi.cdef[[
    typedef struct{
        void*       handle;
        char        name[260];
        int         load_flags;
        int         server_count;
        int         type;
        int         flags;
        vector_t    mins;
        vector_t    maxs;
        float       radius;
        char        pad[28];  
    } model_t;
]]
local IModelInfoClient = interface.new("engine", "VModelInfoClient004", {
    GetModelIndex = {2, "int(__thiscall*)(void*, PCSTR)"},
    FindOrLoadModel = {39, "const model_t(__thiscall*)(void*, PCSTR)"}
})
local IEngineServerStringTable = interface.new("engine", "VEngineClientStringTable001", {
    FindTable = {3, "void*(__thiscall*)(void*, PCSTR)"}
})
local PrecachedTableClass = class.new({
    AddString = {8, "int(__thiscall*)(void*, bool, PCSTR, int, const void*)"}
})
-- local imdlcache_raw = se.create_interface("datacache.dll", "MDLCache004") or error("couldn't find MDLCache004")
-- local imdlcache_vmt = hooks.vmt.new(imdlcache_raw)
-- local findmdl
-- findmdl = imdlcache_vmt:hookMethod("unsigned short(__thiscall*)(void*, char*)", function(thisptr, path)
--     print("TEST")
--     return findmdl(thisptr, path)
-- end, 10)
-- cbs.unload(function ()
--     imdlcache_vmt:unHookAll()
-- end)
---@param path string
---@return number
local precache_model = errors.handler(function(path)
    local rawprecache_table = IEngineServerStringTable:FindTable("modelprecache") or error("couldnt find modelprecache", 2)
    if rawprecache_table and rawprecache_table ~= nil then
        local precache_table = PrecachedTableClass(rawprecache_table)
        if precache_table then
            IModelInfoClient:FindOrLoadModel(path)
            local idx = precache_table:AddString(false, path, -1, nil)
            return idx
        end
    end
    return -1
end, "precache_model")
---@param self entity_t
---@param path string
entity_t.set_model = errors.handler(function(self, path)
    local index = IModelInfoClient:GetModelIndex(path)
    if index == -1 then
        index = precache_model(path)
    end
    if index == -1 then
        error("couldn't precache model")
    end
    local ragdoll = self.m_hRagdoll
    if ragdoll then
        local cbaseentity = ragdoll:get_class()
        if cbaseentity then
            cbaseentity:SetModelIndex(index)
        end
    end
    local cbaseentity = self:get_class()
    if cbaseentity then
        cbaseentity:SetModelIndex(index)
    end
end, "entity_t.set_model")

---@return { handle: any, name: any, load_flags: number, server_count: number, type: number, flags: number, mins: vec3_t, maxs: vec3_t, radius: number }
entity_t.get_model = function(self)
    return ffi.cast("model_t**", self[0] + 0x6C)[0]
end


ffi.cdef[[
    typedef struct {
        char pad0x0[ 20 ];
        int	order;
        int	sequence;
        float previous_cycle;
        float weight;
        float weight_delta_rate;
        float playback_rate;
        float cycle;
        void* owner;
        char pad0x1[ 4 ];
    } animlayer_t;
]]
---@param index number
---@return { order: number, sequence: number, previous_cycle: number, weight: number, weight_delta_rate: number, playback_rate: number, cycle: number }?
entity_t.get_animlayer = function(self, index)
    local address = self[0]
    if address == 0 then return end
    return ffi.cast("animlayer_t**", address + 0x2990)[0][index]
end

---@param attacker entity_t
entity_t.is_hittable_by = function(self, attacker)
    --!SELF IS THE VICTIM
    --!ATTACKER IS USUALLY THE LOCAL PLAYER
    local from = attacker:get_eye_pos() + v3(0, 0, 10)
    local to = self:get_player_hitbox_pos(0)
    if not to then return end
    local trace_result = trace.line(attacker:get_index(), 0x46004003, from, to)
    if trace_result.hit_entity_index == self:get_index() then
        return true
    end
    return false
end

local cached_ranks = {}
entity_t.set_rank = function(self, rank)
    local index = self:get_index()
    local playerresource = entitylist.get_entities_by_class_id(41)[1]
    if not playerresource then return end
    local info = self:get_info()
    if not info then return end
    local userid = info.user_id
    if not cached_ranks[userid] then
        cached_ranks[userid] = {
            real = playerresource.m_nPersonaDataPublicLevel[index],
        }
        cached_ranks[userid].fake = rank
    end
    if rank == nil then
        rank = cached_ranks[userid].real
        cached_ranks[userid] = nil
    end
    if playerresource.m_nPersonaDataPublicLevel[index] ~= rank then
        playerresource.m_nPersonaDataPublicLevel[index] = rank
    end
end
client.register_callback("paint", function ()
    if not engine.is_connected() then
        cached_ranks = {}
        return
    end
    for _, player in pairs(entitylist.get_players(2)) do
        local info = player:get_info()
        if info then
            local userid = info.user_id
            if cached_ranks[userid] then
                player:set_rank(cached_ranks[userid].fake)
            end
        end
    end
end)
client.register_callback("unload", function ()
    if not engine.is_connected() then
        cached_ranks = {}
        return
    end
    for userid, rank in pairs(cached_ranks) do
        local player = entitylist.get_entity_by_userid(userid)
        if player then
            player:set_rank(rank.real)
        end
    end
end)

---@param cmd? usercmd_t
entity_t.is_shooting = function(self, cmd)
    local is_shooting = (self.m_iShotsFired >= 1) and not self:can_shoot()
    return is_shooting
end

ffi.cdef[[
    struct WeaponInfo_t{
        char pad1[6];
        uint8_t class;
        char pad2[13];
        int max_clip;	
        char pad3[12];
        int max_ammo;
        char pad4[96];
        char* hud_name;			
        char* name;		
        char pad5[56];
        int type;
    };
]]
do
    local raw_get_weapon_data = ffi.cast("struct WeaponInfo_t*(__thiscall*)(void*)", client.find_pattern("client.dll", "55 8B EC 81 EC ? ? ? ? 53 8B D9 56 57 8D 8B ? ? ? ? 85 C9 75 04")) or error("failed to find get_weapon_data")
    local weapon_groups = {
        "knife",
        "pistols",
        "smg",
        "rifle",
        "shotguns",
        "sniper",
        "rifle",
        "c4",
        "placeholder",
        "grenade",
        "unknown"
    }
    local group_by_name = {
        awp = "awp",
        ssg08 = "scout",
        g3sg1 = "auto",
        scar20 = "auto",
        deagle = "deagle",
        taser = "taser",
        c4 = "c4"
    }
    ---@param index? number
    ---@return { entity: entity_t, class: number, name: string, type: number, group: "knife"|"pistols"|"smg"|"rifle"|"shotguns"|"sniper"|"awp"|"auto"|"deagle"|"taser"|"scout"|"rifle"|"c4"|"placeholder"|"grenade"|"revolver"|"unknown" }?
    entity_t.get_weapon = function (self, index)
        local weapon
        if index ~= nil then
            weapon = self.m_hMyWeapons[index]
        else
            weapon = self.m_hActiveWeapon
        end
        if not weapon then return end
        local data = raw_get_weapon_data(ffi.cast("void*", weapon[0]))
        local name = ffi.string(data.name):gsub("weapon_", "")
        local group = weapon_groups[data.type + 1]
        if group_by_name[name] then
            group = group_by_name[name] end
        if ffi.string(data.hud_name):find("REVOLVER") then
            group = "revolver" end
        return {
            entity = weapon,
            class = data.class,
            name = name,
            type = data.type,
            group = group,
        }
    end
end

local netvar_table_list = {
    "AI_BaseNPC",
    "WeaponAK47",
    "BaseAnimating", "BaseAnimatingOverlay", "BaseAttributableItem", "BaseButton", "BaseCombatCharacter",
    "BaseCombatWeapon", "BaseCSGrenade", "BaseCSGrenadeProjectile", "BaseDoor", "BaseEntity",
    "BaseFlex", "BaseGrenade", "BaseParticleEntity", "BasePlayer", "BasePropDoor",
    "BaseTeamObjectiveResource", "BaseTempEntity", "BaseToggle", "BaseTrigger", "BaseViewModel",
    "BaseVPhysicsTrigger", "BaseWeaponWorldModel",
    "Beam",
    "BeamSpotlight",
    "BoneFollower",
    "BRC4Target",
    "WeaponBreachCharge",
    "BreachChargeProjectile",
    "BreakableProp", "BreakableSurface",
    "WeaponBumpMine",
    "BumpMineProjectile",
    "WeaponC4",
    "CascadeLight",
    "CChicken",
    "ColorCorrection", "ColorCorrectionVolume",
    "CSGameRulesProxy", "CSPlayer", "CSPlayerResource", "CSRagdoll", "CSTeam",
    "DangerZone", "DangerZoneController",
    "WeaponDEagle",
    "DecoyGrenade", "DecoyProjectile",
    "Drone", "Dronegun",
    "DynamicLight", "DynamicProp",
    "EconEntity",
    "WearableItem",
    "Embers",
    "EntityDissolve", "EntityFlame", "EntityFreezing", "EntityParticleTrail",
    "EnvAmbientLight",
    "DetailController",
    "EnvDOFController", "EnvGasCanister", "EnvParticleScript", "EnvProjectedTexture",
    "QuadraticBeam",
    "EnvScreenEffect", "EnvScreenOverlay", "EnvTonemapController",
    "EnvWind",
    "FEPlayerDecal",
    "FireCrackerBlast", "FireSmoke", "FireTrail",
    "CFish",
    "WeaponFists",
    "Flashbang",
    "FogController",
    "FootstepControl",
    "Func_Dust", "Func_LOD", "FuncAreaPortalWindow", "FuncBrush", "FuncConveyor",
    "FuncLadder", "FuncMonitor", "FuncMoveLinear", "FuncOccluder", "FuncReflectiveGlass",
    "FuncRotating", "FuncSmokeVolume", "FuncTrackTrain",
    "GameRulesProxy",
    "GrassBurn",
    "HandleTest",
    "HEGrenade",
    "CHostage",
    "HostageCarriableProp",
    "IncendiaryGrenade",
    "Inferno",
    "InfoLadderDismount", "InfoMapRegion", "InfoOverlayAccessor",
    "Item_Healthshot", "ItemCash", "ItemDogtags",
    "WeaponKnife", "WeaponKnifeGG",
    "LightGlow",
    "MapVetoPickController",
    "MaterialModifyControl",
    "WeaponMelee",
    "MolotovGrenade", "MolotovProjectile",
    "MovieDisplay",
    "ParadropChopper",
    "ParticleFire",
    "ParticlePerformanceMonitor",
    "ParticleSystem",
    "PhysBox", "PhysBoxMultiplayer", "PhysicsProp", "PhysicsPropMultiplayer", "PhysMagnet",
    "PhysPropAmmoBox", "PhysPropLootCrate", "PhysPropRadarJammer", "PhysPropWeaponUpgrade",
    "PlantedC4",
    "Plasma",
    "PlayerPing", "PlayerResource",
    "PointCamera", "PointCommentaryNode", "PointWorldText",
    "PoseController",
    "PostProcessController",
    "Precipitation",
    "PrecipitationBlocker",
    "PredictedViewModel",
    "Prop_Hallucination", "PropCounter", "PropDoorRotating", "PropJeep", "PropVehicleDriveable",
    "RagdollManager", "Ragdoll", "Ragdoll_Attached",
    "RopeKeyframe",
    "WeaponSCAR17",
    "SceneEntity",
    "SensorGrenade", "SensorGrenadeProjectile",
    "ShadowControl",
    "SlideshowDisplay",
    "SmokeGrenade", "SmokeGrenadeProjectile", "SmokeStack",
    "Snowball",
    "SnowballPile", "SnowballProjectile",
    "SpatialEntity",
    "SpotlightEnd",
    "Sprite", "SpriteOriented", "SpriteTrail",
    "StatueProp",
    "SteamJet",
    "Sun",
    "SunlightShadowControl",
    "SurvivalSpawnChopper",
    "WeaponTablet",
    "Team",
    "TeamplayRoundBasedRulesProxy",
    "TEArmorRicochet",
    "ProxyToggle",
    "TestTraceline",
    "TEWorldDecal",
    "TriggerPlayerMovement", "TriggerSoundOperator",
    "VGuiScreen",
    "VoteController",
    "WaterBullet",
    "WaterLODControl",
    "WeaponAug", "WeaponAWP", "WeaponBaseItem", "WeaponBizon", "WeaponCSBase",
    "WeaponCSBaseGun", "WeaponCycler", "WeaponElite", "WeaponFamas", "WeaponFiveSeven",
    "WeaponG3SG1", "WeaponGalil", "WeaponGalilAR", "WeaponGlock", "WeaponHKP2000",
    "WeaponM249", "WeaponM3", "WeaponM4A1", "WeaponMAC10", "WeaponMag7",
    "WeaponMP5Navy", "WeaponMP7", "WeaponMP9", "WeaponNegev", "WeaponNOVA",
    "WeaponP228", "WeaponP250", "WeaponP90", "WeaponSawedoff", "WeaponSCAR20",
    "WeaponScout", "WeaponSG550", "WeaponSG552", "WeaponSG556", "WeaponShield",
    "WeaponSSG08", "WeaponTaser", "WeaponTec9", "WeaponTMP", "WeaponUMP45",
    "WeaponUSP", "WeaponXM1014", "WeaponZoneRepulsor",
    "WORLD",
    "WorldVguiText",
    "DustTrail",
    "MovieExplosion",
    "ParticleSmokeGrenade",
    "RocketTrail",
    "SmokeTrail",
    "SporeExplosion",
    "SporeTrail",
    "AnimTimeMustBeFirst",
    "CollisionProperty"
}
for i = 1, #netvar_table_list do
    netvar_table_list[i] = "DT_" .. netvar_table_list[i]
end

---@alias __netvar_t { type: string, offset: number, table_type?: string }
---@type table<string, __netvar_t>
local netvar_cache = {
    m_flPoseParameter = { type = "table" },
    m_flEncodedController = { type = "table" },
    m_flexWeight = { type = "table" },
    m_iAmmo = { type = "table" },
    m_bCPIsVisible = { type = "table" },
    m_flLazyCapPerc = { type = "table" },
    m_iTeamIcons = { type = "table" },
    m_iTeamOverlays = { type = "table" },
    m_iTeamReqCappers = { type = "table" },
    m_flTeamCapTime = { type = "table" },
    m_iPreviousPoints = { type = "table" },
    m_bTeamCanCap = { type = "table" },
    m_iTeamBaseIcons = { type = "table" },
    m_iBaseControlPoints = { type = "table" },
    m_bInMiniRound = { type = "table" },
    m_iWarnOnCap = { type = "table" },
    m_flPathDistance = { type = "table" },
    m_iNumTeamMembers = { type = "table" },
    m_iCappingTeam = { type = "table" },
    m_iTeamInZone = { type = "table" },
    m_bBlocked = { type = "table" },
    m_iOwner = { type = "table" },
    m_iMatchStats_Kills = { type = "table" },
    m_iMatchStats_Damage = { type = "table" },
    m_iMatchStats_EquipmentValue = { type = "table" },
    m_iMatchStats_MoneySaved = { type = "table" },
    m_iMatchStats_KillReward = { type = "table" },
    m_iMatchStats_LiveTime = { type = "table" },
    m_iMatchStats_Deaths = { type = "table" },
    m_iMatchStats_Assists = { type = "table" },
    m_iMatchStats_HeadShotKills = { type = "table" },
    m_iMatchStats_Objective = { type = "table" },
    m_iMatchStats_CashEarned = { type = "table" },
    m_iMatchStats_UtilityDamage = { type = "table" },
    m_iMatchStats_EnemiesFlashed = { type = "table" },
    m_hMyWeapons = { type = "table" },
    m_nPersonaDataPublicLevel = { type = "table" },
    m_vecViewOffset = {
        type = "vector",
        offset = 264
    },
    m_fLastShotTime = { type = "float" },
    m_nGrenadeSpawnTime = {
        type = "float",
        offset = se.get_netvar("DT_BaseCSGrenadeProjectile", "m_vecExplodeEffectOrigin") + 12
    }
}
local netvar_types = {
    b = "bool",
    i = "int",
    f = "float",
    v = "vector",
    a = "angle",
    h = "entity",
    n = "int"
}

---@param netvar string
---@return __netvar_t?
local initialize_netvar = function(netvar)
    if netvar_cache[netvar] and netvar_cache[netvar].offset then
        return netvar_cache[netvar]
    end
    for _, table_name in pairs(netvar_table_list) do
        local offset = se.get_netvar(table_name, netvar)
        if offset and offset ~= 0 then
            local netvar_type = netvar_types[netvar:sub(3, 3)]
            if netvar_type == "float" and netvar:sub(3, 4) ~= "fl" then
                netvar_type = "int"
            end
            if netvar_cache[netvar] then
                if netvar_cache[netvar].type == "table" then
                    netvar_cache[netvar] = {
                        offset = offset,
                        type = "table",
                        table_type = netvar_type
                    }
                    return netvar_cache[netvar]
                end
                if netvar_cache[netvar].type then
                    netvar_type = netvar_cache[netvar].type
                end
            end
            netvar_cache[netvar] = {
                offset = offset,
                type = netvar_type
            }
            return netvar_cache[netvar]
        end
    end
end

local netvar_table_mt = {
    ---@param self { netvar: __netvar_t, entity: entity_t }
    __index = errors.handler(function(self, key)
        if type(key) ~= "number" then
            error("netvar table index must be a number")
        end
        local offset = self.netvar.offset + key * 4
        if self.netvar.table_type == "entity" then
            return entitylist.get_entity_from_handle(self.entity:get_prop_int(offset))
        end
        return self.entity["get_prop_"..self.netvar.table_type](self.entity, offset)
    end, "netvar_table_t.__index"),
    __newindex = function (self, key, value)
        if type(key) ~= "number" then
            error("netvar table index must be a number")
        end
        local offset = self.netvar.offset + key * 4
        return self.entity["set_prop_"..self.netvar.table_type](self.entity, offset, value)
    end
}
local netvar_table_t = {
    new = function (entity, netvar)
        return setmetatable({
            netvar = netvar,
            entity = entity,
        }, netvar_table_mt)
    end
}

---@param prop string
entity_t.__get_prop = errors.handler(function(self, prop)
    local netvar = initialize_netvar(prop)
    if not netvar then
        error("failed to init " .. prop .. " netvar")
    end
    if netvar.type == "table" then
        return netvar_table_t.new(self, netvar)
    end
    if netvar.type == "entity" then
        return entitylist.get_entity_from_handle(self:get_prop_int(netvar.offset))
    end
    return self["get_prop_"..netvar.type](self, netvar.offset)
end, "entity_t.__get_prop")
---@param prop string
---@param value any
entity_t.__set_prop = errors.handler(function(self, prop, value)
    local netvar = initialize_netvar(prop)
    if not netvar then
        error("failed to init " .. prop .. " netvar")
    end
    if netvar.type == "table" then
        error("cannot set netvar table")
    end
    return self["set_prop_"..netvar.type](self, netvar.offset, value)
end, "entity_t.__set_prop")
local entity_mt
local initialize_entity_mt = function()
    local lp = entitylist.get_local_player()
    if not lp then return end
    entity_mt = getmetatable(lp)
    ---@param self entity_t
    entity_mt.__index = function (self, key)
        if key == 0 then return entitylist.get_client_entity(self:get_index()) end
        local result = entity_t[key]
        if result then return result end
        return entity_t.__get_prop(self, key)
    end
    ---@param self entity_t
    entity_mt.__newindex = function (self, key, value)
        if key == 0 then error("cannot set entity index") end
        local result = entity_t[key]
        if result then error("cannot set entity property") end
        return entity_t.__set_prop(self, key, value)
    end
end

if not entity_mt then
    initialize_entity_mt()
    if not entity_mt then
        cbs.frame_stage(function (stage)
            if not entity_mt then initialize_entity_mt() end
        end)
    end
end

end)
__bundle_register("features.revealer", function(require, _LOADED, __bundle_register, __bundle_modules)
local ffi = require("libs.protected_ffi")
local errors = require("libs.error_handler")
local iengine = require("includes.engine")
local cbs = require("libs.callbacks")
local col = require("libs.colors")
local hooks = require("libs.hooks")
local voice_data_msg = client.find_pattern("engine.dll", "55 8B EC 83 E4 F8 A1 ? ? ? ? 81 EC 84 01 00")
ffi.cdef[[
    struct voice_data_t {
		char		pad_0000[8]; //0
		int32_t     client; //8
		int32_t     audible_mask; //12
		uint32_t    xuid_low; //16
		uint32_t    xuid_high; //20
		void*		voice_data; //24
		bool		proximity; //28
		bool		caster; //29
		char		pad_001E[2]; //30
		int32_t     format; //32
		int32_t	    sequence_bytes; //36
		uint32_t    section_number; //40
		uint32_t    uncompressed_sample_offset; //44
		char		pad_0030[4]; //48
		uint32_t    has_bits; //52
	};
    struct voice_communication_t {
        uint32_t    xuid_low; //0
        uint32_t    xuid_high; //4
        int32_t     sequence_bytes; //8
        uint32_t    section_number; //12
        uint32_t    uncompressed_sample_offset; //16
    };
    struct CommunicationString_t {
	    char        szData[16];
	    uint32_t    m_nCurrentLen;
	    uint32_t    m_nMaxLen;
    };
    struct voice_data_msg_t {
        void*       inetmessage_vtable; //0x0000
	    char        pad_0004[4]; //0x0004
	    void*       voicedata_vtable; //0x0008
	    char        pad_000c[8]; //0x000C
	    void*       data; //0x0014
	    uint32_t    xuid_low;
	    uint32_t    xuid_high;
	    int32_t     format; //0x0020
	    int32_t     sequence_bytes; //0x0024
	    uint32_t    section_number; //0x0028
	    uint32_t    uncompressed_sample_offset; //0x002C
	    int32_t     cached_size; //0x0030
	    uint32_t    flags; //0x0034
	    uint8_t     no_stack_overflow[255];
    };
    struct floridahook_shared_esp_data_t{
        uint32_t    id;
        uint8_t     user_id;
        int16_t     origin_x;
        int16_t     origin_y;
        int16_t     origin_z;
        int8_t      health;
    };
]]
local voice_data_construct = ffi.cast("uint32_t(__fastcall*)(struct voice_data_msg_t*, void*)", client.find_pattern("engine.dll", "56 57 8B F9 8D 4F 08 C7 07 ? ? ? ? E8 ? ? ? ? C7") or error("failed to find voice_data_construct"))
local function send_voice_msg(data)
    if not voice_data_construct then return end
    local msg = ffi.new("struct voice_data_msg_t[1]")
    ffi.fill(msg, ffi.sizeof(msg))
    voice_data_construct(msg, nil)

    local voice_data = ffi.new("struct voice_communication_t[1]")
    ffi.fill(voice_data, ffi.sizeof(voice_data))
    ffi.copy(voice_data, data, ffi.sizeof(data))
    msg[0].xuid_low = voice_data[0].xuid_low
    msg[0].xuid_high = voice_data[0].xuid_high
    msg[0].sequence_bytes = voice_data[0].sequence_bytes
    msg[0].section_number = voice_data[0].section_number
    msg[0].uncompressed_sample_offset = voice_data[0].uncompressed_sample_offset

    local communication_str = ffi.new("struct CommunicationString_t[1]")
    ffi.fill(communication_str, ffi.sizeof(communication_str))
    communication_str[0].m_nMaxLen = 15
    communication_str[0].m_nCurrentLen = 0

    msg[0].data = ffi.cast("void*", communication_str)
    msg[0].format = 0
    msg[0].flags = 63

    iengine.send_net_msg(msg)
    -- print("inetmessage_vtable: " .. tostring(msg[0].inetmessage_vtable))
    -- print("voicedata_vtable: " .. tostring(msg[0].voicedata_vtable))
    -- print("data: " .. tostring(msg[0].data))
    -- print("xuid_low: " .. tostring(msg[0].xuid_low))
    -- print("xuid_high: " .. tostring(msg[0].xuid_high))
    -- print("format: " .. tostring(msg[0].format))
    -- print("sequence_bytes: " .. tostring(msg[0].sequence_bytes))
    -- print("section_number: " .. tostring(msg[0].section_number))
    -- print("uncompressed_sample_offset: " .. tostring(msg[0].uncompressed_sample_offset))
    -- print("cached_size: " .. tostring(msg[0].cached_size))
    -- print("flags: " .. tostring(msg[0].flags))
    -- print("")
end

local function find_duplicate_element(array, divisor)
    local visited_elements = {}

    for current_index = 1, #array do
        local current_element = array[current_index]

        if not visited_elements[current_element] then
            visited_elements[current_element] = true

            for next_index = current_index + 4, #array do
                if current_index % divisor == 0 then
                    if array[next_index] == current_element then
                        return true
                    end
                elseif array[next_index] == current_element then
                    return false
                end
            end
        end
    end

    return false
end
local convert_to_communication_data = function(packet)
    local voice_communication = ffi.new("struct voice_communication_t[1]")
    voice_communication[0].xuid_low = packet.xuid_low
    voice_communication[0].xuid_high = packet.xuid_high
    voice_communication[0].sequence_bytes = packet.sequence_bytes
    voice_communication[0].section_number = packet.section_number
    voice_communication[0].uncompressed_sample_offset = packet.uncompressed_sample_offset
    return voice_communication
end
-- local airflow_packet = ffi.new("struct test_data_t[1]")
-- --57FA to dec
-- airflow_packet[0].id = 0x695B
-- airflow_packet[0].a = 100
-- airflow_packet[0].b = 100
-- airflow_packet[0].c = 100
-- airflow_packet[0].d = 100
-- airflow_packet[0].e = 100
-- airflow_packet[0].f = 100
-- client.register_callback('create_move', function (cmd)
--     if cmd.command_number % 10 == 0 then
        
--     end
-- end)
local voice_data_list = {}
local detector_storage = {
    nl = {
        sig_count = {},
        found = {}
    },
    nw = {},
    pd = {},
    ot = {},
    ft = {},
    pl = {},
    ev = {},
    r7 = {},
    af = {},
    gs = {},
    fl = {},
    we = {},
    pr = {},
}
local icons = {
    af = 2245,
    ev = 2246,
    ft = 2247,
    gs = 2248,
    nl = 2249,
    nw = 2250,
    ot = 2251,
    pd = 2252,
    pl = 2253,
    r7 = 2254,
    fl = 2255,
    we = 2256,
    pr = 2257,
}
---@type table<string, fun(packet: { client: number, audible_mask: number, xuid_low: number, xuid_high: number, voice_data: ffi.cdata*, proximity: boolean, caster: boolean, format: number, sequence_bytes: number, section_number: number, uncompressed_sample_offset: number, has_bits: number }, target: number): boolean?>
local detector_table = {
    nl = function(packet, target)
        if packet.xuid_high == 0 then
            return
        end

        if (detector_storage.fl[target] or 0) > 24 then
            return
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 22)[0])

        if sig == detector_storage.current_signature then
            detector_storage.nl.sig_count[target] = (detector_storage.nl.sig_count[target] or 0) + 1

            if detector_storage.nl.sig_count[target] > 24 then
                detector_storage.nl.found[target] = 1

                return true
            else
                detector_storage.nl.sig_count[target] = nil
            end
        end

        if #detector_storage.nl.found > 3 then
            return false
        end

        if not detector_storage.nl[target] then
            detector_storage.nl[target] = {}
        end

        detector_storage.nl[target][#detector_storage.nl[target] + 1] = packet.xuid_high

        if #detector_storage.nl[target] > 24 then
            if find_duplicate_element(detector_storage.nl[target], 4) and packet.xuid_high ~= 0 then
                detector_storage.current_signature = sig
                detector_storage.nl[target] = {}

                return true
            end

            table.remove(detector_storage.nl[target], 1)
        end

        return false
    end,
    nw = function(packet, target)
        if not detector_storage.nw[target] then
            detector_storage.nw[target] = 0
        end

        if detector_storage.nw[target] > 34 then
            detector_storage.nw[target] = nil
            return true
        elseif packet.xuid_high == 0 then
            detector_storage.nw[target] = detector_storage.nw[target] + 1
        else
            detector_storage.nw[target] = 0
        end

        return false
    end,
    pd = function(packet, target)
        if not detector_storage.pd[target] then
            detector_storage.pd[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.pd[target] > 24 then
            return true
        elseif sig == "695B" or sig == "1B39" then
            detector_storage.pd[target] = detector_storage.pd[target] + 1
        else
            detector_storage.pd[target] = 0
        end

        return false
    end,
    ot = function(packet, target)
        if not detector_storage.ot[target] then
            detector_storage.ot[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.ot[target] > 36 then
            return true
        elseif sig == "57FA" then
            detector_storage.ot[target] = detector_storage.ot[target] + 1
        end

        return false
    end,
    ft = function(packet, target)
        if not detector_storage.ft[target] then
            detector_storage.ft[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.ft[target] > 36 then
            return true
        elseif sig == "7FFA" or sig == "7FFB" then
            detector_storage.ft[target] = detector_storage.ft[target] + 1
        end

        return false
    end,
    pl = function(packet, target)
        if not detector_storage.pl[target] then
            detector_storage.pl[target] = 0
        end

        if detector_storage.pl[target] > 24 then
            return true
        elseif packet.uncompressed_sample_offset == 408409397
            or packet.xuid_low == 907415600
            or packet.xuid_high == 49439746
            or packet.xuid_high == 29713409
            or packet.xuid_high == 38822914 then
            detector_storage.pl[target] = detector_storage.pl[target] + 1
        else
            detector_storage.pl[target] = 0
        end

        return false
    end,
    ev = function(packet, target)
        if not detector_storage.ev[target] then
            detector_storage.ev[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.ev[target] > 36 then
            return true
        elseif sig == "7FFC" or sig == "7FFD" then
            detector_storage.ev[target] = detector_storage.ev[target] + 1
        end

        return false
    end,
    r7 = function(packet, target)
        if not detector_storage.r7[target] then
            detector_storage.r7[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.r7[target] > 24 then
            return true
        elseif sig == "234" or sig == "134" then
            detector_storage.r7[target] = detector_storage.r7[target] + 1
        else
            detector_storage.r7[target] = 0
        end

        return false
    end,
    af = function(packet, target)
        if not detector_storage.af[target] then
            detector_storage.af[target] = 0
        end

        if detector_storage.af[target] > 24 then
            return true
        elseif packet.xuid_low == 3735943921 or packet.xuid_low == 3735924721 then
            detector_storage.af[target] = detector_storage.af[target] + 1
        else
            detector_storage.af[target] = 0
        end

        return false
    end,
    gs = function(packet, target)
        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 22)[0])
        local sequence_bytes = string.sub(packet.sequence_bytes, 1, 4)

        if not detector_storage.gs[target] then
            detector_storage.gs[target] = {
                repeated = 0,
                packet = sig,
                bytes = sequence_bytes
            }
        end

        if sequence_bytes ~= detector_storage.gs[target].bytes and sig ~= detector_storage.gs[target].packet then
            detector_storage.gs[target].packet = sig
            detector_storage.gs[target].bytes = sequence_bytes
            detector_storage.gs[target].repeated = detector_storage.gs[target].repeated + 1
        else
            detector_storage.gs[target].repeated = 0
        end

        if detector_storage.gs[target].repeated >= 36 then
            detector_storage.gs[target] = {
                repeated = 0,
                packet = sig,
                bytes = sequence_bytes
            }

            return true
        end

        return false
    end,
    fl = function(packet, target)
        if not detector_storage.fl[target] then
            detector_storage.fl[target] = 0
        end
        -- local communication = convert_to_communication_data(packet)
        -- local floridahook_info = ffi.cast("struct floridahook_shared_esp_data_t*", communication)[0]
        local id = bit.rshift(bit.band(packet.xuid_low, 0xFF00), 8)
        if detector_storage.fl[target] > 24 then
            return true
        elseif id == 0x66 then
            detector_storage.fl[target] = detector_storage.fl[target] + 1
        else
            detector_storage.fl[target] = 0
        end
    end,
    we = function (packet, target)
        if not detector_storage.we[target] then
            detector_storage.we[target] = 0
        end
        if detector_storage.we[target] > 24 then
            return true
        elseif packet.xuid_low == 3735919089 then
            detector_storage.we[target] = detector_storage.we[target] + 1
        else
            detector_storage.we[target] = 0
        end
    end,
    pr = function (packet, target)
        if not detector_storage.pr[target] then
            detector_storage.pr[target] = 0
        end
        if detector_storage.pr[target] > 24 then
            return true
        elseif bit.band(bit.bxor(bit.band(packet.sequence_bytes, 255), bit.band(bit.rshift(packet.uncompressed_sample_offset, 16), 255)) - bit.rshift(packet.sequence_bytes, 16), 255) == 77 and bit.band(bit.bxor(bit.rshift(packet.sequence_bytes, 16), bit.rshift(packet.sequence_bytes, 8)), 255) >= 1 then
            -- print("prim detected")
            detector_storage.pr[target] = detector_storage.pr[target] + 1
        else
            detector_storage.pr[target] = 0
        end
    end
}
local user_list = {}
local voice_data_process = errors.handler(function(packet)
    if not packet then return end
    local msg = ffi.cast("struct voice_data_t*", packet)
    if not msg then return end
    local entity = entitylist.get_entity_by_index(msg.client + 1)
    if not entity then return end
    local info = entity:get_info()
    if not info then return end
    -- print("client: " .. info.name)
	-- print("xuid_low: " .. tostring(msg.xuid_low))z
	-- print("xuid_high: " .. tostring(msg.xuid_high))
	-- print("sequence_bytes: " .. tostring(msg.sequence_bytes))
	-- print("section_number: " .. tostring(msg.section_number))
	-- print("uncompressed_sample_offset: " .. tostring(msg.uncompressed_sample_offset))
	-- print("format: " .. tostring(msg.format))
	-- print("audible_mask: " .. tostring(msg.audible_mask))
	-- print("proximity: " .. tostring(msg.proximity))
	-- print("caster: " .. tostring(msg.caster))
    -- print("")

    local target = info.user_id
    if not user_list[target] then
        user_list[target] = {}
    end
    local user = user_list[target]

    for cheat_identifier, detect_fn in pairs(detector_table) do
        local cheat = user.cheat
        if detect_fn(msg, target) then
            user.cheat = cheat_identifier

            if cheat ~= cheat_identifier then
                local name = entity:get_info().name
                if name then
                    -- iengine.log({{"[cheat revealer] ", col.red}, {name .. " is using " .. cheat_identifier}})
                end
                if icons[cheat_identifier] then
                    entity:set_rank(icons[cheat_identifier])
                end
            end
        end
    end
end, "features.revealer.process")
cbs.paint(function ()
    for i = 1, #voice_data_list do
        voice_data_process(voice_data_list[i])
    end
    voice_data_list = {}
end)
local voice_data_hook = function (orig, this, msg)
    local voice_data = ffi.new("struct voice_data_t[1]")
    ffi.copy(voice_data, msg, ffi.sizeof("struct voice_data_t"))
    voice_data_list[#voice_data_list + 1] = voice_data
    return orig(this, msg)
end
local voice_data_fn = hooks.jmp2.new("bool(__thiscall*)(void*, struct voice_data_t*)", voice_data_hook, voice_data_msg)
cbs.unload(function()
    if voice_data_fn then
        voice_data_fn:unhook()
    end
end)

end)
__bundle_register("features.create_move_hk", function(require, _LOADED, __bundle_register, __bundle_modules)
local hooks = require("libs.hooks")
local errors = require("libs.error_handler")

end)
__bundle_register("libs.drag", function(require, _LOADED, __bundle_register, __bundle_modules)
local v2 = require("libs.vectors")()
local render = require("libs.render")
local col = require("libs.colors")
require("libs.advanced math")
local modules = require("libs.modules")
ffi.load('user32')
require("libs.types")
ffi.cdef[[
    typedef void* HANDLE;
    HANDLE LoadCursorA(HANDLE, PCSTR);
    typedef struct { long x; long y; } POINT;
]]
local SetCursor = modules.get_function("HANDLE(__stdcall*)(HANDLE)", "user32", "SetCursor")
local ss = engine.get_screen_size()
local input = require("libs.input")
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local drag = {
    ---@type table<string, draggable_t>
    __elements = {},
    __blocked = false,
    ---@param to_pos? vec2_t
    is_hovered = function(pos, size, to_pos)
        local cursor = renderer.get_cursor_pos()
        local from = pos
        local to = to_pos or pos + size
        local distance_from, distance_to = cursor - from, cursor - to

        --!HOVER DEBUG
        -- renderer.rect(from, to, col(255, 255, 255, 127))
        --!HOVER DEBUG

        if distance_from.x > 0 and distance_from.y > 0
            and distance_to.x < 0 and distance_to.y < 0 then
            return true
        end
    end,
    ---@param pos vec2_t
    ---@param size vec2_t
    ---@param alpha number
    highlight = function(pos, size, alpha)
        local from, to = pos, pos + size
        render.rounded_rect(from:round() - v2(3, 3), to:round() + v2(2, 2), col(200, 200, 200, alpha / 3), 3)
        local shine = col.white:alpha(alpha / 25)
        local trans = col.white:alpha(0)

        renderer.rect_filled_fade(from, from + size / 2, trans, trans, shine, trans)
        renderer.rect_filled_fade(from + size / 2, to, shine, trans, trans, trans)
        renderer.rect_filled_fade(v2(from.x + size.x / 2, from.y), from + v2(size.x, size.y / 2), trans, trans, trans, shine)
        renderer.rect_filled_fade(v2(from.x, from.y + size.y / 2), from + v2(size.x / 2, size.y), trans, shine, trans, trans)
    end,
    current_cursor = nil,
}
drag.arrow_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32512))
drag.move_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32646))
drag.hand_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32649))
drag.horizontal_resize_cursor = ffi.C.LoadCursorA(nil, ffi.cast("PCSTR", 32644))
drag.new = errors.handler(function(key, default_pos, pointer)
    if pointer == nil then pointer = true end
    drag.__elements[key] = {
        pos = {
            x = ui.add_slider_float(key .. "__x", key .. "_dx", 0, 1, default_pos.x),
            y = ui.add_slider_float(key .. "__y", key .. "_dy", 0, 1, default_pos.y),
        },
        hovered = false,
        key = key,
        highlight_alpha = 0,
        old_cursor = renderer.get_cursor_pos() / engine.get_screen_size(),
        dragging = false,
        move_cursor = false,
        pointer = pointer
    }
    drag.__elements[key].pos.x:set_visible(false)
    drag.__elements[key].pos.y:set_visible(false)
    return setmetatable(drag.__elements[key], drag.mt)
end, "drag.new")

drag.is_menu_hovered = function()
    local rect = ui.get_menu_rect()
    return drag.is_hovered(v2(rect.x, rect.y), v2(rect.z - rect.x, rect.w - rect.y))
end
---@param from vec2_t
---@param to vec2_t
drag.hover_absolute = function(from, to)
    return drag.is_hovered(from, nil, to)
        and not (drag.is_menu_hovered() and ui.is_visible())
end
---@param size vec2_t
---@param center_x? boolean
drag.hover_fn = function(size, center_x, center_y)
    return function(pos)
        return drag.is_hovered(v2(center_x and pos.x - size.x / 2 or pos.x, center_y and pos.y - size.y / 2 or pos.y) or pos, size)
            and not (drag.is_menu_hovered() and ui.is_visible())
    end
end
drag.block = function()
    drag.__blocked = true
end
drag.mt = {
    ---@class draggable_t
    ---@field pos { x: slider_float_t, y: slider_float_t }
    ---@field key string
    ---@field dragging boolean
    ---@field highlight_alpha number
    ---@field old_cursor vec2_t
    ---@field pointer boolean
    __index = {
        ---@param s draggable_t
        ---@param hover_fn fun(pos: vec2_t): boolean
        ---@param highlight? fun(pos: vec2_t, alpha: number)
        ---@return vec2_t, fun()
        run = errors.handler(function(s, hover_fn, highlight)
            local draggable = ui.is_visible()
            for _, elem in pairs(drag.__elements) do
                if draggable and elem.dragging and elem.key ~= s.key then
                    draggable = false
                end
            end
            local pos = v2(s.pos.x:get_value(), s.pos.y:get_value()):clamp(v2(0, 0), v2(1, 1))
            local pressed = input.is_key_pressed(1)
            local cursor = renderer.get_cursor_pos() / ss

            local transformed_pos = pos * ss
            s.move_cursor = false
            s.hovered = (hover_fn(transformed_pos) or (s.dragging and pressed)) and draggable
            s.highlight_alpha = math.anim(s.highlight_alpha, (not pressed and s.hovered) and 255 or 0)
            local highlight_alpha = math.round(s.highlight_alpha)
            if draggable and s.hovered and not ((s.blocked or drag.__blocked) and not s.dragging) and not (s.key ~= "magnolia" and gui.hovered and not s.dragging) then
                if s.pointer then
                    drag.set_cursor(drag.move_cursor)
                end
                s.move_cursor = true
                if pressed or s.dragging then
                    s.dragging = true
                    pos = (cursor - s.old_cursor + pos):clamp(v2(0, 0), v2(1, 1))
                    s.pos.x:set_value(pos.x) s.pos.y:set_value(pos.y)
                end
            end
            if pressed and (not s.hovered and not s.dragging) then
                s.blocked = true
            end
            if not pressed then
                s.blocked = false
                s.dragging = false
            end

            transformed_pos = pos * ss
            if draggable then
                s.old_cursor = cursor
            end
            return transformed_pos, function()
                if highlight_alpha > 0 and highlight then
                    highlight(transformed_pos, highlight_alpha)
                end
            end
        end, "drag_mt.run"),
        block = function(s)
            s.blocked = true
        end,
    }
}

local set_cursor
local original_set_cursor
local hooks = require("libs.hooks")
local hooked_setcursor = function (original, cursor)
    drag.original_cursor = cursor
    original_set_cursor = original
    -- if drag.current_cursor then
    --     local result = original(drag.current_cursor)
    --     return result
    -- end
    if drag.original_cursor then
        return nil
    end
    return original(cursor)
end
drag.set_cursor = function(cursor)
    drag.current_cursor = cursor
end
-- set_cursor = hooks.jmp2.new("HANDLE(__stdcall*)(HANDLE)", hooked_setcursor, SetCursor)
cbs.paint(errors.handler(function ()
    if not original_set_cursor then return end
    for _, elem in pairs(drag.__elements) do
        if elem.move_cursor and elem.pointer then
            return original_set_cursor(drag.move_cursor)
        end
    end
    if drag.current_cursor then
        local result = original_set_cursor(drag.current_cursor)
        drag.current_cursor = nil
        return result
    end
    return original_set_cursor(drag.original_cursor)
end, "drag.paint"))
cbs.add("unload", function ()
    set_cursor:unhook()
end)

return drag
end)
__bundle_register("libs.input", function(require, _LOADED, __bundle_register, __bundle_modules)
local cbs = require("libs.callbacks")
ffi.cdef([[
    short GetAsyncKeyState(int);
    typedef struct {
        DWORD cbSize;
        DWORD flags;
        void* hCursor;
        POINT ptScreenPos;
    } CURSORINFO;
    bool GetCursorInfo(CURSORINFO*);
    void* GetForegroundWindow();
]])
local click_state = {}
local window_handle = ffi.C.GetForegroundWindow()
local is_cursor_visible = function()
    local cursor = ffi.new("CURSORINFO")
    cursor.cbSize = ffi.sizeof("CURSORINFO")
    ffi.C.GetCursorInfo(cursor)
    return cursor.flags ~= 0
end
local is_window_active = function()
    local focused = ffi.C.GetForegroundWindow() == window_handle
    local inter = ui.is_visible() or not is_cursor_visible()
    return focused and inter
end
local input = {
    ---@param code number
    ---@return boolean
    is_key_pressed = function (code)
        return ffi.C.GetAsyncKeyState(code) ~= 0 and is_window_active()
    end
}
---@param code number
---@return boolean
input.is_key_clicked = function(code)
    local state = input.is_key_pressed(code)
    if click_state[code] == nil then
        click_state[code] = {
            state = state,
            clicked = false,
            time = false,
        }
    end
    return click_state[code].clicked
end
---@param code number
---@return number
input.get_key_pressed_time = function (code)
    if click_state[code] == nil then
        click_state[code] = {
            state = false,
            clicked = false,
            time = false
        }
    end
    if click_state[code].time == false then
        return 0
    end
    return globalvars.get_real_time() - click_state[code].time
end
cbs.paint(function()
    local realtime = globalvars.get_real_time()
    for code, _ in pairs(click_state) do
        local state = input.is_key_pressed(code)
        click_state[code] = {
            state = state,
            clicked = state and not click_state[code].state,
            time = click_state[code].time
        }
        if click_state[code].time == false and state then
            click_state[code].time = realtime
        end
        if not state then
            click_state[code].time = false
        end
    end
end)
return input
end)
__bundle_register("libs.modules", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.types")
ffi.cdef[[
    void* GetModuleHandleA(PCSTR);
    uintptr_t GetProcAddress(void*, PCSTR);
]]
local modules = {}
---@return ffi.ctype*|nil
modules.get_fn_pointer = function(module, name)
    --auto append .dll if there's no extension
    if module:find("%.") == nil then
        module = module .. ".dll"
    end
    local handle = ffi.C.GetModuleHandleA(module)
    if handle == nil then
        return nil
    end
    return ffi.cast("void*", ffi.C.GetProcAddress(handle, name))
end
modules.get_function = function(cast, module, name)
    local ptr = modules.get_fn_pointer(module, name)
    if ptr == nil then
        return nil
    end
    return ffi.cast(cast, ptr)
end
modules.get_fn_from_module_handle = function (cast, handle, name)
    local ptr = ffi.C.GetProcAddress(handle, name)
    if ptr == nil then
        return nil
    end
    return ffi.cast(cast, ptr)
end
return modules
end)
__bundle_register("features.shared", function(require, _LOADED, __bundle_register, __bundle_modules)
local sockets = require("libs.sockets")
local cbs = require("libs.callbacks")
local iengine = require("includes.engine")
local steam = require("libs.steam_api")
local security = require("includes.security")
local errors = require("libs.error_handler")
local delay = require("libs.delay")

local shared = {}
---@class __shared_features_t
---@field logo gui_checkbox_t
shared.elements = {}
shared.features = {}

local last_time_presence = globalvars.get_real_time() + 10
shared.features.presence = function()
    if not sockets.websocket then return end
    last_time_presence = globalvars.get_real_time()
    if security.debug_logs then
        iengine.log("presence called")
    end
    local server_info = iengine.get_server_info()
    if not server_info then return end
    local data = {
        type = "presence",
        steam_id = steam.get_steam_id(),
        ip = server_info.ip,
    }
    sockets.send(data)
end

local player_cache = {}
shared.features.update_players = errors.handler(function ()
    iengine.log("update players")
    if not engine.is_in_game() then return end
    local playerresource = entitylist.get_entities_by_class_id(41)[1]
    if not playerresource then return end
    for cached_steam_id, cached in pairs(player_cache) do
        local entity = entitylist.get_entity_by_steam_id(cached_steam_id)
        if entity then
            iengine.log("update presence on " .. entity:get_info().name)
            local index = entity:get_index()
            if not cached.real_rank then
                player_cache[cached_steam_id].real_rank = playerresource.m_nPersonaDataPublicLevel[index]
            end
            if cached.revoke then
                playerresource.m_nPersonaDataPublicLevel[index] = player_cache[cached_steam_id].real_rank
                player_cache[cached_steam_id] = nil
                break
            end
            playerresource.m_nPersonaDataPublicLevel[index] = 2244
            break
        end
    end
end, "shared.features.update_players")

local last_heartbeat = globalvars.get_real_time()

cbs.paint(function ()
    if not sockets.websocket then return end
    local realtime = globalvars.get_real_time()
    if realtime > last_heartbeat + 20 then
        if security.debug_logs then
            iengine.log("heartbeat called")
        end
        sockets.send({type = "heartbeat"})
        last_heartbeat = realtime
    end
    if not engine.is_in_game() then return end
    if globalvars.get_real_time() - last_time_presence > 120 then
        shared.features.presence()
    end
end)

sockets.add("on_socket_init", function()
    if engine.is_in_game() then return end
    shared.features.presence()
end)


sockets.add("player", function(data)
    local steam_id = data.steam_id
    player_cache[steam_id] = player_cache[steam_id] or {}
    player_cache[steam_id].time = globalvars.get_real_time()
    if data.unload then
        player_cache[steam_id].revoke = true
    end
    shared.features.update_players()
end)

local revoke_players = function ()
    local time = globalvars.get_real_time()
    local revoked = false
    for steam_id, player in pairs(player_cache) do
        if time - player.time > 60 * 3 then
            player_cache[steam_id].revoke = true
            revoked = true
        end
    end
    if revoked then
        shared.features.update_players()
    end
end

local was_connected = false
cbs.paint(function ()
    if not sockets.websocket then return end
    if engine.is_in_game() then
        revoke_players()
        if not was_connected then
            was_connected = true
            shared.features.presence()
            shared.features.update_players()
        end
    else
        if was_connected then
            shared.features.presence()
        end
        was_connected = false
    end
end)

cbs.event("player_spawn", function()
    delay.add(shared.features.update_players, 3000)
end)
cbs.add("unload", function()
    -- if security.debug_logs then
    --     iengine.log("unload")
    -- end
    sockets.send({type = "unload"}, true)
    if not engine.is_in_game() then return end
    for cached_steam_id, _ in pairs(player_cache) do
        player_cache[cached_steam_id].revoke = true
    end
    shared.features.update_players()
end)

return shared
end)
__bundle_register("libs.steam_api", function(require, _LOADED, __bundle_register, __bundle_modules)
local iengine = require("includes.engine")
require("libs.types")
ffi.cdef[[
    void* GetModuleHandleA(PCSTR);
]]
local steam_api = ffi.C.GetModuleHandleA("steam_api.dll")
local steam_context = iengine.get_steam_context()
---@class __steam_api
local raw_steam = {
    User = {
        GetSteamID = "uint64_t(__cdecl*)(void*)"
    }
}
for i_name, i in pairs(raw_steam) do
    for f_name, f_type in pairs(i) do
        local casted_fn = ffi.cast(f_type, ffi.C.GetProcAddress(steam_api, "SteamAPI_ISteam"..i_name.."_"..f_name))
        i[f_name] = function (...)
            if not steam_context[i_name] or steam_context[i_name] == nil then
                error("SteamAPI: "..i_name.." is not initialized")
                return
            end
            return casted_fn(steam_context[i_name], ...)
        end
    end
end

local steam = {}
steam.get_steam_id = function ()
    local result = tostring(raw_steam.User.GetSteamID())
    return result:sub(1, #result-3)
end

return steam
end)
__bundle_register("libs.ragebot_lib", function(require, _LOADED, __bundle_register, __bundle_modules)
local cbs = require("libs.callbacks")
local set = require("libs.set")
local rage_weapon_groups = {
    "pistols",
    "deagle",
    "revolver",
    "smg",
    "rifle",
    "shotguns",
    "scout",
    "auto",
    "awp",
    "taser",
}
local rage_weapon_groups_set = set(rage_weapon_groups)

---@return string?
ragebot.get_active_weapon_group = function()
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    local weapon = lp:get_weapon()
    if not weapon then return end
    return weapon.group
end
do
    local hitchance_backups = {}
    local hitchance_override_value = nil
    local is_hitchance_overriden = false
    ragebot.override_hitchance = function(hitchance)
        if not ui.is_visible() then
            hitchance_override_value = hitchance
        end
    end
    cbs.create_move(function (cmd)
        if not is_hitchance_overriden then
            for _, group in pairs(rage_weapon_groups) do
                hitchance_backups[group] = ui.get_slider_int("rage_"..group.."_hitchance"):get_value()
            end
        end
        if hitchance_override_value then
            is_hitchance_overriden = true
            local active_weapon_group = ragebot.get_active_weapon_group()
            if active_weapon_group and rage_weapon_groups_set[active_weapon_group] then
                ui.get_slider_int("rage_"..active_weapon_group.."_hitchance"):set_value(hitchance_override_value)
            end
        else
            is_hitchance_overriden = false
            for group, value in pairs(hitchance_backups) do
                ui.get_slider_int("rage_"..group.."_hitchance"):set_value(value)
            end
        end
        hitchance_override_value = nil
    end)
end
do
    local double_tap = ui.get_check_box("rage_doubletap")
    local double_tap_bind = ui.get_key_bind("rage_doubletap_bind")
    local hide_shots = ui.get_check_box("rage_hide_shots")
    local hide_shots_bind = ui.get_key_bind("rage_hide_shots_bind")
    local fake_duck = ui.get_check_box("antihit_fakeduck")
    local fake_duck_bind = ui.get_key_bind("antihit_fakeduck_bind")
    ragebot.is_charged = function()
        if fake_duck:get_value() and fake_duck_bind:is_active() then return false end
        return (double_tap:get_value() and double_tap_bind:is_active()) or (hide_shots:get_value() and hide_shots_bind:is_active())
    end
end
-- do
--     local fakelag_limit = ui.get_slider_int("antihit_fakelag_limit")
--     local fakelag_disablers = ui.get_multi_combo_box("antihit_fakelag_disablers")
--     local fakelag_triggers = ui.get_multi_combo_box("antihit_fakelag_triggers")
--     local fakelag_trigger_limit = ui.get_slider_int("antihit_fakelag_trigger_limit")
--     ragebot.get_current_fakelag = function()

--     end
-- end
end)
__bundle_register("includes.gui.header", function(require, _LOADED, __bundle_register, __bundle_modules)
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
local colors = require("includes.colors")
local security = require("includes.security")
local label_t = require("includes.gui.label")


local header = {
    ---@param pos vec2_t
    ---@param input_allowed boolean
    tabs = function (pos, input_allowed)
        local alpha = gui.anims.main_alpha()
        for _, v in pairs(gui.elements) do
            local size = v:draw(pos, alpha, input_allowed)
            pos = pos + v2(size.x + 10, 0)
        end
    end,
    anims = anims.new({
        avatar_alpha = 0,
        hover = 0,
    }),
    avatar_texture = nil,
}
local expiration_label ---@type gui_label_t
local discord_username_label ---@type gui_label_t
local dummy_options = label_t.new("header"):options(function ()
    expiration_label = gui.label("Expires: Never")
    discord_username_label = gui.label("Discord: unknown")
end)
---@param pos vec2_t
---@param input_allowed boolean
header.user = errors.handler(function (pos, input_allowed)
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
    local hovered = input_allowed and
        (drag.hover_absolute(normalized_text_pos - v2(2, 0), v2(avatar_pos.x, normalized_text_pos.y + text_size.y)) or
        drag.hover_absolute(avatar_pos - v2(1, 1), avatar_pos + avatar_size + v2(1, 1)))
    if hovered then
        gui.drag:block()
        header.anims.hover(175)
        drag.set_cursor(drag.hand_cursor)
    else
        header.anims.hover(255)
    end
    dummy_options.anims.alpha(dummy_options.open and 255 or 0)
    local seconds_difference = security.sub_expires - os.time()
    local expiration = "Never"
    if security.sub_expires ~= -1 then
        expiration = ""
        local minutes = math.max(math.floor((seconds_difference) / 60), 0)
        --if more than 1 day 
        if minutes > 60*24 then
            local days = math.max(math.floor(minutes / 60 / 24), 1)
            expiration = expiration .. days .. "d "
        elseif minutes > 60 then
            local hours = math.max(math.floor(minutes / 60), 1)
            expiration = expiration .. hours .. "h "
        else
            expiration = expiration .. minutes .. "m "
        end
    end
    expiration_label.name = "Expires: " .. expiration
    if security.discord_username and discord_username_label.name == "Discord: unknown" then
        discord_username_label.name = "Discord: " .. security.discord_username
        discord_username_label.size.x = 0
    end
    if hovered and input.is_key_clicked(1) then
        click_effect.add()
        header.open()
    end
end, "header.user")

header.open = errors.handler(function()
    if not dummy_options.open then
        dummy_options.pos = renderer.get_cursor_pos()
    end
    dummy_options.open = true
    -- dummy_options
end, "header.open")
header.get_avatar = errors.handler(function ()
    -- if gui.anims.main_alpha() ~= 255 then return end
    if header.avatar_texture then return end
    if security.debug then return end
    once(function ()
        http.download("https://pleasant-build-r39zc.cloud.serverless.com/avatar_round/s/" .. client.get_username(), nil, function(path)
            header.avatar_texture = renderer.setup_texture(path)
        end)
    end, "get_avatar")
end, "header.get_avatar")
header.open_link = function()
    win32.open_url("https://nixware.uk.ms/profile/" .. client.get_username())
end

---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
header.draw = errors.handler(function (pos, alpha, input_allowed)
    header.get_avatar()
    local icon_padding = 14
    local icon_pos = pos + v2(icon_padding, icon_padding - 3)
    render.text("A", fonts.logo_shadow, icon_pos - v2(2, 2), colors.magnolia:alpha(alpha):salpha(50))
    render.text("A", fonts.logo, icon_pos, colors.magnolia:alpha(alpha))
    local center_after_icon_pos = icon_pos + v2(fonts.logo.size + icon_padding, fonts.logo.size / 2)
    local line_size = 14
    local line_start_pos = center_after_icon_pos - v2(0, line_size / 2 - 4)
    renderer.line(line_start_pos, line_start_pos + v2(0, line_size / 2), col.white:alpha(20):salpha(alpha))


    local tab_icon_pos = center_after_icon_pos + v2(icon_padding, 0)
    header.tabs(tab_icon_pos, input_allowed)
    header.user(v2(pos.x + gui.size.x - icon_padding, tab_icon_pos.y), input_allowed)
end, "header.draw")

---@param alpha number
header.draw_popout = errors.handler(function(alpha)
    dummy_options:draw(alpha)
end, "header.draw_popout")

header.is_popout_open = function()
    return dummy_options.open
end

return header
end)
__bundle_register("includes.gui.label", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")
local element_t = require("includes.gui.element")
local inline_t = require("includes.gui.inline")
local colors = require("includes.colors")
local cbs = require("libs.callbacks")
local options_t = require("includes.gui.options")

local label_t = { }
---@class gui_label_t : gui_element_class
---@field inline gui_options_t[]
local label_mt = {
    master = element_t.master,
    options = options_t.new
}
---@param self gui_checkbox_t
---@param pos vec2_t
---@param alpha number
---@param width number
---@param input_allowed boolean
label_mt.draw = errors.handler(function (self, pos, alpha, width, input_allowed)
    -- renderer.rect(pos, pos + v2(width, s.size.y), col.white:alpha(alpha))
    local text_size = render.text_size(fonts.label, self.name)
    render.text(self.name, fonts.menu, pos + v2(1, 2), col.black:alpha(alpha / 4))
    render.text(self.name, fonts.label, pos + v2(0, 1), col.white:alpha(alpha / 1.25))
    inline_t.draw(self, pos, alpha, width, input_allowed)
    if self.size.x == 0 then
        self.size.x = text_size.x + inline_t.calculate_size(self)
    end
end, "label_t.draw")

label_t.new = errors.handler(function (name)
    -- local path = gui.get_path(name)
    local c = setmetatable({
        name = name,
        anims = anims.new({
            alpha = 255,
        }),
        inline = {},
        size = v2(0, 18),
    }, { __index = label_mt })
    return c
end, "label_t.new")
---@param name string
---@return gui_label_t
gui.label = function(name)
    return gui.add_element(label_t.new(name))
end

return label_t
end)
__bundle_register("includes.gui.options", function(require, _LOADED, __bundle_register, __bundle_modules)
local v2 = require("libs.vectors")()
local col = require("libs.colors")
local render = require("libs.render")
local fonts = require("includes.gui.fonts")
local anims = require("libs.anims")
local drag = require("libs.drag")
local errors = require("libs.error_handler")
local input = require("libs.input")
local column_t = require("includes.gui.column")
local click_effect = require("includes.gui.click_effect")
local cbs = require("libs.callbacks")

local options_t = {}

---@class gui_options_t
---@field anims __anims_mt
---@field columns gui_column_t[]
---@field pos vec2_t
---@field open boolean
---@field parent gui_checkbox_t
---@field master fun(self: gui_options_t, fn_or_func: gui_checkbox_t|fun(): boolean): gui_options_t
local options_mt = {
    size = v2(18, 18),
    ---@param self gui_options_t
    master = function(self, fn_or_func)
        return self.parent:master(fn_or_func)
    end
}

---@param self gui_options_t
---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
options_mt.inline_draw = errors.handler(function(self, pos, alpha, input_allowed)
    local _, text_size = render.sized_text(function ()
        return render.text("E", fonts.menu_icons, pos - v2(2, 1), col.white:alpha(alpha):salpha(self.anims.hover()), render.flags.TEXT_SIZE)
    end, fonts.menu_icons, 19)
    ---@cast text_size vec2_t
    local hovered = input_allowed and drag.hover_absolute(pos - v2(0, 1), pos + text_size + v2(0, 2))
    self.anims.hover((hovered or self.open) and 255 or 100)
    self.anims.alpha(self.open and 255 or 0)
    if hovered then
        drag.set_cursor(drag.hand_cursor)
        if input.is_key_clicked(1) then
            click_effect.add()
            if not self.open then
                self.pos = renderer.get_cursor_pos()
            end
            self.open = true
        end
    end
end, "options_mt.inline_draw")
local container_t
---@param self gui_options_t
---@param alpha number
options_mt.draw = errors.handler(function(self, alpha)
    if not container_t then
        container_t = require("includes.gui.container")
    end
    local alpha_anim = self.anims.alpha()
    local open_alpha = alpha_anim * (alpha / 255)
    if open_alpha > 0 then
        local input_allowed = self.open and not gui.is_another_dragging()
        local size = v2((#self.columns + 1) * gui.paddings.options_container_padding, 0)
        if self.columns then
            for _, column in pairs(self.columns) do
                local col_size = column:get_size()
                if col_size.x < 100 then
                    col_size.x = 100
                end
                size.x = size.x + col_size.x
                if col_size.y > size.y then
                    size.y = col_size.y
                end
                for _, element in pairs(column.elements) do
                    if element.size.x == 0 then
                        --*HACK: this is a hack to make the options menu wait for the element to calculate its size before drawing it
                        open_alpha = 0.01
                    end
                end
                input_allowed = input_allowed and column:input_allowed()
            end
        end
        size = v2(size.x + 1, gui.paddings.options_container_padding * 2 + size.y + 1)

        local pos = self.pos - v2(size.x / 2, 0)
        local to = pos + size

        local hovered = drag.hover_absolute(pos, to)
        if hovered and alpha_anim > 127 then
            gui.hovered = true
        end
        if input_allowed and alpha_anim > 127 and not hovered and input.is_key_clicked(1) then
            self.open = false
        end

        container_t.draw_background(pos, to, open_alpha, 253)

        if self.columns then
            local add_pos = v2(gui.paddings.options_container_padding + 1, gui.paddings.options_container_padding + 1)
            for i = 1, #self.columns do
                local column = self.columns[i]
                container_t.draw_elements(column.elements, pos + add_pos, math.round(column.size.x), open_alpha, input_allowed)

                --!DEBUG
                -- renderer.rect(s.pos + add_pos, s.pos + add_pos + column.size, col.black:alpha(open_alpha))
                --!DEBUG

                add_pos.x = column.size.x + add_pos.x + gui.paddings.options_container_padding
            end
        end
    end
end, "options_mt.draw")
---@param fn fun(cmd: usercmd_t, el: gui_options_t)
---@return gui_options_t
options_mt.create_move = function (self, fn)
    cbs.create_move(function(cmd)
        if self.parent.value and self.parent:value() or not self.parent.value then fn(cmd, self) end
    end, self.parent.name .. ".create_move")
    return self
end
---@param fn fun(el: gui_options_t)
---@return gui_options_t
options_mt.paint = function (self, fn)
    cbs.paint(function()
        if self.parent.value and self.parent:value() or not self.parent.value then fn(self) end
    end, self.parent.name .. ".paint")
    return self
end
---@param fn fun(el: gui_options_t)
---@return gui_options_t
options_mt.update = function (self, fn)
    cbs.paint(function ()
        local value = self.parent:value()
        if value ~= self.parent.old_value then
            fn(self)
        end
        self.parent.old_value = value
    end, self.parent.name .. ".update")
    cbs.unload(function ()
        self.parent:value(false)
        fn(self)
    end, self.parent.name .. ".update")
    return self
end

---@param self gui_options_t
---@param value? boolean
---@return boolean
options_mt.value = function (self, value)
    return self.parent:value(value)
end

---@param self gui_options_t
---@param name string
---@return gui_element_t?
options_mt.__get = function (self, name)
    for _, column in pairs(self.columns) do
        for _, element in pairs(column.elements) do
            if element.name == name then
                return element
            end
        end
    end
    error("couldn't find element with name '" .. name .. "'")
end
---@param name string
---@return gui_checkbox_t
options_mt.get_checkbox = function (self, name)
    ---@diagnostic disable-next-line: return-type-mismatch
    return self:__get(name)
end
---@param name string
---@return gui_options_t?
options_mt.get_options = function (self, name)
    local el = self:__get(name)
    if not el then return end
    for i = 1, #el.inline do
        if el.inline[i].parent then
            return el.inline[i]
        end
    end
    ---@diagnostic disable-next-line: return-type-mismatch
end
---@param name string
---@return gui_slider_t
options_mt.get_slider = function (self, name)
    ---@diagnostic disable-next-line: return-type-mismatch
    return self:__get(name)
end
---@param name string
---@return gui_dropdown_t
options_mt.get_dropdown = function (self, name)
    ---@diagnostic disable-next-line: return-type-mismatch
    return self:__get(name)
end

---@param element gui_checkbox_t|gui_label_t 
---@param options fun()
---@return gui_options_t
options_t.new = errors.handler(function (element, options)
    local t = setmetatable({
        parent = element,
        columns = {
            column_t.new(),
        },
        anims = anims.new({
            hover = 100,
            enabled = 0,
            alpha = 0,
        }),
        path = gui.get_path(element.name),
        pos = v2(0, 0),
        open = false,
    }, { __index = options_mt })
    element.inline[#element.inline+1] = t
    local old_options = gui.current_options
    gui.current_options = t
    options()
    gui.current_options = old_options
    return t
end, "options_t.new")

return options_t
end)
__bundle_register("includes.gui.container", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local errors = require("libs.error_handler")
require("includes.gui.checkbox")
require("includes.gui.dropdown")
require("includes.gui.slider")
require("includes.gui.label")
local fonts  = require("includes.gui.fonts")
local element_t = require("includes.gui.element")
local colors = require("includes.colors")


---@class gui_container_t
local container_t = {}
---@param from vec2_t
---@param to vec2_t
---@param alpha number
---@param background_alpha? number
container_t.draw_background = errors.handler(function(from, to, alpha, background_alpha)
    local background_color = colors.container_bg:alpha(background_alpha or 200):salpha(alpha)
    render.rounded_rect(from + v2(1, 1), to, background_color, 7.5, true)
    render.rounded_rect(from, to, col.white:alpha(alpha):salpha(30), 7.5, false)
end)

---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
container_t.draw = errors.handler(function (pos, alpha, input_allowed)
    local width = gui.paddings.subtab_list_width
    local menu_padding = gui.paddings.menu_padding
    local padding = 34
    local from = pos + v2(width + menu_padding, 64 - padding / 2 + 1)
    local to = pos + v2(gui.size.x - 1, gui.size.y - 1)
    local container_width = to.x - from.x - menu_padding
    container_t.draw_background(from, to, alpha)
    for i = 1, #gui.elements do
        local tab = gui.elements[i]
        local tab_alpha = tab.anims.alpha()
        render.text(tab.icon, fonts.title_icon, from + v2(23, menu_padding), colors.magnolia:alpha(tab_alpha):salpha(alpha), render.flags.X_ALIGN)
        local text_pos = from + v2(40, 13)
        render.text(tab.name, fonts.tab_title, text_pos, col.white:alpha(tab_alpha):salpha(alpha), render.flags.TEXT_SIZE)
        if tab_alpha > 0 then
            for s = 1, #tab.subtabs do
                local subtab = tab.subtabs[s]
                local subtab_alpha = subtab.anims.alpha()
                if subtab_alpha > 0 then
                    container_t.draw_columns(subtab.columns, from + v2(menu_padding, menu_padding * 3 + 6),
                        container_width,
                        alpha * tab_alpha / 255 * subtab_alpha / 255,
                        gui.active_tab == subtab.tab and subtab.active and input_allowed)
                    render.text(subtab.name:upper(), fonts.subtab_title, text_pos + v2(0, 13), col.white:alpha(subtab_alpha / 2):salpha(alpha):salpha(tab_alpha))
                end
            end
        end
    end
end, "container_t.draw")

---@param elements gui_element_t[]
---@param pos vec2_t
---@param width number
---@param alpha number
---@param input_allowed boolean
container_t.draw_elements = errors.handler(function(elements, pos, width, alpha, input_allowed)
    local padding = 6
    local add_pos = v2(0, 0)
    if alpha > 0 then
        for e = 1, #elements do
            local element = elements[e]
            local p = (pos + add_pos):round() ---@type vec2_t
            local element_alpha, element_input = element_t.animate_master(element)
            element_alpha = element_alpha / 255
            element_input = element_input and element_alpha > 0
            add_pos.y = add_pos.y + (element.size.y + padding) * element_alpha
            element_alpha = element_alpha * alpha
            if element_alpha > 0 or alpha == 0.01 then
                element:draw(p, element_alpha, width, input_allowed and element_input)
            end
        end
    end
end, "container_t.draw_elements")

---@param columns gui_column_t[]
---@param pos vec2_t
---@param width number
---@param alpha number
---@param input_allowed boolean
container_t.draw_columns = errors.handler(function(columns, pos, width, alpha, input_allowed)
    local column_width = math.round(width / #columns - gui.paddings.menu_padding)
    for i = 1, #columns do
        local column = columns[i]
        local add_pos = v2(width / #columns * (i - 1), 0):round()
        container_t.draw_elements(column.elements, pos + add_pos, column_width, alpha, input_allowed)

        --!DEBUG
        -- renderer.rect(pos + add_pos, pos + add_pos + v2(column_width, 100), col.black:alpha(alpha))
        --!DEBUG
    end
end, "container_t.draw_columns")

return container_t
end)
__bundle_register("includes.gui.element", function(require, _LOADED, __bundle_register, __bundle_modules)
---@alias gui_element_draw_fn fun(self: any, pos: vec2_t, alpha: number, width: number, input_allowed: boolean)

---@class gui_element_class
---@field name string
---@field path string
---@field anims __anims_mt
---@field size vec2_t
---@field master_object? { el?: checkbox_t, fn: fun(): boolean }
local element_t = {}

---@param s gui_element_t
---@param master gui_checkbox_t|fun(): boolean
element_t.master = function(s, master)
    s.master_object = {}
    if type(master) == "function" then
        s.master_object.fn = master
    elseif master.el then
        s.master_object.el = master.el
    end
    s.anims.alpha.value = 0
    return s
end
---@param s gui_element_t
element_t.animate_master = function(s)
    if not s.master_object then return 255, true end

    local value = false
    if s.master_object.el then
        value = s.master_object.el:get_value()
    elseif s.master_object.fn then
        value = s.master_object.fn()
    end
    return s.anims.alpha(value and 255 or 0), value
end

return element_t
end)
__bundle_register("includes.gui.slider", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")
local element_t = require("includes.gui.element")
local colors = require("includes.colors")

local slider_t = { }

---@class gui_slider_t : gui_element_class
---@field active boolean
---@field el slider_int_t|slider_float_t
---@field float boolean
---@field float_accuracy number
---@field min number
---@field max number
local slider_mt = {
    master = element_t.master,
}

---@param self gui_slider_t
---@param pos vec2_t
---@param alpha number
---@param width number
---@param input_allowed boolean
slider_mt.draw = errors.handler(function (self, pos, alpha, width, input_allowed)
    local value = math.clamp(self:value(), self.min, self.max)
    local value_anim = self.anims.value(value * 10) / 10
    local value_str = self.float and string.format("%."..self.float_accuracy.."f", value) or tostring(value)
    local active_anim = self.anims.active()
    local hover_anim = self.anims.hover()
    local height = math.round((self.size.y) + math.round(self.anims.active() / 255 * 3) * 2)
    local size = v2(width, height)
    local from = pos + v2(0, self.size.y / 2 - size.y / 2)
    local to = from + v2(size.x, size.y)
    local progress = (value_anim - self.min) / (self.max - self.min)
    local progress_offset = v2(math.round(progress * width), 0)
    local clamped_x = math.max(from.x + progress_offset.x - 1, from.x + 1)

    if self.size.x == 0 then
        local max_width = 28 + render.text_size(fonts.menu, self.name).x
        local longest_value = math.max(math.abs(self.min), math.abs(self.max))
        local numbers_count = #tostring(longest_value)
        max_width = max_width + render.text_size(fonts.menu, string.rep("0", numbers_count)).x
        self.size.x = max_width
    end

    local border_color = colors.magnolia_tinted:fade(colors.magnolia, hover_anim / 255):alpha(alpha)
    local active_color = colors.magnolia:alpha(alpha)


    --borders of slider progress
    renderer.rect_filled(v2(clamped_x, from.y), v2(to.x - 1, from.y + 1), border_color)
    renderer.rect_filled(v2(clamped_x, to.y - 1), v2(to.x - 1, to.y), border_color)

    --slider progress
    renderer.rect_filled(v2(from.x, from.y + 1), v2(from.x + progress_offset.x, to.y - 1), active_color)

    local left_color, right_color = colors.magnolia:alpha(alpha), colors.magnolia:alpha(alpha)

    if progress_offset.x > 0 then
        --top and bottom borders of slider progress
        renderer.rect_filled(v2(from.x + 1, from.y), v2(clamped_x, from.y + 1), active_color)
        renderer.rect_filled(v2(from.x + 1, to.y - 1), v2(clamped_x, to.y), active_color)
    else
        left_color = border_color
        --left slider progress border
        renderer.rect_filled(v2(from.x, from.y + 1), v2(from.x + 1, to.y - 1), border_color)
    end

    if progress_offset.x < width then
        right_color = border_color
        --slider background
        renderer.rect_filled(v2(math.max(from.x + progress_offset.x, from.x + 1), from.y + 1), to - v2(1, 1), col.gray:alpha(alpha))
        --right slider progress border
        renderer.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), border_color)
    end

    --antialias dots on each corner of the slider
    left_color = left_color:salpha(127)
    right_color = right_color:salpha(127)
    renderer.rect_filled(v2(from.x, from.y), v2(from.x + 1, from.y + 1), left_color)
    renderer.rect_filled(v2(to.x - 1, from.y), v2(to.x, from.y + 1), right_color)
    renderer.rect_filled(v2(from.x, to.y - 1), v2(from.x + 1, to.y), left_color)
    renderer.rect_filled(v2(to.x - 1, to.y - 1), v2(to.x, to.y), right_color)

    local text_padding_anim = math.round(1 * (active_anim / 255))
    local text_padding = v2(4 - text_padding_anim, 1 - text_padding_anim)

    local font_size = fonts.menu.size - (active_anim / 255 * 1.6)

    local outline_color = col.black:alpha(75)
    render.sized_text(function()
        render.outline_text(self.name, fonts.slider, from + text_padding, col.white:alpha(alpha), 0, outline_color)
        return render.outline_text(value_str, fonts.slider, v2(to.x, from.y) - v2(text_padding.x, -text_padding.y),
        col.white:alpha(alpha), render.flags.RIGHT_ALIGN, outline_color)
    end, fonts.slider, font_size)

    if active_anim > 0 then
        local color = col.white:alpha(alpha):salpha(active_anim)
        render.outline_text(tostring(self.min), fonts.slider_small, v2(from.x + 3, to.y - 10), color, 0, outline_color)
        render.outline_text(tostring(self.max), fonts.slider_small, v2(to.x - 3, to.y - 10), color, render.flags.RIGHT_ALIGN, outline_color)
    end

    local hovered = input_allowed and drag.hover_absolute(from, to)
    if hovered then
        drag.set_cursor(drag.horizontal_resize_cursor)
        gui.drag:block()
        local change_value = 1
        if input.is_key_pressed(16) then
            change_value = 10
        end
        if input.is_key_pressed(18) and self.float then
            change_value = 0.1
        end
        if input.is_key_clicked(37) then
            self.el:set_value(math.max(self.min, value - change_value))
        end
        if input.is_key_clicked(39) then
            self.el:set_value(math.min(self.max, value + change_value))
        end
    end
    local is_pressed = input.is_key_pressed(1)
    local active = (hovered and input.is_key_clicked(1)) or self.active
    self.anims.hover((active or hovered) and 255 or 0)
    self.anims.active(active and 255 or 0)

    if not is_pressed then
        self.active = false
        active = false
    end

    if active then
        drag.set_cursor(drag.horizontal_resize_cursor)
        gui.drag:block()
        if not self.active then
            click_effect.add()
        end
        self.active = true
        local mouse_pos = renderer.get_cursor_pos()
        local new_progress = (mouse_pos.x - from.x - 1) / (to.x - from.x - 2)
        local new_value = math.clamp(self.min + (self.max - self.min) * new_progress, self.min, self.max)
        if self.float then
            local accuracy = math.pow(10, self.float_accuracy)
            new_value = math.round(new_value * accuracy) / accuracy
        end
        self.el:set_value(new_value)
    end
end, "slider_t.draw")

slider_mt.value = function (self)
    return self.el:get_value()
end

slider_t.new = errors.handler(function (name, min, max, float_accuracy, value)
    if value == nil then
        value = min
    end
    float_accuracy = float_accuracy or 0
    if float_accuracy == true then
        float_accuracy = 1
    end
    local path = gui.get_path(name)
    local c = setmetatable({
        name = name,
        default_value = value,
        el = float_accuracy > 0
            and ui.add_slider_float(path, path, min, max, value)
            or ui.add_slider_int(path, path, min, max, value),
        float = float_accuracy > 0 or false,
        float_accuracy = float_accuracy,
        min = min,
        max = max,
        anims = anims.new({
            alpha = 255,
            hover = 0,
            active = 0,
            value = value * 10,
        }),
        active = false,
        size = v2(0, 18),
    }, { __index = slider_mt })
    c.el:set_visible(false)
    return c
end, "slider_t.new")
---@param name string
---@param min number
---@param max number
---@param float? number|boolean
---@param value? number
---@return gui_checkbox_t
gui.slider = function(name, min, max, float, value)
    return gui.add_element(slider_t.new(name, min, max, float, value))
end
end)
__bundle_register("includes.gui.click_effect", function(require, _LOADED, __bundle_register, __bundle_modules)
local anims = require("libs.anims")
local col = require("libs.colors")
local click_effects = {
    ---@type { pos: vec2_t, anims: __anims_mt }[]
    list = {},
}
click_effects.draw = function()
    for i = #click_effects.list, 1, -1 do
        local effect = click_effects.list[i]
        if effect then
            local alpha = effect.anims.alpha(0)
            local size = effect.anims.size(12)
            if alpha <= 0 then
                table.remove(click_effects.list, i)
            else
                renderer.circle(effect.pos, size, 15, true, col(255, 255, 255, alpha))
            end
        end
    end
end
click_effects.add = function()
    local pos = renderer.get_cursor_pos()
    table.insert(click_effects.list, {
        pos = pos,
        anims = anims.new({
            alpha = 175,
            size = 0,
        }),
    })
end

return click_effects
end)
__bundle_register("includes.gui.dropdown", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")
local element_t = require("includes.gui.element")
local colors = require("includes.colors")
local cbs = require("libs.callbacks")


---@class gui_dropdown_t : gui_element_class
---@field el multi_combo_box_t|combo_box_t
---@field old_value number
---@field multi boolean
---@field open boolean
---@field pos vec2_t
---@field width number
---@field values string[]
---@field values_data { anims: __anims_mt, text_size: vec2_t }[]
local dropdown_mt = {
    master = element_t.master,
}

local trim_last_space = function(str)
    if str:sub(-1) == " " then
        str = str:sub(1, -2)
    end
    return str
end

---@param self gui_dropdown_t
---@param alpha number
---@param width number
---@param input_allowed boolean
dropdown_mt.draw = errors.handler(function(self, pos, alpha, width, input_allowed)
    local size = v2(width, 32)
    local from = pos + v2(0, self.size.y - size.y)
    local to = from + v2(size.x, size.y)
    renderer.rect_filled(from + v2(1, 1), to - v2(1, 1), col.gray:alpha(alpha))
    self.width = width
    do
        -- local text_padding = 10
        -- local text_pos, text_size = render.text(self.name, fonts.menu_small, pos + v2(text_padding + 1, -1), col.black:alpha(alpha), render.flags.TEXT_SIZE)
        -- -@cast text_size vec2_t
        -- render.text(self.name, fonts.menu_small, text_pos - v2(1, 1), col.white:alpha(alpha))
        -- local border_color = colors.magnolia_tinted:alpha(alpha) --:fade(colors.magnolia, hover_anim / 255)
        -- renderer.rect_filled(from + v2(1, 0), v2(text_pos.x - 4, from.y + 1), border_color)
        -- renderer.rect_filled(v2(text_pos.x + text_size.x + 3, from.y), v2(to.x - 1, from.y + 1), border_color)
        -- renderer.rect_filled(from + v2(0, 1), v2(from.x + 1, to.y - 1), border_color)
        -- renderer.rect_filled(v2(from.x + 1, to.y - 1), to - v2(1, 0), border_color)
        -- renderer.rect_filled(v2(to.x - 1, from.y + 1), to - v2(0, 1), border_color)
    end
    local hovered = input_allowed and drag.hover_absolute(from, to)
    local hover_anim = self.anims.hover((hovered or self.open) and 255 or 0)
    self.pos = pos
    self.anims.active(self.open and 255 or 0)
    if hovered then
        if input.is_key_clicked(1) then
            gui.drag:block()
            click_effect.add()
            self.open = true
        end
        drag.set_cursor(drag.hand_cursor)
    end
    if hovered or self.open and not self.multi then
        local el = self.el ---@type combo_box_t
        local can_fast_scroll = globalvars.get_frame_count() % 7 == 0
        local down_arrow = input.is_key_clicked(40) or (input.get_key_pressed_time(40) > 0.3 and can_fast_scroll)
        local up_arrow = not down_arrow and (input.is_key_clicked(38) or (input.get_key_pressed_time(38) > 0.3 and can_fast_scroll))
        if down_arrow or up_arrow then
            --increase or decrease the index
            el:set_value(math.clamp(el:get_value() + (down_arrow and 1 or -1), 0, #self.values - 1))
        end
    end
    do
        local text_pos = pos + v2(5, 3)
        local border_color = colors.magnolia_tinted:fade(colors.magnolia, hover_anim / 255):alpha(alpha)
        render.smoothed_rect(from, to, border_color)
        -- render.text(self.name, fonts.menu_small, text_pos + v2(1, 1), col.black:alpha(alpha))
        render.text(self.name:upper(), fonts.subtab_title, text_pos, col.white:alpha(alpha / 2))
    end
    if self.size.x == 0 then
        local max_width = 0
        for i = 1, #self.values do
            local text_size = render.text_size(fonts.menu, self.values[i])
            if max_width < text_size.x then
                max_width = text_size.x
            end
            self.size.x = max_width + 22
        end
    end
    local el = self.el
    local text_pos = from + v2(5, size.y / 2 - 3)
    local shadow_color = col.black:alpha(alpha)
    local text_color = col.white:alpha(alpha)
    if self.multi then
        local comma_width = render.text_size(fonts.menu, ", ").x
        local ellipsis_width = render.text_size(fonts.menu, "...").x
        local elements_after_width = 10 + ellipsis_width * 2 + 6
        local x = 0
        local place_comma = false
        ---@cast el multi_combo_box_t
        local last_active_index
        local has_active_been_trimmed = false
        local has_any_been_trimmed = false
        for i = 1, #self.values do
            local active = el:get_value(i-1)
            if active then
                last_active_index = i
            end
        end
        local none_active_alpha = self.anims.none_active(not last_active_index and 255 or 0)
        if none_active_alpha > 0 then
            render.text("None", fonts.menu, text_pos + v2(1, 1), shadow_color:salpha(none_active_alpha))
            render.text("None", fonts.menu, text_pos, text_color:salpha(none_active_alpha))
        end
        for i = 1, #self.values do
            local active = el:get_value(i-1)
            if self.values_data[i].text_size.x == 0 then
                self.values_data[i].text_size = render.text_size(fonts.menu, self.values[i])
            end
            local value_width = (self.values_data[i].text_size.x)
            local out_of_bounds = text_pos.x + x > to.x - 4
            local value_alpha = self.values_data[i].anims.alpha((active and not out_of_bounds and not has_active_been_trimmed) and 255 or 0)
            -- self.values_data[i].anims.active(active and 255 or 0)
            if value_alpha > 0 then
                local elements_after = last_active_index and (last_active_index > i)
                local name = self.values[i]
                if place_comma then
                    name = ", " .. name
                    value_width = value_width + comma_width * (value_alpha / 255)
                end
                local value_pos = v2(text_pos.x + x, text_pos.y)
                if value_pos.x + value_width > to.x - elements_after_width and elements_after then
                    local current_width = value_width
                    while value_pos.x + current_width > to.x - elements_after_width do
                        name = name:sub(1, -2)
                        if name == "" then break end
                        current_width = render.text_size(fonts.menu, name).x
                    end
                    name = trim_last_space(name)
                    if name == "," then
                        name = ", "
                    end
                    if not has_any_been_trimmed then
                        name = name .. "..., ..."
                    end
                    has_any_been_trimmed = true
                    if active then
                        has_active_been_trimmed = true
                    end
                elseif value_pos.x + value_width > to.x - 10 then
                    local current_width = value_width
                    while value_pos.x + current_width > to.x - 10 - ellipsis_width do
                        name = name:sub(1, -2)
                        if name == "" then break end
                        current_width = render.text_size(fonts.menu, name).x
                    end
                    if not has_any_been_trimmed then
                        name = trim_last_space(name) .. "..."
                    end
                end
                if value_alpha > 0 then
                    render.text(name, fonts.menu, value_pos + v2(1, 1), shadow_color:salpha(value_alpha))
                    render.text(name, fonts.menu, value_pos, text_color:salpha(value_alpha))
                end

                x = x + math.round(value_width * (value_alpha / 255))
            end
            if active then
                place_comma = true
            end
        end
    else
        ---@cast el combo_box_t
        for i = 1, #self.values do
            local active = el:get_value() + 1 == i
            local value_alpha = self.values_data[i].anims.alpha(active and 255 or 0)
            -- self.values_data[i].anims.active(active and 255 or 0)
            if value_alpha > 0 then
                render.text(self.values[i], fonts.menu, text_pos + v2(1, 1), shadow_color:salpha(value_alpha))
                render.text(self.values[i], fonts.menu, text_pos, text_color:salpha(value_alpha))
            end
        end
    end
end, "dropdown_t.draw")

---@param self gui_dropdown_t
---@param alpha number
dropdown_mt.draw_popout = errors.handler(function (self, alpha)
    local active_alpha = self.anims.active() * (alpha / 255)
    if active_alpha == 0 then return end
    local padding = 26
    local height = #self.values * padding + 3
    local from = self.pos + v2(0, self.size.y - 2)
    local to = from + v2(self.width, height)
    local hover_anim = self.anims.hover()
    local active_border_color = colors.magnolia_tinted:fade(colors.magnolia, hover_anim / 255):alpha(active_alpha)
    local border_color = colors.magnolia_tinted:alpha(active_alpha)
    local half_height = math.round(height / 2)
    renderer.rect_filled(from + v2(1, 2), to - v2(1, 1), col.gray:alpha(active_alpha))
    renderer.rect_filled_fade(v2(to.x - 1, from.y + 1), to - v2(0, 1 + half_height), active_border_color, active_border_color, border_color, border_color)
    renderer.rect_filled_fade(from + v2(0, 1), v2(from.x + 1, to.y - 1 - half_height), active_border_color, active_border_color, border_color, border_color)
    renderer.rect_filled(v2(from.x, to.y - half_height - 1), v2(from.x + 1, to.y - 1), border_color)
    renderer.rect_filled(to - v2(1, 1 + half_height), to - v2(0, 1), border_color)
    renderer.rect_filled(v2(from.x + 1, to.y - 1), to - v2(1, 0), border_color)
    local new_col = border_color:salpha(127)
    renderer.rect_filled(v2(from.x, to.y), v2(from.x + 1, to.y - 1), new_col)
    renderer.rect_filled(to - v2(1, 1), to, new_col)

    local text_color = col.white:alpha(active_alpha)
    local active_text_color = col(colors.magnolia.r + 10, colors.magnolia.g + 10, colors.magnolia.b + 10, active_alpha)
    local shadow_color = col.black:alpha(active_alpha)
    do
        local hovered = drag.hover_absolute(from, to)
        if hovered then
            gui.hovered = true
        end
        if not hovered and input.is_key_clicked(1) and active_alpha > 127 then
            self.open = false
        end
    end
    for i = 1, #self.values do
        local el = self.el
        local active
        if self.multi then
            ---@cast el multi_combo_box_t
            active = el:get_value(i - 1)
        else
            ---@cast el combo_box_t
            active = el:get_value() + 1 == i
        end
        local pos = from + v2(0, 2 + (i - 1) * padding)
        if i ~= 1 then
            renderer.rect_filled(pos + v2(1, 0), pos - v2(1, 0) + v2(self.width, 1), border_color)
        end
        local text_padding = 5
        local text_pos = pos + v2(text_padding, padding / 2)
        local hovered = drag.hover_absolute(pos, pos + v2(self.width, padding))
        if hovered and active_alpha > 127 then
            if input.is_key_clicked(1) then
                gui.drag:block()
                click_effect.add()
                if self.multi then
                    ---@cast el multi_combo_box_t
                    el:set_value(i - 1, not el:get_value(i - 1))
                else
                    ---@cast el combo_box_t
                    el:set_value(i - 1)
                end
            end
            drag.set_cursor(drag.hand_cursor)
        end
        local value_alpha = self.values_data[i].anims.active(active and 255 or 0) * (active_alpha / 255)
        local hover_text_anim = self.values_data[i].anims.hover((active or hovered) and 255 or 0)
        local cur_text_color = text_color:fade(active_text_color, value_alpha / 255)
        render.text(self.values[i], fonts.menu, text_pos + v2(1, 1), shadow_color:alpha_anim(hover_text_anim, 127, 255), render.flags.Y_ALIGN)
        render.text(self.values[i], fonts.menu, text_pos, cur_text_color:alpha_anim(hover_text_anim, 127, 255), render.flags.Y_ALIGN)
        if value_alpha > 0 then
            renderer.circle(text_pos + v2(self.width - text_padding * 3, 0), 2, 6, true, cur_text_color:alpha(value_alpha))
        end
    end
end)

---@overload fun(self: gui_dropdown_t, index: number): boolean
---@overload fun(self: gui_dropdown_t): number
dropdown_mt.val_index = function (self, index)
    if self.multi and index then
        return self.el:get_value(index - 1)
    elseif not self.multi then
        return self.el:get_value() + 1
    end
end

---@overload fun(self: gui_dropdown_t, name: string): boolean
---@overload fun(self: gui_dropdown_t): string
dropdown_mt.value = errors.handler(function (self, name)
    if self.multi and name then
        for i = 1, #self.values do
            if self.values[i] == name then
                return self.el:get_value(i - 1)
            end
        end
    elseif not self.multi then
        local val = self.el:get_value() + 1
        if name then
            for i = 1, #self.values do
                if self.values[i] == name then
                    return self.el:get_value() + 1 == i
                end
            end
        else
            return self.values[val]
        end
    end
end, "dropdown_mt.value")

---@param fn fun(el: gui_dropdown_t)
---@return gui_dropdown_t?
dropdown_mt.update = function (self, fn)
    if self.multi then return error("can't use update on multi dropdown") end
    cbs.paint(function ()
        local value = self:value()
        if value ~= self.old_value then
            fn(self)
        end
        self.old_value = value
    end, self.name .. ".update")
    cbs.unload(function ()
        self.el:set_value(0)
        fn(self)
    end, self.name .. ".update")
    return self
end

dropdown_mt.new = errors.handler(function (name, values, defaults)
    local path = gui.get_path(name)
    local el
    local multi = false
    if type(defaults) == "table" then
        local defaults_table = {}
        for k = 1, #values do
            defaults_table[k] = false
        end
        for i = 1, #defaults do
            for k = 1, #values do
                if values[k] == defaults[i] then
                    defaults_table[k] = true
                end
            end
        end
        el = ui.add_multi_combo_box(path, path, values, defaults_table)
        multi = true
    else
        for i = 1, #values do
            if values[i] == defaults then
                def_value = i - 1
                break
            end
        end
        el = ui.add_combo_box(path, path, values, def_value)
    end
    local c = setmetatable({
        name = name,
        el = el,
        multi = multi,
        values = values,
        open = false,
        anims = anims.new({
            alpha = 255,
            hover = 0,
            active = 0,
            none_active = 0,
        }),
        pos = v2(0, 0),
        width = 0,
        values_data = {

        },
        size = v2(0, 32),
    }, { __index = dropdown_mt })
    if not multi then
        c.old_value = def_value or 0
    end
    for i = 1, #values do
        c.values_data[i] = {
            anims = anims.new({
                alpha = 0,
                active = 0,
                hover = 0,
            }),
            text_size = v2(0, 0),
        }
    end
    c.el:set_visible(false)
    return c
end, "dropdown_mt.new")

---@param name string
---@param values string[]
---@param defaults? string[]|string
---@return gui_dropdown_t
gui.dropdown = function(name, values, defaults)
    return gui.add_element(dropdown_mt.new(name, values, defaults))
end
end)
__bundle_register("includes.gui.checkbox", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")
local element_t = require("includes.gui.element")
local inline_t = require("includes.gui.inline")
local colors = require("includes.colors")
local cbs = require("libs.callbacks")
local options_t = require("includes.gui.options")

local checkbox_t = { }

---@class gui_checkbox_t : gui_element_class
---@field inline gui_options_t[]
---@field el checkbox_t
---@field old_value boolean
---@field default_value boolean
---@field callbacks table<string, fun()>
local checkbox_mt = {
    master = element_t.master,
    options = options_t.new
}
---@param self gui_checkbox_t
---@param pos vec2_t
---@param alpha number
---@param width number
---@param input_allowed boolean
checkbox_mt.draw = errors.handler(function (self, pos, alpha, width, input_allowed)
    -- renderer.rect(pos, pos + v2(width, s.size.y), col.white:alpha(alpha))
    local text_size = render.text_size(fonts.menu, self.name)
    local size = v2(18, 18)
    local text_padding = 8
    local hover_to = pos + size + v2(text_size.x + text_padding + 2, 0)
    local hovered = input_allowed and drag.hover_absolute(pos, hover_to)
    render.text(self.name, fonts.menu, pos + v2(size.x + text_padding + 1, 2), col.black:alpha(alpha))
    render.text(self.name, fonts.menu, pos + v2(size.x + text_padding, 1), col.white:alpha(alpha))
    local value = self:value()
    local hover_anim, active_anim
    if hovered then
        if input.is_key_clicked(1) then
            gui.drag:block()
            click_effect.add()
            value = self.el:set_value(not value)
        end
        drag.set_cursor(drag.hand_cursor)
    end
    hover_anim = self.anims.hover((hovered or value) and 255 or 0 )
    active_anim = self.anims.active(value and 255 or 0)
    renderer.rect_filled(pos + v2(1, 1), pos + size - v2(1, 1), col.gray:fade(colors.magnolia, active_anim / 255):alpha(alpha))
    render.smoothed_rect(pos, pos + size, colors.magnolia_tinted:fade(colors.magnolia, hover_anim / 255):alpha(alpha), false)
    self:draw_checkmark(pos, alpha * (active_anim / 255))
    inline_t.draw(self, pos, alpha, width, input_allowed)
    if self.size.x == 0 then
        self.size.x = hover_to.x - pos.x + inline_t.calculate_size(self)
    end
end, "checkbox_t.draw")
---@param fn fun(cmd: usercmd_t, el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.create_move = function (self, fn)
    cbs.create_move(function (cmd)
        if self:value() then fn(cmd, self) end
    end, self.name .. ".create_move")
    return self
end
---@param fn fun(el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.paint = function (self, fn)
    cbs.paint(function ()
        if self:value() then fn(self) end
    end, self.name .. ".paint")
    return self
end
---@param fn fun(event: game_event_t, el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.callback = function (self, event_name, fn)
    cbs.event(event_name, function (event)
        if self:value() then fn(event, self) end
    end, self.name .. "." .. event_name)
    return self
end
---@param fn fun(el: gui_checkbox_t)
---@return gui_checkbox_t
checkbox_mt.update = function (self, fn)
    cbs.paint(function ()
        local value = self:value()
        if value ~= self.old_value then
            fn(self)
        end
        self.old_value = value
    end, self.name .. ".update")
    cbs.unload(function ()
        self:value(false)
        fn(self)
    end, self.name .. ".update")
    return self
end
---@param self gui_checkbox_t 
---@param pos vec2_t
---@param alpha number
checkbox_mt.draw_checkmark = errors.handler(function (self, pos, alpha)
    local color = col.gray:alpha(alpha)
    local size = v2(18, 18)
    local anim = self.anims.active()
    do
        local start_pos = pos + v2(5, size.y / 2)
        local difference = pos + v2(size.x / 2, size.y / 2 + 3) - start_pos
        renderer.line(start_pos, start_pos + difference * math.clamp(anim * 2, 0, 255) / 255, color)
    end
    do
        local start_pos = pos + v2(size.x / 2 - 1, size.y / 2 + 3)
        local difference = pos + v2(size.x - 5, 5) - start_pos
        renderer.line(start_pos, start_pos + difference * math.clamp(anim * 2 - 255, 0, 255) / 255, color)
    end
end, "checkbox_t.draw_checkmark")
---@param value? boolean
---@return boolean
checkbox_mt.value = function (self, value)
    if value ~= nil then
        self.el:set_value(value)
    end
    return self.el:get_value()
end
checkbox_t.new = errors.handler(function (name, value)
    local path = gui.get_path(name)
    local c = setmetatable({
        name = name,
        default_value = value or false,
        el = ui.add_check_box(path, path, value or false),
        anims = anims.new({
            alpha = 255,
            hover = 0,
            active = 0,
        }),
        inline = {},
        size = v2(0, 18),
        old_value = value or false,
    }, { __index = checkbox_mt })
    c.el:set_visible(false)
    return c
end, "checkbox_t.new")
---@param name string
---@param value? boolean
---@return gui_checkbox_t
gui.checkbox = function(name, value)
    return gui.add_element(checkbox_t.new(name, value))
end
end)
__bundle_register("includes.gui.inline", function(require, _LOADED, __bundle_register, __bundle_modules)
local v2, v3 = require("libs.vectors")()

local inline_t = {}
---@param element gui_element_t
inline_t.draw = function(element, pos, alpha, width, input_allowed)
    local enabled = true
    if element.value then
        enabled = element:value() ---@type boolean
    end
    local offset = 0
    for i = 1, #element.inline do
        local inline = element.inline[i]
        local inline_alpha = inline.anims.enabled(enabled and 255 or 0)
        if inline_alpha > 0 then
            inline:inline_draw(pos + v2(width - inline.size.x - offset, 0), alpha * inline_alpha / 255, input_allowed and enabled)
        end
        offset = offset + inline.size.x + gui.paddings.inline_padding
    end
end
inline_t.calculate_size = function(element)
    local width = gui.paddings.inline_padding * (#element.inline + 1)
    for i = 1, #element.inline do
        width = width + element.inline[i].size.x
    end
    return width
end

return inline_t
end)
__bundle_register("includes.gui.column", function(require, _LOADED, __bundle_register, __bundle_modules)
local errors = require("libs.error_handler")
local v2 = require("libs.vectors")()

---@class gui_column_t
---@field elements gui_element_t[]
---@field size vec2_t

---@class gui_column_t
local column_t = {}

local column_mt = {
    ---@class gui_column_t
    __index = {
        ---@param s gui_column_t
        ---@return vec2_t
        get_size = errors.handler(function(s)
            local size = v2(0, 0)
            local last_padding = 0
            for i = 1, #s.elements do
                local element = s.elements[i]
                if element.size.x > size.x then
                    size.x = element.size.x
                end
                local alpha = element.anims.alpha() / 255
                last_padding = 6
                size.y = size.y + (element.size.y + last_padding) * alpha
            end
            size.y = size.y - last_padding
            s.size = size
            return size
        end, "column_t.get_size"),
        ---@param s gui_column_t
        input_allowed = errors.handler(function(s)
            for l = 1, #s.elements do
                local element = s.elements[l]
                if element.open then
                    return false
                end
                if element.inline then
                    for i = 1, #element.inline do
                        if element.inline[i].open then
                            return false
                        end
                    end
                end
                if element.active then
                    return false
                end
            end
            return true
        end, "column_t.input_allowed"),
    }
}

---@return gui_column_t
column_t.new = function ()
    return setmetatable({
        elements = {},
        size = v2(0, 0)
    }, column_mt)
end

gui.column = errors.handler(function ()
    if gui.current_options then
        table.insert(gui.current_options.columns, column_t.new())
        return
    end
    local tab = gui.elements[#gui.elements]
    local subtab = tab.subtabs[#tab.subtabs]
    table.insert(subtab.columns, column_t.new())
end, "gui.column")

return column_t
end)
__bundle_register("includes.gui.popouts", function(require, _LOADED, __bundle_register, __bundle_modules)
local errors = require("libs.error_handler")
local options_t = require("includes.gui.options")
local popouts_t = { }
---@param columns gui_column_t[]
---@param alpha any
popouts_t.draw_columns = function(columns, alpha)
    for _, column in pairs(columns) do
        for _, element in pairs(column.elements) do
            if element.draw_popout then
                ---@diagnostic disable-next-line: param-type-mismatch
                element:draw_popout(alpha)
            end
            for i = 1, #(element.inline or {}) do
                local inline = element.inline[i]
                if inline.columns then
                    inline:draw(alpha)
                    popouts_t.draw_columns(inline.columns, alpha)
                end
            end
        end
    end
end
popouts_t.draw = errors.handler(function()
    local alpha = gui.anims.main_alpha()
    for _, tab in pairs(gui.elements) do
        local tab_alpha = tab.anims.alpha() * (alpha / 255)
        for _, subtab in pairs(tab.subtabs) do
            local subtab_alpha = subtab.anims.alpha() * (tab_alpha / 255)
            popouts_t.draw_columns(subtab.columns, subtab_alpha)
        end
    end
end, "options_t.draw")

return popouts_t
end)
__bundle_register("includes.gui.subtab", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
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
                render.text(subtab.name,
                    fonts.header, p,
                    col.white:fade(colors.magnolia, underline_alpha / 255):alpha(alpha):alpha_anim(hover, 100, 255),
                    render.flags.Y_ALIGN)
                -- if underline_alpha > 0 then
                --     local active_line_color = colors.magnolia:alpha(alpha):salpha(underline_alpha)
                --     -- renderer.rect_filled(active_line_pos, active_line_pos + v2(text_size.x, 1), active_line_color)
                --     -- renderer.rect_filled(active_line_pos + v2(0, 1), active_line_pos + v2(text_size.x, 2), active_line_color:salpha(100))
                -- end
                if not is_last then
                    local line_pos = p + v2(0, padding / 2)
                    renderer.rect_filled(line_pos, line_pos + v2(width, 1), col.white:alpha(alpha):salpha(30))
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
end)
__bundle_register("includes.gui.types", function(require, _LOADED, __bundle_register, __bundle_modules)
---@alias gui_element_t gui_checkbox_t|gui_slider_t|gui_dropdown_t
end)
__bundle_register("includes.gui.tab", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
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
            local text_size = render.text_size(fonts.header, s.name)
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

            render.text(s.icon, fonts.tab_icons, pos, icon_color, render.flags.Y_ALIGN)
            local text_pos = pos + v2(fonts.tab_icons.size + 8, 0)
            render.text(s.name, fonts.header, text_pos, color, render.flags.Y_ALIGN)

            line_width = line_width * 2
            local line_pos = text_pos + v2(text_size.x / 2 - line_width / 2, size.y - 2)
            local line_color = colors.magnolia:alpha(alpha):alpha_anim(underline_alpha, 0, 255)
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
end)
__bundle_register("includes.preload", function(require, _LOADED, __bundle_register, __bundle_modules)
local errors = require("libs.error_handler")
local o_require = require
require = function (lib)
    local result = nil
    errors.handler(function()
        result = o_require(lib)
    end)()
    return result
end
end)
return __bundle_require("__root")