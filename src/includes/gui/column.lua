local errors = require("libs.error_handler")

---@class gui_column_t
---@field elements gui_element_t[]

local column_mt = {
    __index = {
        get_size = function()

        end
    }
}

local column_t = {}
column_t.new = function ()
    return setmetatable({
        elements = {}
    }, column_mt)
end

return column_t