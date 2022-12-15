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