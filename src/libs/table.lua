table.find_by_value = function(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
end