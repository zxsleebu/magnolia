local v2 = require("libs.vectors")()
local col = require("libs.colors")
local render = require("libs.render")
local fonts = require("includes.gui.fonts")
local anims = require("libs.anims")
local drag = require("libs.drag")
local errors = require("libs.error_handler")
local input = require("libs.input")
local column_t = require("includes.gui.column")
local click_effect = require("includes.gui.click_effect")
local cbs = require("libs.callbacks")
local colors = require("includes.colors")

local bind_t = {}

---@class gui_bind_t
---@field anims __anims_mt
---@field pos vec2_t
---@field el key_bind_t
---@field size vec2_t
---@field open boolean
---@field changing boolean
---@field parent gui_checkbox_t|gui_label_t
---@field key_anims __anims_mt[]
local bind_mt = {

}

local bind_names = {
    [-1] = "...", [0] = "none",
    'm1','m2',0,'m3','m4','m5',0,'bsp','tab',0,0,0,'enter',0,0,'shift','ctrl','alt',
    'brk','caps',0,0,0,0,0,0,'esc',0,0,0,0,'space','pg up','pg dn','end',
    'home','<-','^','->','v',0,0,0,0,'ins','del',0,'0','1','2','3','4','5',
    '6','7','8','9',0,0,0,0,0,0,0,'a','b','c','d','e','f','g','h',
    'i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',0,0, 0,
    0,0,'n0','n1','n2','n3','n4','n5','n6','n7','n8','n9','n*','n+',0,'n-','n.','n/',
    'f1','f2','f3','f4','f5','f6','f7','f8','f9','f10','f11','f12'
}
bind_names[161] = 'r shift'
bind_names[162] = 'ctrl'
bind_names[163] = 'r ctrl'
bind_names[164] = 'alt'
bind_names[165] = 'r alt'
bind_names[144] = 'num lk'
bind_names[145] = 'scr lk'
bind_names[192] = '`'
bind_names[220] = '\\'

---@param self gui_bind_t
---@param pos vec2_t
---@param alpha number
---@param input_allowed boolean
bind_mt.inline_draw = errors.handler(function(self, pos, alpha, input_allowed)
    local active_key = self.el:get_key()
    if self.changing then
        active_key = -1
    end
    for key, name in pairs(bind_names) do
        if self.changing then
            if key ~= 0 and input.is_key_clicked(key) then
                active_key = key
                self.el:set_key(key)
                self.changing = false
            end
        end
        if self.key_anims[key] and active_key ~= key then
            local key_alpha = self.key_anims[key].alpha(0)
            if key_alpha == 0 then
                self.key_anims[key] = nil
            end
        end
    end
    if not self.key_anims[active_key] then
        self.key_anims[active_key] = anims.new({
            alpha = 0,
        })
    end
    self.key_anims[active_key].alpha(255)
    local text_width = math.max(render.text_size(fonts.menu, bind_names[active_key]).x + 8, 20)
    if self.size.x == 0 then
        self.anims.width.value = text_width
        self.size.x = text_width
        return
    end
    self.size.x = self.anims.width(text_width)
    local size = self.size
    local hovered = input_allowed and drag.hover_absolute(pos, pos + size)
    local hover_anim = self.anims.hover((hovered or self.changing or self.open) and 255 or 0)
    -- local active_anim = self.anims.alpha((self.changing or self.open) and 255 or 0)
    renderer.rect_filled(pos + v2(1, 1), pos + size - v2(1, 1), col.gray:alpha(alpha))
    render.smoothed_rect(pos, pos + size, colors.magnolia_tinted:fade(colors.magnolia, hover_anim / 255):alpha(alpha), false)
    for key, anim in pairs(self.key_anims) do
        render.text(bind_names[key], fonts.menu, pos + v2(size.x / 2, 0), col.white:alpha(alpha):salpha(anim.alpha()), render.flags.X_ALIGN)
    end
    if hovered then
        drag.set_cursor(drag.hand_cursor)
        if input.is_key_clicked(1) then
            click_effect.add()
            self.changing = true
            -- if not self.open then
            --     self.pos = renderer.get_cursor_pos()
            -- end
            -- self.open = true
        end
    end
end, "bind_mt.inline_draw")
local container_t
-- ---@param self gui_options_t
-- ---@param alpha number
-- options_mt.draw = errors.handler(function(self, alpha)
--     if not container_t then
--         container_t = require("includes.gui.container")
--     end
--     local alpha_anim = self.anims.alpha()
--     local open_alpha = alpha_anim * (alpha / 255)
--     if open_alpha > 0 then
--         local input_allowed = self.open and not gui.is_another_dragging()
--         local size = v2((#self.columns + 1) * gui.paddings.options_container_padding, 0)
--         if self.columns then
--             for _, column in pairs(self.columns) do
--                 local col_size = column:get_size()
--                 if col_size.x < 100 then
--                     col_size.x = 100
--                 end
--                 size.x = size.x + col_size.x
--                 if col_size.y > size.y then
--                     size.y = col_size.y
--                 end
--                 for _, element in pairs(column.elements) do
--                     if element.size.x == 0 then
--                         --*HACK: this is a hack to make the options menu wait for the element to calculate its size before drawing it
--                         open_alpha = 0.01
--                     end
--                 end
--                 input_allowed = input_allowed and column:input_allowed()
--             end
--         end
--         size = v2(size.x + 1, gui.paddings.options_container_padding * 2 + size.y + 1)

--         local pos = self.pos - v2(size.x / 2, 0)
--         local to = pos + size

--         local hovered = drag.hover_absolute(pos, to)
--         if hovered and alpha_anim > 127 then
--             gui.hovered = true
--         end
--         if input_allowed and alpha_anim > 127 and not hovered and input.is_key_clicked(1) then
--             self.open = false
--         end

--         container_t.draw_background(pos, to, open_alpha, 253)

--         if self.columns then
--             local add_pos = v2(gui.paddings.options_container_padding + 1, gui.paddings.options_container_padding + 1)
--             for i = 1, #self.columns do
--                 local column = self.columns[i]
--                 container_t.draw_elements(column.elements, pos + add_pos, math.round(column.size.x), open_alpha, input_allowed)

--                 --!DEBUG
--                 -- renderer.rect(s.pos + add_pos, s.pos + add_pos + column.size, col.black:alpha(open_alpha))
--                 --!DEBUG

--                 add_pos.x = column.size.x + add_pos.x + gui.paddings.options_container_padding
--             end
--         end
--     end
-- end, "options_mt.draw")


---@param element gui_checkbox_t|gui_label_t 
---@param default_key? number
---@param default_mode? number
---@return gui_bind_t
bind_t.new = errors.handler(function (element, default_key, default_mode)
    local path = gui.get_path(element.name .. "_bind")
    local bind = ui.add_key_bind(path, path, default_key or 0, default_mode or 1)
    bind:set_visible(false)
    local t = setmetatable({
        parent = element,
        anims = anims.new({
            hover = 0,
            alpha = 0,
            width = 0,
            active = 0,
        }),
        key_anims = {},
        path = gui.get_path(element.name),
        pos = v2(0, 0),
        open = false,
        size = v2(0, 18),
        el = bind,
    }, { __index = bind_mt })
    element.inline[#element.inline+1] = t
    return t
end, "bind_t.new")

return bind_t