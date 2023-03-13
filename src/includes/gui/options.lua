local v2 = require("libs.vectors")()
local col = require("libs.colors")
local render = require("libs.render")
local http = require("libs.http")
local fonts = require("includes.gui.fonts")
local anims = require("libs.anims")

local options_t = {}
local options_mt = {}

---@param element gui_element_t
---@param options fun()
options_t.new = function (element, options)
    local self = setmetatable({
        element = element,
        anims = anims.new({
            alpha = 0,
        }),
        open = false,
    }, options_mt)
    element.inline = self
    gui.current_options = self
    options()
    gui.current_options = nil
end