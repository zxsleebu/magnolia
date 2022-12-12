return function(...)
    local elems = select(1, ...)
    local t = {}
    if type(elems) == "table" then
        for _, v in pairs(elems) do
            t[v] = true end
        return t
    end
    for i = 1, select("#", ...) do
        t[select(i, ...)] = true
    end
    return t
end