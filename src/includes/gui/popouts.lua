local errors = require("libs.error_handler")
local options_t = require("includes.gui.options")
local popouts_t = { }
---@param columns gui_column_t[]
---@param alpha any
popouts_t.draw_columns = function(columns, alpha)
    for _, column in pairs(columns) do
        for _, element in pairs(column.elements) do
            if element.draw_popout then
                ---@diagnostic disable-next-line: param-type-mismatch
                element:draw_popout(alpha)
            end
            for i = 1, #(element.inline or {}) do
                local inline = element.inline[i]
                if inline.columns then
                    inline:draw(alpha)
                    popouts_t.draw_columns(inline.columns, alpha)
                end
            end
        end
    end
end
popouts_t.draw = errors.handler(function()
    local alpha = gui.anims.main_alpha()
    for _, tab in pairs(gui.elements) do
        local tab_alpha = tab.anims.alpha() * (alpha / 255)
        for _, subtab in pairs(tab.subtabs) do
            local subtab_alpha = subtab.anims.alpha() * (tab_alpha / 255)
            popouts_t.draw_columns(subtab.columns, subtab_alpha)
        end
    end
end, "options_t.draw")

return popouts_t