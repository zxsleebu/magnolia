local once = {
    ---@return fun(fn: fun(), name: string)
    new = function()
        local t = {}
        ---@diagnostic disable-next-line: return-type-mismatch
        return setmetatable(t, {
            __call = function(s, func, id)
                if not s[id] then
                    s[id] = true
                    func()
                end
            end,
        })
    end
}

return once