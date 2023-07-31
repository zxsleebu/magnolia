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
        get_size = errors.handler(function(s)
            local size = v2(0, 0)
            local last_padding = 0
            for i = 1, #s.elements do
                local element = s.elements[i]
                if element.size.x > size.x then
                    size.x = element.size.x
                end
                local alpha = element.anims.alpha() / 255
                last_padding = 6
                size.y = size.y + (element.size.y + last_padding) * alpha
            end
            size.y = size.y - last_padding
            s.size = size
            return size
        end, "column_t.get_size"),
        ---@param s gui_column_t
        input_allowed = errors.handler(function(s)
            for l = 1, #s.elements do
                local element = s.elements[l]
                if element.open then
                    return false
                end
                if element.inline then
                    for i = 1, #element.inline do
                        if element.inline[i].open then
                            return false
                        end
                    end
                end
                if element.active then
                    return false
                end
            end
            return true
        end, "column_t.input_allowed"),
    }
}

---@return gui_column_t
column_t.new = function ()
    return setmetatable({
        elements = {},
        size = v2(0, 0)
    }, column_mt)
end

gui.column = errors.handler(function ()
    if gui.current_options then
        table.insert(gui.current_options.columns, column_t.new())
        return
    end
    local tab = gui.elements[#gui.elements]
    local subtab = tab.subtabs[#tab.subtabs]
    table.insert(subtab.columns, column_t.new())
end, "gui.column")

return column_t