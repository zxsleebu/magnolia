local v2 = require("libs.vectors")()
local col = require("libs.colors")
local render = require("libs.render")
local fonts = require("includes.gui.fonts")
local anims = require("libs.anims")
local drag = require("libs.drag")
local errors = require("libs.error_handler")
local input = require("libs.input")
local container_t = require("includes.gui.container")
local column_t = require("includes.gui.column")
local click_effect = require("includes.gui.click_effect")

local options_t = {}
local options_mt = {
    ---@class gui_options_t
    ---@field anims __anims_mt
    ---@field columns gui_column_t[]
    ---@field pos vec2_t
    ---@field open boolean
    __index = {
        ---@param s gui_options_t
        ---@param pos vec2_t
        ---@param alpha number
        ---@param input_allowed boolean
        inline_draw = errors.handle(function(s, pos, alpha, input_allowed)
            local text_pos, text_size = render.text("E", fonts.menu_icons, pos, col.white:alpha(alpha):salpha(s.anims.hover()), render.flags.CENTER)
            ---@cast text_size vec2_t
            local hovered = input_allowed and drag.hover_absolute(text_pos - v2(0, 1), text_pos + text_size + v2(0, 2))
            s.anims.hover((hovered or s.open) and 255 or 100)
            if hovered then
                drag.set_cursor(drag.hand_cursor)
                if input.is_key_clicked(1) then
                    click_effect.add()
                    if not s.open then
                        s.pos = renderer.get_cursor_pos()
                    end
                    s.open = true
                end
            end
            s.anims.alpha(s.open and 255 or 0)
        end, "options_mt.inline_draw"),
        ---@param s gui_options_t
        ---@param alpha number
        draw = errors.handle(function(s, alpha)
            local open_alpha = s.anims.alpha() * (alpha / 255)
            local to = s.pos + v2(100, 200)
            if open_alpha > 0 then
                local hovered = drag.hover_absolute(s.pos, to)
                if not hovered then
                    if input.is_key_clicked(1) then
                        s.open = false
                    end
                end
                container_t.draw_background(s.pos, to, open_alpha, 253)
                local input_allowed = true
                if s.columns then
                    for _, column in pairs(s.columns) do
                        for _, element in pairs(column.elements) do
                            if element.inline and element.inline.open then
                                input_allowed = false
                            end
                        end
                    end
                end
                container_t.draw_elements(s.columns, s.pos, 300, open_alpha, input_allowed)
            end
        end, "options_mt.draw"),
        size = v2(11, 14),
    }
}

---@param element gui_element_t
---@param options fun()
options_t.new = errors.handle(function (element, options)
    local self = setmetatable({
        element = element,
        columns = {
            column_t.new(),
        },
        anims = anims.new({
            hover = 100,
            enabled = 0,
            alpha = 0,
        }),
        pos = v2(0, 0),
        open = false,
    }, options_mt)
    element.inline = self
    gui.current_options = self
    options()
    gui.current_options = nil
end, "options_t.new")

options_t.draw = errors.handle(function()
    local alpha = gui.anims.main_alpha()
    for _, tab in pairs(gui.elements) do
        local tab_alpha = tab.anims.alpha() * (alpha / 255)
        for _, subtab in pairs(tab.subtabs) do
            local subtab_alpha = subtab.anims.alpha() * (tab_alpha / 255)
            for _, column in pairs(subtab.columns) do
                for _, element in pairs(column.elements) do
                    if element.inline and element.inline.columns then
                        element.inline:draw(subtab_alpha)
                    end
                end
            end
        end
    end
end, "options_t.draw")

gui.options = options_t.new

return options_t