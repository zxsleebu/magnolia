local kernel32 = ffi.load('kernel32')
local cbs = require("libs.callbacks")
require("libs.types")
ffi.cdef[[
    typedef DWORD(__stdcall* PTHREAD_START_ROUTINE)(void* lpThreadParameter);
    HANDLE CreateThread(
        void* lpThreadAttributes,
        SIZE_T dwStackSize,
        PTHREAD_START_ROUTINE lpStartAddress,
        void* lpParameter,
        DWORD dwCreationFlags,
        DWORD* lpThreadId
    );
    BOOL CloseHandle(HANDLE hObject);
    BOOL TerminateThread(HANDLE hThread, DWORD dwExitCode);
    void Sleep(DWORD dwMilliseconds);
]]
local thread_t = {
    ---@class thread_t
    __index = {
        start = function(s)
            if s.running then return s end
            s.running = true
            s.handle = kernel32.CreateThread(nil, 0, s.fn, nil, 0, s.id)
            return s
        end,
        stop = function(s)
            if not s.running then return s end
            s.running = false
            kernel32.TerminateThread(s.handle, 0)
            kernel32.CloseHandle(s.handle)
            return s
        end,
        sleep = function(s, ms)
            kernel32.Sleep(ms)
        end
    },
    __gc = function(s)
        s:stop()
    end,
}
local threads = {}
local thread = {}
---@param fn fun(t: thread_t)
thread.new = function(fn)
    jit.off()
    local id = ffi.new('DWORD[1]')
    local t = setmetatable({
        handle = nil,
        id = id,
        running = false,
    }, thread_t)
    t.fn = function(thread_parameter)
        pcall(fn, t)
        return 0
    end
    table.insert(threads, t)
    t:start()
    return t
end
thread.stop = function()
    for i = 1, #threads do
        threads[i]:stop()
    end
end
cbs.add("unload", thread.stop)
return thread