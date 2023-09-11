local ffi = require("libs.protected_ffi")
require("libs.types")
ffi.cdef [[
    typedef uintptr_t (*GetInterfaceFn)();
    typedef struct {
        GetInterfaceFn Interface;
        char* InterfaceName;
        void* NextInterface;
    } CInterface;
    void* GetModuleHandleA(PCSTR);
    void* GetProcAddress(void*, PCSTR);
]]

local utils = {}

utils.create_interface = function(module, interface_name)
    local handle = ffi.C.GetModuleHandleA(module)
    assert(handle ~= nil, string.format("module %s not found", module));

    local pCreateInterface = ffi.cast("int", ffi.C.GetProcAddress(handle, "CreateInterface"));
    local interface = ffi.cast("CInterface***", pCreateInterface + ffi.cast("int*", pCreateInterface + 5)[0] + 15)[0][0]

    while interface ~= nil do
        if string.sub(ffi.string(interface.InterfaceName), 0, -4) == interface_name or ffi.string(interface.InterfaceName) == interface_name then
            return interface.Interface();
        end

        interface = ffi.cast("CInterface*", interface.NextInterface);
    end

    return 0x0
end

utils.find_pattern = function(module, pattern, offset)
    return tonumber(ffi.cast("uintptr_t", find_pattern(module .. ".dll", pattern, offset)))
end

utils.get_username = function()
    return get_user_name()
end

return utils