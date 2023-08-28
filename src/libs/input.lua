local cbs = require("libs.callbacks")
local user32 = ffi.load("user32.dll")
local v2 = require("libs.vectors")()
require("libs.types")
ffi.cdef([[
    short GetAsyncKeyState(int);
    typedef struct {
        long x;
        long y;
    } POINT;
    typedef struct {
        DWORD cbSize;
        DWORD flags;
        void* hCursor;
        POINT ptScreenPos;
    } CURSORINFO;
    bool GetCursorInfo(CURSORINFO*);
    void* GetForegroundWindow();
    BOOL GetCursorPos(POINT*);
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
    local inter = menu.is_visible() or not is_cursor_visible()
    return focused and inter
end
local input = {
    ---@param code number
    ---@return boolean
    is_key_pressed = function (code)
        return ffi.C.GetAsyncKeyState(code) ~= 0 and is_window_active()
    end
}
---@param code number
---@return boolean
input.is_key_clicked = function(code)
    local state = input.is_key_pressed(code)
    if click_state[code] == nil then
        click_state[code] = {
            state = state,
            clicked = false,
            time = false,
        }
    end
    return click_state[code].clicked
end
---@param code number
---@return number
input.get_key_pressed_time = function (code)
    if click_state[code] == nil then
        click_state[code] = {
            state = false,
            clicked = false,
            time = false
        }
    end
    if click_state[code].time == false then
        return 0
    end
    return globals.real_time - click_state[code].time
end
---@return vec2_t
input.cursor_pos = function()
    local pos = ffi.new("POINT")
    user32.GetCursorPos(pos)
    return v2(pos.x, pos.y)
end
cbs.paint(function()
    local realtime = globals.real_time
    for code, _ in pairs(click_state) do
        local state = input.is_key_pressed(code)
        click_state[code] = {
            state = state,
            clicked = state and not click_state[code].state,
            time = click_state[code].time
        }
        if click_state[code].time == false and state then
            click_state[code].time = realtime
        end
        if not state then
            click_state[code].time = false
        end
    end
end)
return input