ffi.cdef([[
    short GetAsyncKeyState(int);
]])
local click_state = {}
local input = {
    ---@param code number
    ---@return boolean
    is_key_pressed = function (code)
        return ffi.C.GetAsyncKeyState(code) ~= 0
    end,
    is_key_clicked = function(code)
        local state = ffi.C.GetAsyncKeyState(code) ~= 0
        if click_state[code] == nil then
            click_state[code] = state
        end
        local clicked = state and not click_state[code]
        click_state[code] = state
        return clicked
    end
}
return input