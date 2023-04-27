local interface = require("libs.interfaces")()
require("libs.types")
local col = require("libs.colors")
local IEngineCVar = interface.new("vstdlib", "VEngineCvar007", {
    PrintColor = {25, "void(__cdecl*)(void*, const color_t&, const char*, ...)"},
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

return lib_engine