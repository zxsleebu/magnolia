local errors = require("libs.error_handler")
local utils = require("libs.utils")
-- local ffi = require("ffi")
-- local protected_ffi = require("libs.protected_ffi")
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
        local ptr = utils.create_interface(module .. ".dll", name)
        if not ptr then
            return print("[error] can't find " .. name .. " interface in " .. module .. ".dll")
        end
        return class.new(fns)(ptr)
    end
}

return function()
    return interface, class
end