local cbs = { list = {} }
cbs.add = function(name, fn)
    if not cbs.list[name] then
        cbs.list[name] = {}
    end
    table.insert(cbs.list[name], fn)
end
return cbs