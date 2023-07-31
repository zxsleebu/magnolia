local render = require("libs.render")
local col = require("libs.colors")
local v2 = require("libs.vectors")()
local fonts = require("includes.gui.fonts")
local drag = require("libs.drag")
local anims = require("libs.anims")
local input = require("libs.input")
local errors = require("libs.error_handler")
local click_effect = require("includes.gui.click_effect")
local element_t = require("includes.gui.element")
local inline_t = require("includes.gui.inline")
local colors = require("includes.colors")
local cbs = require("libs.callbacks")
local options_t = require("includes.gui.options")

local label_t = { }
---@class gui_label_t : gui_element_class
---@field inline gui_options_t[]
local label_mt = {
    master = element_t.master,
    options = options_t.new
}
---@param self gui_checkbox_t
---@param pos vec2_t
---@param alpha number
---@param width number
---@param input_allowed boolean
label_mt.draw = errors.handler(function (self, pos, alpha, width, input_allowed)
    -- renderer.rect(pos, pos + v2(width, s.size.y), col.white:alpha(alpha))
    local text_size = render.text_size(fonts.label, self.name)
    render.text(self.name, fonts.menu, pos + v2(1, 2), col.black:alpha(alpha / 4))
    render.text(self.name, fonts.label, pos + v2(0, 1), col.white:alpha(alpha / 1.25))
    inline_t.draw(self, pos, alpha, width, input_allowed)
    if self.size.x == 0 then
        self.size.x = text_size.x + inline_t.calculate_size(self)
    end
end, "label_t.draw")

label_t.new = errors.handler(function (name)
    -- local path = gui.get_path(name)
    local c = setmetatable({
        name = name,
        anims = anims.new({
            alpha = 255,
        }),
        inline = {},
        size = v2(0, 18),
    }, { __index = label_mt })
    return c
end, "label_t.new")
---@param name string
---@return gui_label_t
gui.label = function(name)
    return gui.add_element(label_t.new(name))
end

return label_t