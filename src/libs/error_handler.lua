require("libs.types")
local col = require("libs.colors")
local utils = require("libs.utils")

local IEngineCVar = ffi.cast("void***", utils.create_interface("vstdlib.dll", "VEngineCvar007"))
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
errors.handle = function(fn, name, ...)
    return errors.handler(fn, name)(...)
end

return errors