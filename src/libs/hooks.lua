ffi.cdef[[
    typedef unsigned long DWORD;
    int VirtualProtect(void*, DWORD, DWORD, DWORD*);
    void* VirtualAlloc(void*, DWORD, DWORD, DWORD);
]]
local copy = function(dst, src, len)
    ffi.copy(ffi.cast('void*', dst), ffi.cast('const void*', src), len)
end
local VirtualProtect = function(addr, size, new_protect, old_protect)
    return ffi.C.VirtualProtect(ffi.cast('void*', addr), size, new_protect, old_protect)
end
local VirtualAllocBuff = {free = {}}
local VirtualAlloc = function(addr, size, alloctype, protect, free)
    local alloc = ffi.C.VirtualAlloc(addr, size, alloctype, protect)
    if free then table.insert(VirtualAllocBuff.free, alloc) end
    return ffi.cast('intptr_t', alloc)
end
local vmt_hook = {
    __index = {
        hookMethod = function(h, cast, func, method)
            h.hook[method] = func
            jit.off(h.hook[method], true)
            h.orig[method] = h.vt[method]
            VirtualProtect(h.vt + method, 4, 0x4, h.prot)
            h.vt[method] = ffi.cast('intptr_t', ffi.cast(cast, h.hook[method]))
            VirtualProtect(h.vt + method, 4, h.prot[0], h.prot)
            return ffi.cast(cast, h.orig[method])
        end,
        unHookMethod = function(h, method)
            if not h.orig[method] then return end
            h.hook[method] = function() end
            VirtualProtect(h.vt + method, 4, 0x4, h.prot)
            local alloc_addr = VirtualAlloc(nil, 5, 0x1000, 0x40, false)
            if not alloc_addr then return end
            local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)
            trampoline_bytes[0] = 0xE9
            ffi.cast('int32_t*', trampoline_bytes + 1)[0] = h.orig[method] - tonumber(alloc_addr) - 5
            copy(alloc_addr, trampoline_bytes, 5)
            h.vt[method] = ffi.cast('intptr_t', alloc_addr)
            VirtualProtect(h.vt + method, 4, h.prot[0], h.prot)
            h.orig[method] = nil
        end,
        unHookAll = function(h)
            for method, _ in pairs(h.orig) do h:unHookMethod(method) end
        end
    },
}
vmt_hook.new = function(vt)
    return setmetatable({
        orig = {},
        vt = ffi.cast('intptr_t**', vt)[0],
        prot = ffi.new('unsigned long[1]'),
        hook = {}
    }, vmt_hook)
end

local jmp_hook = {
    hooks = {},
    ---@class jmp_hook_t
    -- __index = {
    --     set_status = function(s, bool)
    --         s.status = bool
    --         VirtualProtect(s.address, s.size, 0x40, s.old_protect)
    --         copy(s.address, bool and s.hook_bytes or s.org_bytes, s.size)
    --         VirtualProtect(s.address, s.size, s.old_protect[0], s.old_protect)
    --     end,
    --     stop = function(s) s:set_status(false) end,
    --     start = function(s) s:set_status(true) end,
    --     __call = function(s, ...)
    --         if s.trampoline then
    --             return s.call(...)
    --         end
    --         s:stop()
    --         local res = s.call(...)
    --         s:start()
    --         return res
    --     end
    -- }
}

---@param cast string
---@param callback fun(orig: fun(...): any): fun(...)
---@param address ffi.ctype*|number|nil
---@param size? number
function jmp_hook.new(cast, callback, address, size)
    jit.off(callback, true)
    size = size or 5
    local new_hook = {}
    local detour_addr = tonumber(ffi.cast('intptr_t', ffi.cast('void*', ffi.cast(cast, callback))))
    local void_addr = ffi.cast('void*', address)
    local old_prot = ffi.new('unsigned long[1]')
    local org_bytes = ffi.new('uint8_t[?]', size)
    ffi.copy(org_bytes, void_addr, size)
    local hook_bytes = ffi.new('uint8_t[?]', size, 0x90)
    hook_bytes[0] = 0xE9
    ffi.cast('uint32_t*', hook_bytes + 1)[0] = detour_addr - tonumber(ffi.cast("intptr_t", address)) - 5
    new_hook.call = ffi.cast(cast, address)
    new_hook.status = false
    local function set_status(bool)
        new_hook.status = bool
        VirtualProtect(void_addr, size, 0x40, old_prot)
        copy(void_addr, bool and hook_bytes or org_bytes, size)
        VirtualProtect(void_addr, size, old_prot[0], old_prot)
    end
    new_hook.stop = function() set_status(false) end
    new_hook.start = function() set_status(true) end
    new_hook.start()
    table.insert(jmp_hook.hooks, new_hook)
    return setmetatable(new_hook, {
        __call = function(self, ...)
            self.stop()
            local res = self.call(...)
            self.start()
            return res
        end
    })
end

-- ---@param cast string
-- ---@param callback fun(orig: fun(...): any): fun(...)
-- ---@param address ffi.ctype*|number|nil
-- jmp_hook.new_new = function(cast, callback, address)
--     if address == nil then return end
--     -- local hook_bytes = {0x04, 0xF0, 0x1F, 0xE5, 0xDE, 0xAD, 0xBE, 0xEF}
--     local hook_bytes = {0xE9}
--     local s = setmetatable({
--         old_protect = ffi.new('unsigned long[1]'),
--         address = address,
--         size = #hook_bytes + 4,
--     }, jmp_hook)
--     local original_fn = ffi.cast(cast, address)
--     local call = function(...)
--         s:stop()
--         local res = original_fn(...)
--         s:start()
--         return res
--     end
--     local hook_fn = ffi.cast(cast, callback(call))
--     local offset = ffi.cast("intptr_t", hook_fn) - ffi.cast("intptr_t", address) - #hook_bytes - 4
--     s.hook_bytes = ffi.new('uint8_t[?]', s.size, hook_bytes)
--     ffi.cast("uint32_t*", s.hook_bytes + #hook_bytes)[0] = ffi.cast('intptr_t', offset)

--     s.org_bytes = ffi.new('uint8_t[?]', s.size)
--     copy(s.org_bytes, address, s.size)

--     s:set_status(true)
--     return s
-- end

return {
    vmt = vmt_hook,
    jmp = jmp_hook
}
