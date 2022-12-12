local lib_engine = require("includes.engine")
local col = require("libs.colors")

---@param err string
---@param name? string
local report = function(err, name)
    lib_engine.print_color("[ magnolia ] ", col.magnolia)
    if name then
        lib_engine.print_color("error occured in %s: ", col.red, name)
    else
        lib_engine.print_color("error occured: ", col.red)
    end
    lib_engine.print_color(err, col.white)
    lib_engine.print_color("\n", col.white)
end

---@generic T
---@param fn fun(...: T)
---@param name? string
---@return fun(...: T)
local handle = function(fn, name)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            report(err, name)
        end
    end
end

return function()
    return handle, report
end