local element_t = {}

---@param element gui_element_t
---@param master gui_checkbox_t|fun(): boolean
element_t.master = function(element, master)
    element.master_object = {}
    if master.el then
        element.master_object.el = master.el
    elseif type(master) == "function" then
        element.master_object.fn = master
    end
    element.anims.alpha.value = 0
    return element
end
---@param element gui_element_t
element_t.animate_master = function(element)
    if not element.master_object then return 255, true end

    local value = false
    if element.master_object.el then
        value = element.master_object.el:get_value()
    elseif element.master_object.fn then
        value = element.master_object.fn()
    end
    return element.anims.alpha(value and 255 or 0), value
end

return element_t