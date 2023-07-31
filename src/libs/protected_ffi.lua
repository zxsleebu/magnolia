local offi = ffi
local is_hooked = function()
    --!ADD THE CHECK HERE
end
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
    cast = function(ctype, obj)
        local casted = offi.cast(ctype, obj)
        if type(casted) == "function" then
            return nil
        end
        return casted
    end,
    load = function(lib)
        return setmetatable({}, protected_mt.new(offi.load(lib)))
    end,
    C = setmetatable({}, protected_mt.new(offi.C)),
    typeof = offi.typeof,
    metatype = offi.metatype,
    new = offi.new,
    string = offi.string,
    sizeof = offi.sizeof,
    alignof = offi.alignof,
    offsetof = offi.offsetof,
    istype = offi.istype,
    copy = offi.copy,
    fill = offi.fill,
    cdef = offi.cdef,
    gc = offi.gc,
}

return ffi