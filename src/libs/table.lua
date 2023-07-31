---@param t table
---@param value any
---@return any
table.find_by_value = function(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
end
---@param t table
---@param value string
---@return string?
table.find_value_by_string_key = function(t, value)
    for k, v in pairs(t) do
        if k:find(value) then
            return v
        end
    end
end