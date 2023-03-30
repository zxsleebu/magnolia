ffi.cdef([[
    short GetAsyncKeyState(int);
    typedef struct {
        DWORD cbSize;
        DWORD flags;
        void* hCursor;
        POINT ptScreenPos;
    } CURSORINFO;
    bool GetCursorInfo(CURSORINFO*);
    void* GetForegroundWindow();
]])
local click_state = {}
local window_handle = ffi.C.GetForegroundWindow()
local is_cursor_visible = function()
    local cursor = ffi.new("CURSORINFO")
    cursor.cbSize = ffi.sizeof("CURSORINFO")
    ffi.C.GetCursorInfo(cursor)
    return cursor.flags ~= 0
end
local is_window_active = function()
    local focused = ffi.C.GetForegroundWindow() == window_handle
    local inter = ui.is_visible() or not is_cursor_visible()
    return focused and inter
end
local input = {
    ---@param code number
    ---@return boolean
    is_key_pressed = function (code)
        return ffi.C.GetAsyncKeyState(code) ~= 0 and is_window_active()
    end
}
input.is_key_clicked = function(code)
    local state = input.is_key_pressed(code)
    if click_state[code] == nil then
        click_state[code] = state
    end
    local clicked = state and not click_state[code]
    click_state[code] = state
    return clicked
end
return input