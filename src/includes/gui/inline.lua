local v2, v3 = require("libs.vectors")()

local inline_t = {}
---@param element gui_element_t
inline_t.draw = function(element, pos, alpha, width, input_allowed)
    local enabled = true
    if element.value then
        enabled = element:value() ---@type boolean
    end
    local offset = 0
    for i = 1, #element.inline do
        local inline = element.inline[i]
        local inline_alpha = inline.anims.enabled(enabled and 255 or 0)
        if inline_alpha > 0 then
            inline:inline_draw(pos + v2(width - inline.size.x - offset, 0), alpha * inline_alpha / 255, input_allowed and enabled)
        end
        offset = offset + inline.size.x + gui.paddings.inline_padding
    end
end
inline_t.calculate_size = function(element)
    local width = gui.paddings.inline_padding * (#element.inline + 1)
    for i = 1, #element.inline do
        width = width + element.inline[i].size.x
    end
    return width
end

return inline_t