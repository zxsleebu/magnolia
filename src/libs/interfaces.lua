---@class class_t
---@field this ffi.ctype*
---@field ptr number
require("libs.types")
local class_t = {
    __call = function(s, classptr)
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