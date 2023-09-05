local win32 = require("libs.win32")
local utils = require("libs.utils")
local vmt_hook = {
    __index = {
        ---@generic T
        ---@param cast string
        ---@param func T
        ---@param method number
        ---@return T
        hookMethod = function(h, cast, func, method)
            h.hook[method] = func
            jit.off(h.hook[method], true)
            h.orig[method] = h.vt[method]
            win32.VirtualProtect(h.vt + method, 4, 0x4, h.prot)
            h.vt[method] = ffi.cast('intptr_t', ffi.cast(cast, h.hook[method]))
            win32.VirtualProtect(h.vt + method, 4, h.prot[0], h.prot)
            return ffi.cast(cast, h.orig[method])
        end,
        unHookMethod = function(h, method)
            if not h.orig[method] then return end
            h.hook[method] = function() end
            win32.VirtualProtect(h.vt + method, 4, 0x4, h.prot)
            local alloc_addr = win32.VirtualAlloc(nil, 5, 0x1000, 0x40, false)
            if not alloc_addr then return end
            local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)
            trampoline_bytes[0] = 0xE9
            ffi.cast('int32_t*', trampoline_bytes + 1)[0] = h.orig[method] - tonumber(alloc_addr) - 5
            win32.copy(alloc_addr, trampoline_bytes, 5)
            h.vt[method] = ffi.cast('intptr_t', alloc_addr)
            win32.VirtualProtect(h.vt + method, 4, h.prot[0], h.prot)
            h.orig[method] = nil
        end,
        unHookAll = function(h)
            for method, _ in pairs(h.orig) do h:unHookMethod(method) end
        end
    },
}
vmt_hook.new = function(vt)
    if not vt or vt == 0 or vt == nil then
        error('vmt_hook.new: invalid vtable pointer')
    end
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
---@param callback fun(...): any
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
        win32.VirtualProtect(void_addr, size, 0x40, old_prot)
        win32.copy(void_addr, bool and hook_bytes or org_bytes, size)
        win32.VirtualProtect(void_addr, size, old_prot[0], old_prot)
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

local jmp_hook_2 = {
    list = {},
    rel_jmp = function(address)
        local addr = ffi.cast("uintptr_t", address)
        local jmp_addr = ffi.cast("uintptr_t", addr)
        local jmp_disp = ffi.cast("int32_t*", jmp_addr + 0x1)[0]
        return ffi.cast("uintptr_t", jmp_addr + 0x5 + jmp_disp)
    end
}
local hook = ffi.cast("int(__cdecl*)(void*, void*, void*, int)", utils.find_pattern("gameoverlayrenderer", "55 8B EC 51 8B 45 10 C7"))
local unhook = ffi.cast("void(__cdecl*)(void*, bool)", jmp_hook_2.rel_jmp(utils.find_pattern("gameoverlayrenderer", "E8 ? ? ? ? 83 C4 08 FF 15 ? ? ? ?")))
---@param cast string
---@param callback fun(orig: function, ...): function
---@param address any
jmp_hook_2.new = function(cast, callback, address)
    local addr_pointer = ffi.cast("void*", address)
    local typedef = ffi.typeof(cast)

    local callback_fn = ffi.cast(typedef, callback)
    local original_pointer = ffi.typeof("$[1]", callback_fn)()

    local function actual_callback(...)
        local original = original_pointer[0]

        local call, result = pcall(callback, original, ...)
        if not call then
            return original(...)
        end

        return result
    end

    local callback_type = ffi.cast(typedef, actual_callback)

    local result = hook(addr_pointer, callback_type, original_pointer, 0)
    if result == 1 then

    elseif result == 0 then
        if type(address) ~= "number" then
            return print(("[EPIC FAIL] Failed to hook function! Unknown calling conv.!"))
        end

        print(("[EPIC FAIL] Failed to hook function! Addr: 0x%x!!!"):format(address or 0))
    end

    return {
        unhook = function()
            unhook(addr_pointer, true)
        end
    }
end

return {
    vmt = vmt_hook,
    jmp = jmp_hook,
    jmp2 = jmp_hook_2
}
