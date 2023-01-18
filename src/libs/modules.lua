ffi.cdef[[
    void* GetModuleHandleA(const char*);
    uintptr_t GetProcAddress(void*, const char*);
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
return modules