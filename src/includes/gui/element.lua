local element_t = {}

---@param s gui_element_t
---@param master gui_checkbox_t|fun(): boolean
element_t.master = function(s, master)
    s.master_object = {}
    if master.el then
        s.master_object.el = master.el
    elseif type(master) == "function" then
        s.master_object.fn = master
    end
    s.anims.alpha.value = 0
    return s
end
---@param s gui_element_t
element_t.animate_master = function(s)
    if not s.master_object then return 255, true end

    local value = false
    if s.master_object.el then
        value = s.master_object.el:get_value()
    elseif s.master_object.fn then
        value = s.master_object.fn()
    end
    return s.anims.alpha(value and 255 or 0), value
end

return element_t