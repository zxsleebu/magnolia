local lib_engine = require("includes.engine")
local col = require("libs.colors")

local errors = {}

---@param err string
---@param name? string
errors.report = function(err, name)
    lib_engine.log({
        name
            and {"error occured in %s: ", col.red, name}
            or {"error occured: ", col.red},
        {err, col.white}
    })
end

---@generic T
---@param fn fun(...: T)
---@param name? string
---@return fun(...: T)
errors.handle = function(fn, name)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            errors.report(err, name)
        end
        return err
    end
end

return errors