---@alias gui_element_draw_fn fun(self: any, pos: vec2_t, alpha: number, width: number, input_allowed: boolean)

---@class gui_element_class
---@field name string
---@field path string
---@field anims __anims_mt
---@field size vec2_t
---@field master_object? { el?: check_box_t, fn: fun(): boolean }
local element_t = {}

---@generic T
---@param s T
---@param master gui_checkbox_t|fun(): boolean
---@return T
element_t.master = function(s, master)
    ---@cast s gui_checkbox_t
    s.master_object = {}
    if type(master) == "function" then
        s.master_object.fn = master
    elseif master.el then
        s.master_object.el = master.el
    end
    s.anims.alpha.value = 0
    return s
end
---@param s gui_element_t
element_t.animate_master = function(s)
    if not s.master_object then return 255, true end

    local value = false
    if s.master_object.el then
        value = s.master_object.el:get()
    elseif s.master_object.fn then
        value = s.master_object.fn()
    end
    return s.anims.alpha(value and 255 or 0), value
end

return element_t