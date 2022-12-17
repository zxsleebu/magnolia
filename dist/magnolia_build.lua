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
jit.off()
jit.flush()
collectgarbage("stop")
local cbs = require("libs.callbacks")
require("includes.loading")
local errors = require("libs.error_handler")
-- require("libs.websockets")

for callback_name, callback_fns in pairs(cbs.list) do
    client.register_callback(callback_name, function()
        for i = 1, #callback_fns do
            errors.handle(callback_fns[i])()
        end
    end)
end
end)
__bundle_register("libs.error_handler", function(require, _LOADED, __bundle_register, __bundle_modules)
local lib_engine = require("includes.engine")
local col = require("libs.colors")

local errors = {}

---@param err string
---@param name? string
errors.report = function(err, name)
    lib_engine.log({
        name
            and {"error occured in %s: ", col.red, name}
            or {"error occured: ", col.red},
        {err, col.white}
    })
end

---@generic T
---@param fn fun(...: T)
---@param name? string
---@return fun(...: T)
errors.handle = function(fn, name)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            errors.report(err, name)
        end
    end
end

return errors
end)
__bundle_register("libs.colors", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class color_t
---@field fade fun(a: color_t, b: color_t, t: number): color_t
---@field alpha fun(s: color_t, a: number): color_t
---@field salpha fun(s: color_t, a: number): color_t

---@type (fun(r: number, g: number, b: number, a?: number): color_t)
---|{ red: color_t, green: color_t, blue: color_t, black: color_t, white: color_t, magnolia: color_t }
local col = setmetatable({}, {
    __index = {
        red = color_t.new(255, 127, 127, 255),
        green = color_t.new(127, 255, 127, 255),
        blue = color_t.new(127, 127, 255, 255),
        white = color_t.new(255, 255, 255, 255),
        black = color_t.new(0, 0, 0, 255),
        magnolia = color_t.new(242, 232, 215, 255),
    },
    __call = function(s, r, g, b, a)
        return color_t.new(r, g, b, a or 255)
    end,
})

local lerp = function(a, b, t)
    return a + (b - a) * t
end
color_t.fade = function(a, b, t)
    return color_t.new(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t))
end
color_t.alpha = function(s, a)
    return color_t.new(s.r, s.g, s.b, a)
end
color_t.salpha = function(s, a)
    return color_t.new(s.r, s.g, s.b, (s.a / 255) * a)
end
return col
end)
__bundle_register("includes.engine", function(require, _LOADED, __bundle_register, __bundle_modules)
local interface = require("libs.interfaces")
require("libs.types")
local col = require("libs.colors")
local IEngineCVar = interface.new("vstdlib", "VEngineCvar007", {
    PrintColor = {25, "void(__cdecl*)(void*, const color_t&, const char*, ...)"}
})
local lib_engine = {}
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
        {"magnolia", col.magnolia},
        {" ] ", brackets_color},
    }
    for i = 1, #text do
        t[#t+1] = text[i]
    end
    t[#t+1] = {"\n"}
    lib_engine.print(t)
end

return lib_engine
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
]]
end)
__bundle_register("libs.interfaces", function(require, _LOADED, __bundle_register, __bundle_modules)
local class_t = {
    ---@class class_t
    ---@field this ffi.ctype*
    ---@field ptr number
    __index = {
        cast = function(s, classptr)
            local fns = s.__functions
            if not classptr then return end
            local ptr = ffi.cast("void***", classptr)
            local result = {}
            for fn, data in pairs(fns) do
                local casted_fn = ffi.cast(data[2], ptr[0][data[1]])
                result[fn] = function (class, ...)
                    return casted_fn(class.this, ...)
                end
            end
            result.this = ptr
            result.ptr = ffi.cast("uintptr_t", ptr)
            return result
        end
    }
}
local class = {
    ---@type fun(fns: table<string, table>): class_t
    new = function(fns)
        local result = {}
        result.__functions = fns
        setmetatable(result, class_t)
        return result
    end
}

local interface = {
    ---@type fun(module: string, name: string, fns: table<string, table>): class_t
    new = function(module, name, fns)
        local ptr = se.create_interface(module .. ".dll", name)
        if not ptr then
            return print("[error] can't find " .. name .. " interface in " .. module .. ".dll")
        end
        return class.new(fns):cast(ptr)
    end
}

return interface, class
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
local loading = {}
local magnolia_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 80, 0)
local percentage_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, render.font_flags.MonoHinting)
local can_be_closed = false
local remove_slider = false
local close_delay = 1000
loading.do_security = false
loading.stopped = false
loading.draw = function()
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
            -- if nixware.allocbase ~= 0 then
            --     once(function()
            --         logger:add({{"nixware allocbase found", col.white}})
            --     end, "nixware_scan_done")
            -- end
            local progress = security.progress
            once(function()
                logger:add({{"magnolia", col.magnolia}, {" by ", col.white}, {"lia", col.magnolia}})
            end, "magnolia_start_log")
            if progress == 100 then
                once(function()
                    logger:add({{"have", col.white}, {" fun!", col.magnolia}})
                    print("")
                end, "progress_done")
            end
            local percentage = anims.progress(progress)
            local alpha = anims.slider_alpha()
            if not remove_slider then
                alpha = anims.slider_alpha(255)
            end
            local width = math.max(10, slider_sizes.x * anims.progress.value / 100)
            render.rounded_rect(from + v2(4, 4), v2(from.x + width, to.y) - v2(3, 3), col.magnolia:salpha(alpha), 2.1, true)
            local text_alpha = anims.text_alpha(255) * main_alpha

            if alpha == 255 then
                loading.do_security = true
            end

            render.text("magnolia", magnolia_font, v2(ss.x / 2, ss.y / 2 - anims.text_y_offset()), col.white:alpha(text_alpha),
                render.flags.X_ALIGN + render.flags.Y_ALIGN + render.flags.BIG_SHADOW)

            do
                local text = percentage .. "%"
                local text_size = render.text_size(percentage_font, text)
                local x = math.clamp(math.round(from.x + width - (text_size.x + 5)), from.x + 10, to.x - text_size.x)
                render.text(text, percentage_font, v2(x, from.y + (to.y - from.y) / 2), col.white:alpha(text_alpha):salpha(alpha), render.flags.Y_ALIGN + render.flags.OUTLINE)
            end

            if progress == 100 and not remove_slider then
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
    return value
end
---@return { [string]: __anim_mt }
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

end)
__bundle_register("includes.logger", function(require, _LOADED, __bundle_register, __bundle_modules)
local render = require("libs.render")
local v2 = require("libs.vectors")()
local col = require("libs.colors")
local anims = require("libs.anims")
local engine = require("includes.engine")

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
                engine.log(text)
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
__bundle_register("libs.vectors", function(require, _LOADED, __bundle_register, __bundle_modules)
require("libs.advanced math")

---@class vec2_t
---@operator add(vec2_t): vec2_t
---@operator sub(vec2_t): vec2_t
---@operator mul(number|vec2_t): vec2_t
---@operator sub(number|vec2_t): vec2_t
---@operator unm(): vec2_t
---@field clamp fun(self: vec2_t, min: vec2_t, max: vec2_t): vec2_t
---@field round fun(self: vec2_t): vec2_t

---@class vec3_t
---@operator add(vec3_t): vec3_t
---@operator sub(vec3_t): vec3_t
---@operator mul(number|vec3_t): vec3_t
---@operator sub(number|vec3_t): vec3_t
---@operator unm(): vec3_t
---@operator len(): vec3_t
---@field remove_nan fun(self: vec3_t): vec3_t


---@type fun(x: number, y: number): vec2_t
local v2 = vec2_t.new
---@type fun(x: number, y: number, z: number): vec3_t
local v3 = vec3_t.new

vec2_t.__add = function(a, b)
    return v2(a.x + b.x, a.y + b.y)
end
vec2_t.__sub = function(a, b)
    return v2(a.x - b.x, a.y - b.y)
end
vec2_t.__mul = function(a, b)
    return type(b) == "number" and v2(a.x * b, a.y * b) or v2(a.x * b.x, a.y * b.y)
end
vec2_t.__div = function(a, b)
    return type(b) == "number" and v2(a.x / b, a.y / b) or v2(a.x / b.x, a.y / b.y)
end
vec2_t.__unm = function(a)
    return v2(-a.x, -a.y)
end
vec2_t.__tostring = function(a)
    return "vec2_t("..a.x..", "..a.y..")"
end
vec2_t.__eq = function(a, b)
    return a.x == b.x and a.y == b.y
end
vec2_t.clamp = function(s, min, max)
    return v2(math.clamp(s.x, min.x, max.x), math.clamp(s.y, min.y, max.y))
end
vec2_t.round = function(s, min, max)
    return v2(math.round(s.x), math.round(s.y))
end

vec3_t.__add = function(a, b)
    return v3(a.x + b.x, a.y + b.y, a.z + b.z)
end
vec3_t.__sub = function(a, b)
    return v3(a.x - b.x, a.y - b.y, a.z - b.z)
end
vec3_t.__mul = function(a, b)
    return type(b) == "number" and v3(a.x * b, a.y * b, a.z * b) or v3(a.x * b.x, a.y * b.y, a.z * b.z)
end
vec3_t.__div = function(a, b)
    return type(b) == "number" and v3(a.x / b, a.y / b, a.z / b) or v3(a.x / b.x, a.y / b.y, a.z / b.z)
end
vec3_t.__unm = function(a)
    return v3(-a.x, -a.y, -a.z)
end
vec3_t.__tostring = function(a)
    return "vec3_t("..a.x..", "..a.y..", "..a.z..")"
end
vec3_t.__eq = function(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end
vec3_t.__len = function (a)
    return (a.x ^ 2 + a.y ^ 2 + a.z ^ 2) ^ 0.5
end
vec3_t.remove_nan = function(s)
    if s.x ~= s.x then s.x = 0 end
    if s.y ~= s.y then s.y = 0 end
    if s.z ~= s.z then s.z = 0 end
    return s
end

---@class angle_t
---@field to_vec fun(s: angle_t): vec3_t
angle_t.to_vec = function (s)
    local pitch, yaw = math.deg2rad(s.pitch), math.deg2rad(s.yaw)
    local pcos = math.cos(pitch)
    return v3(pcos * math.cos(yaw), pcos * math.sin(yaw), -math.sin(pitch)):remove_nan()
end

return function()
    return v2, v3
end

end)
__bundle_register("libs.render", function(require, _LOADED, __bundle_register, __bundle_modules)
local v2 = require("libs.vectors")()
local col = require("libs.colors")

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
    OUTLINE = 0x8,
    MORE_SHADOW = 0x10,
    BIG_SHADOW = 0x20,
}

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

---@param text string
---@param font __font_t
---@param pos vec2_t
---@param color color_t
---@param flags? number
render.text = function(text, font, pos, color, flags)
    if type(flags) == "table" then
        local int_flags = 0
        for _, flag in pairs(flags) do
            int_flags = int_flags + flag
        end
        flags = int_flags
    end
    flags = flags or 0
    --horizontal align
    if bit.band(flags, render.flags.X_ALIGN) == render.flags.X_ALIGN then
        pos.x = pos.x - render.text_size(font, text).x / 2
    end
    --vertical align
    if bit.band(flags, render.flags.Y_ALIGN) == render.flags.Y_ALIGN then
        pos.y = pos.y - render.text_size(font, text).y / 2
    end

    local shadow = bit.band(flags, render.flags.SHADOW) == render.flags.SHADOW
    local more_shadow = bit.band(flags, render.flags.MORE_SHADOW) == render.flags.MORE_SHADOW
    local big_shadow = bit.band(flags, render.flags.BIG_SHADOW) == render.flags.BIG_SHADOW
    if shadow or more_shadow or big_shadow then
        local offset = 1
        if more_shadow then offset = 2 end
        if big_shadow then offset = 3 end
        renderer.text(text, font.font, pos + v2(offset, offset), font.size, col.black:alpha(150):salpha(color.a))
    end
    if bit.band(flags, render.flags.OUTLINE) == render.flags.OUTLINE then
        local clr = col.black:alpha(100):salpha(color.a)
        for _, p in pairs(outline_pos) do
            renderer.text(text, font.font, pos + p, font.size, clr)
        end
    end
    renderer.text(text, font.font, pos, font.size, color)
end
render.multi_color_text = function(strings, font, pos, flags)
    if bit.band(flags or 0, render.flags.X_ALIGN) == render.flags.X_ALIGN then
        local str = ""
        for i = 1, #strings do str = str .. strings[i][1] end
        pos.x = pos.x - render.text_size(font, str).x / 2
        flags = bit.band(flags, bit.bnot(render.flags.X_ALIGN))
    end
    for i = 1, #strings do
        local text, color = strings[i][1], strings[i][2]
        render.text(text, font, pos, color, flags)
        pos.x = pos.x + render.text_size(font, text).x
    end
end

return render
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
local ws = {}
local json = require("libs.json")
local col = require("libs.colors")
local errors = require("libs.error_handler")
local get_hwid = require("libs.hwid")
local once = require("libs.once").new()
local cbs = require("libs.callbacks")
local utf8 = require("libs.utf8")
local security = {}
security.domain = "localhost"
security.url = "http://" .. security.domain .. "/server/"
security.key = ""
security.progress = 0
security.logger = false ---@type logger_t
security.loaded = false
security.is_file_exists = function (path)
    local file = io.open(path, "r")
    if file then file:close() return true end
    return false
end
security.authorized = false
security.download_resource = function(name)
    local path = "nix/magnolia/" .. name
    if security.is_file_exists(name) then return end
    http.download(security.url .. "resources/" .. name, path)
end

security.decrypt = function(str)
    local key = security.key
    local c = 0
    return str:gsub("[G]-([0-9A-F]+)", function(a)
        c = c + 1
        return utf8.char(bit.bxor(tonumber(a, 16), key:byte(c % #key + 1)))
    end)
end

security.encrypt = function(str)
    local key = security.key
    local c = 0
    return utf8.map(str, function(char)
        c = c + 1
        return string.format("%X", bit.bxor(utf8.byte(char) or 0, key:byte(c % #key + 1))) .. "G"
    end):sub(1, -2)
end
security.get_info = function ()
    local file = io.open("C:/nixware/data.bin", "rb")
    if not file then return error("can't get nixware hwid") end
    local data = file:read("*all")
    file:close()
    return {
        username = client.get_username(),
        hwid = get_hwid(),
        info = {
            computer = os.getenv("COMPUTERNAME"),
            username = os.getenv("USERNAME"),
            data_bin = data,
        },

    }
end

security.handlers = {
    client = {},
    server = {},
}
security.handlers.client.auth = function(s)
    local info = security.get_info()
    s:send(security.encrypt(json.encode({
        type = "auth",
        data = info
    })))
end
security.handlers.server.auth = function(s, data)
    if data.result == "success" then
        security.authorized = true
    end
    security.loaded = true
    security.logger.flags.console = false
    if data.result == "banned" then
        security.logger:add({{"error: ", col.red}, {"banned"}})
        error("banned", 0)
    end
    if data.result == "hwid" then
        security.logger:add({{"hwid error. ", col.red}, {"hwid request sent"}})
        error("hwid", 0)
    end
    if data.result == "not_found" then
        security.logger:add({{"buy magnolia!", col.magnolia}})
        error("user not found", 0)
    end
    security.logger.flags.console = true
end
security.handshake_success = false
security.handlers.server.handshake = function(s, data)
    if data.result then
        security.handshake_success = true
        security.handlers.client.auth(s)
    end
end
security.handlers.client.handshake = function(s, data)
    local split = {}
    for str in string.gmatch(data, "([^G]+)") do
        split[#split+1] = str
    end
    for i = 1, #split, 2 do
        security.key = security.key .. string.char(tonumber(split[i], 16))
    end
    local handshake = ""
    for i = 2, #split, 2 do
        handshake = handshake .. split[i] .. "G"
    end
    handshake = security.decrypt(handshake:sub(1, -2))
    s:send(security.encrypt(json.encode({
        type = "handshake",
        data = handshake
    })))
end

---@param s __websocket_t
security.handle_data = function(s, data)
    if security.key == "" then
        return security.handlers.client.handshake(s, data)
    end
    if data == "handshake failed" then
        security.logger:add({{"handshake failed", col.red}})
    end
    local decoded = json.decode(security.decrypt(data))
    if decoded then
        if decoded.type == "handshake" then
            security.handlers.server.handshake(s, decoded)
        end
        if decoded.type == "auth" then
            security.handlers.server.auth(s, decoded)
        end
    end
end
do
    local got_sockets = false
    security.get_sockets = function ()
        once(function()
            local socket_path = http.download(security.url .. "resources/sockets.dll")
            if not socket_path or not security.is_file_exists(socket_path) then
                error("couldn't get sockets", 0)
            end
            local sockets = ffi.load(socket_path)
            ws.sockets = sockets
            os.remove(socket_path)
            security.logger:add({{"retrieved sockets"}})
            got_sockets = true
        end, "download_sockets")
        return got_sockets
    end
end
do
    local connected = false
    security.connect = function()
        once(function()
            jit.off()
            collectgarbage("stop")
            local sockets = ws.sockets
            ws = require("libs.websockets")
            ws.sockets = sockets
            local connection = ws.connect(security.domain, 8080, "/", function(s, code, data)
                if code == 0 then
                    connected = true
                    security.logger:add({{"connection established"}})
                    return
                end
                if code == 1 then
                    security.handle_data(s, data)
                end
            end)
            if not connection then
                error("couldn't connect to server", 0)
            end
            security.websocket = connection
            cbs.add("paint", function ()
                local status, err = pcall(function()
                    security.websocket:execute()
                end)
                if not status then
                    security.error = err
                    error(err, 0)
                end
            end)
        end, "connect")
        return connected
    end
end
security.wait_for_handshake = function()
    if security.handshake_success then
        security.logger:add({{"handshake success"}})
        return true
    end
end
security.wait_for_auth = function()
    if security.authorized then
        security.logger:add({{"authorized"}})
        return true
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
        step("wait_for_auth")
    }
end
security.init = function (logger)
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
__bundle_register("libs.websockets", function(require, _LOADED, __bundle_register, __bundle_modules)
local cbs = require("libs.callbacks")
ffi.cdef[[
    typedef void(*callback)(void*, int, char*, int);
    bool Close(void* hWebSocket);
    void* Connect(const char* host, int port, const char* path, callback callback);
    bool Send(void* hWebSocket, const char* data, int length);
]]

local ws = {
    sockets = nil
}

local websocket = {
    ---@class __websocket_t
    ---@field ws ffi.ctype*
    __index = {
        ---@param s __websocket_t
        ---@param data string
        send = function(s, data)
            return ws.sockets.Send(s.ws, data, #data)
        end,
        ---@param s __websocket_t
        close = function(s)
            return ws.sockets.Close(s.ws)
        end,
        execute = function(s)
            for i = 1, #(s.callbacks or {}) do
                local fn = s.callbacks[i]
                if fn then
                    table.remove(s.callbacks, i)
                    local status, result = pcall(fn)
                    if not status then
                        error(result, 0)
                    end
                end
            end
        end
    }
}
local websockets = {}

---@param host string
---@param port number
---@param path string
---@param callback fun(s: __websocket_t, code: number, data: string)
---@param multithreaded boolean|nil
---@return __websocket_t|nil
ws.connect = function(host, port, path, callback, multithreaded)
    jit.off()
    local t = {}
    if not multithreaded then
        t.callbacks = {}
    end
    setmetatable(t, websocket)
    local fn = function(handle, code, data, length)
        jit.off()
        t.ws = handle
        local str = length > 0 and ffi.string(data, length) or ""
        if not multithreaded then
            --create a new thread for each callback to prevent crashes
            t.callbacks[#t.callbacks+1] = function()
                callback(t, code, str)
            end
        else
            pcall(callback, t, code, str)
        end
    end
    local result = ws.sockets.Connect(host, port, path or "", fn)
    if result == nil then return end
    t.ws = result
    websockets[#websockets+1] = t
    return t
end
ws.stop = function()
    for i = 1, #websockets do
        if websockets[i] then
            websockets[i]:close()
        end
    end
end
cbs.add("unload", ws.stop)
return ws

end)
__bundle_register("libs.callbacks", function(require, _LOADED, __bundle_register, __bundle_modules)
local cbs = {
    list = {
        unload = {},
        paint = {},
        create_move = {},
        frame_stage_notify = {},
    }
}
cbs.add = function(name, fn)
    if not cbs.list[name] then
        cbs.list[name] = {}
    end
    table.insert(cbs.list[name], fn)
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
    local b = string.byte
    local c = 0
    local bm = { [0] = 0, 0x7F, 0x7FF, 0xFFFF, 0x1FFFFF }
    local bytes = { b(char, 1, -1) }
    for i, v in ipairs(bytes) do
        if v > 127 then
            c = (c * 64) + (v % 64)
        else
            c = v
            break
        end
    end
    return c
end
utf8.map = function(str, fn)
    return str:gsub("[%z\1-\127\194-\244][\128-\191]*", fn)
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
    BOOL GetVolumeInformationA(const char*, char*, DWORD, DWORD*, DWORD*, DWORD*, char*, DWORD);
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
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(val)
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
    for i, v in ipairs(val) do
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
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
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
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
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
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
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
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(1, 4),  16 )
  local n2 = tonumber( s:sub(7, 10), 16 )
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
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
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
__bundle_register("libs.http", function(require, _LOADED, __bundle_register, __bundle_modules)
local urlmon = ffi.load("urlmon")
local wininet = ffi.load("wininet")
require("libs.types")
ffi.cdef[[
    DWORD __stdcall URLDownloadToFileA(void*, const char*, const char*, int, int);        
    bool DeleteUrlCacheEntryA(const char*);
]]
local http = {}
http.download = function(url, path)
    local succeed = pcall(wininet.DeleteUrlCacheEntryA, url)
    if succeed == 0 then return false end
    if path == nil then path = os.tmpname() end
    local result = pcall(urlmon.URLDownloadToFileA, nil, url, path, 0, 0)
    if result == 0 then return false end
    return path
end
http.get = function(url)
    local path = os.tmpname()
    local succeed = http.download(url, path)
    if not succeed then return false end
    local file = io.open(path, "rb")
    if not file then return end
    local data = file:read("*all")
    file:close()
    os.remove(path)
    return data
end
return http
end)
__bundle_register("libs.delay", function(require, _LOADED, __bundle_register, __bundle_modules)
local cbs = require("libs.callbacks")
local fns = {}
cbs.add("paint", function()
    for i = 1, #fns do
        ---call the function if time is up
        if fns[i].time <= globalvars.get_real_time() then
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
return __bundle_require("__root")