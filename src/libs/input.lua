ffi.cdef([[
    short GetAsyncKeyState(int);
]])
local input = {
    ---@param code number
    ---@return boolean
    is_key_pressed = function (code)
        return ffi.C.GetAsyncKeyState(code) ~= 0
    end
}
return input