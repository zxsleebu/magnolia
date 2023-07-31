local ffi = require("libs.protected_ffi")
require("libs.types")
local errors = require("libs.error_handler")
ffi.cdef[[
    typedef struct {
        void*   BaseAddress;
        void*   AllocationBase;
        DWORD   AllocationProtect;
        WORD    PartitionId;
        SIZE_T  RegionSize;
        DWORD   State;
        DWORD   Protect;
        DWORD   Type;
    } MEMORY_BASIC_INFORMATION;
    size_t VirtualQueryEx(void*, const void*, MEMORY_BASIC_INFORMATION*, size_t);
    void* GetCurrentProcess();
    BOOL ReadProcessMemory(void*, const void*, void*, SIZE_T, SIZE_T*);
    BOOL WriteProcessMemory(void*, void*, const void*, SIZE_T, SIZE_T*);
    BOOL VirtualProtectEx(void*, void*, SIZE_T, DWORD, DWORD*);
]]

local setup_bones = client.find_pattern("client.dll", "? ? ? ? ? F0 B8 ? ? ? ? E8 ? ? ? ? 56 57 8B F9 8B")
if setup_bones == 0 then return end
local hook_func = ffi.cast("uintptr_t*", setup_bones + 1)
if not hook_func then return end
local jmp_address = hook_func[0] + setup_bones + 5

local module_start = 0
local module_end = 0


do
    local mbi = ffi.new("MEMORY_BASIC_INFORMATION[1]")
    local size = ffi.sizeof("MEMORY_BASIC_INFORMATION")
    local proc = ffi.C.GetCurrentProcess()
    ffi.C.VirtualQueryEx(proc, ffi.cast("void*", jmp_address), mbi, size)

    module_start = tonumber(ffi.cast("uintptr_t", mbi[0].AllocationBase))

    local old_allocation_base = mbi[0].AllocationBase
    local last_address = mbi[0].AllocationBase

    for i = 1, 999 do
        ffi.C.VirtualQueryEx(proc, ffi.cast("void*", last_address), mbi, size)
        last_address = ffi.cast("uintptr_t", mbi[0].BaseAddress) + 1024 * 1024
        if mbi[0].AllocationBase ~= nil and mbi[0].AllocationBase ~= old_allocation_base then
            module_end = tonumber(ffi.cast("uintptr_t", mbi[0].AllocationBase))
            break
        end
    end
end
local split = function (inputstr, sep)
    if sep == nil then
        sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str) end
    return t
end
local find_pattern_in_region = function(from, to, pattern)
    local ptr = ffi.cast("void*", from)
    local search_size = to - from
    local buffer = ffi.new("BYTE[?]", search_size)
    if ffi.C.ReadProcessMemory(ffi.C.GetCurrentProcess(), ptr, buffer, search_size, nil) == 0 then
        return 0
    end
    local bytes = split(pattern, " ")
    for i = 1, #bytes do
        if bytes[i] == "?" or bytes[i] == "??" then
            bytes[i] = nil
        else
            bytes[i] = tonumber(bytes[i], 16)
        end
    end
    local matched = 0
    for i = 0, search_size - 1 do
        if buffer[i] == bytes[matched + 1] or bytes[matched + 1] == nil then
            matched = matched + 1
            if matched == #bytes then
                return from + i - #bytes + 1
            end
        else
            matched = 0
        end
    end
    return 0
end
local nixware_t = {
    is_in_range = function(addr)
        local address = tonumber(ffi.cast("uintptr_t", addr))
        return address >= module_start and address <= module_end
    end,
    find_pattern = function(pattern)
        local mbi = ffi.new("MEMORY_BASIC_INFORMATION[1]")
        local size = ffi.sizeof("MEMORY_BASIC_INFORMATION")
        local proc = ffi.C.GetCurrentProcess()
        ffi.C.VirtualQueryEx(proc, ffi.cast("void*", module_start), mbi, size)
        local base_address, region_size
        for i = 1, 99999 do
            base_address = tonumber(ffi.cast("uintptr_t", mbi[0].BaseAddress))
            region_size = tonumber(ffi.cast("uintptr_t", mbi[0].RegionSize))
            local result = find_pattern_in_region(base_address, base_address + region_size, pattern)
            if result ~= 0 then
                return result
            end
            if base_address + region_size >= module_end then return end
            ffi.C.VirtualQueryEx(proc, ffi.cast("void*", base_address + region_size), mbi, size)
        end
    end,
    ---@param address any
    ---@param callback function
    write_memory_callback = function(address, size, callback)
        local proc = ffi.C.GetCurrentProcess()
        local old_protect = ffi.new("DWORD[1]")
        ffi.C.VirtualProtectEx(proc, ffi.cast("void*", address), size, 0x40, old_protect)
        callback()
        ffi.C.VirtualProtectEx(proc, ffi.cast("void*", address), size, old_protect[0], nil)
    end
}
nixware_t.write_memory_bytes = function(address, bytes)
    local size = #bytes
    local addr = ffi.cast("void*", address)
    nixware_t.write_memory_callback(addr, size, function()
        local bytes_buffer = ffi.new("BYTE[?]", size, bytes)
        ffi.copy(addr, bytes_buffer, size)
    end)
end

return nixware_t

