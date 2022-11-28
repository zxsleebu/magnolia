local interface = require("libs.interfaces")
ffi.cdef[[
    typedef struct{
        char r, g, b, a;
    } color_t;
]]
local IEngineCVar = interface.new("vstdlib", "VEngineCvar007", {
    PrintColor = {25, "void(__cdecl*)(void*, const color_t&, const char*, ...)"}
})
local lib_engine = {}
lib_engine.print_color = function (text, clr, ...)
    local c = ffi.new("color_t")
    c.r, c.g, c.b, c.a = clr.r, clr.g, clr.b, clr.a
    IEngineCVar:PrintColor(c, text, ...)
end

return lib_engine