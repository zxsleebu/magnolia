local errors = require("libs.error_handler")
local v2 = require("libs.vectors")()

---@class gui_column_t
---@field elements gui_element_t[]
---@field size vec2_t

---@class gui_column_t
local column_t = {}

local column_mt = {
    ---@class gui_column_t
    __index = {
        ---@param s gui_column_t
        ---@return vec2_t
        get_size = function(s)
            local size = v2(0, 0)
            local last_padding = 0
            for i = 1, #s.elements do
                local element = s.elements[i]
                if element.size.x > size.x then
                    size.x = element.size.x
                end
                local alpha = element.anims.alpha() / 255
                last_padding = element.padding
                size.y = size.y + (element.size.y + last_padding) * alpha
            end
            size.y = size.y - last_padding
            s.size = size
            return size
        end
    }
}

---@return gui_column_t
column_t.new = function ()
    return setmetatable({
        elements = {},
        size = v2(0, 0)
    }, column_mt)
end

return column_t