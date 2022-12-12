local ffi = require("ffi")
return function (bytes)
    local name = os.tmpname()
    local file = io.open(name, "w+b")
    if not file then return end
    file:write(bytes)
    file:close()
    local module = ffi.load(name)
    os.remove(name)
    return module
end