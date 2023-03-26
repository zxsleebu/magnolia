local lib_engine = require("includes.engine")
local col = require("libs.colors")

local errors = {}

---@param err string
---@param name? string
errors.report = function(err, name)
    local red = col(255, 75, 75)
    if name then
        lib_engine.log({
            {"[ ", red},
            {"error", col.red},
            {" ] in ", red},
            {name, col.red},
            {": ", red},
            {err, col.white}
        })
    else
        lib_engine.log({
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
errors.handle = function(fn, name)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            --remove ...r-Strike Global Offensive\lua\ from the error message
            ---@cast err string
            -- err = err:gsub(".....r-Strike Global Offensive\\lua\\", "")
            if err:sub(1, 1) == "." then
                err = err:gsub("%.%.%..-\\lua\\", "")
            end
            errors.report(err, name)
        end
        return err
    end
end

return errors