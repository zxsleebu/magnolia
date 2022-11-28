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