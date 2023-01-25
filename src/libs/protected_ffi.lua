local offi = ffi
local protected_mt = {
    new = function(original_table)
        return {
            __index = function(_, k)
                local v = original_table[k]
                if type(v) == "function" then
                    return nil
                end
                return v
            end
        }
    end
}
local ffi = {
    cast = offi.cast,
    typeof = offi.typeof,
    metatype = offi.metatype,
    new = offi.new,
    string = offi.string,
    sizeof = offi.sizeof,
    alignof = offi.alignof,
    istype = offi.istype,
    copy = offi.copy,
    fill = offi.fill,
    cdef = offi.cdef,
    gc = offi.gc,
}
ffi.C = setmetatable({}, protected_mt.new(offi.C))
ffi.load = function(lib)
    return setmetatable({}, protected_mt.new(offi.load(lib)))
end

return ffi