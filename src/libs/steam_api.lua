local iengine = require("includes.engine")
ffi.cdef[[
    void* GetModuleHandleA(const char*);
]]
local steam_api = ffi.C.GetModuleHandleA("steam_api.dll")
local steam_context = iengine.get_steam_context()
---@class __steam_api
local raw_steam = {
    User = {
        GetSteamID = "uint64_t(*)(void*)"
    }
}
for i_name, i in pairs(raw_steam) do
    for f_name, f_type in pairs(i) do
        local casted_fn = ffi.cast(f_type, ffi.C.GetProcAddress(steam_api, "SteamAPI_ISteam"..i_name.."_"..f_name))
        i[f_name] = function (...)
            if not steam_context[i_name] or steam_context[i_name] == nil then
                error("SteamAPI: "..i_name.." is not initialized")
                return
            end
            return casted_fn(steam_context[i_name], ...)
        end
    end
end

local steam = {}
steam.get_steam_id = function ()
    local result = tostring(raw_steam.User.GetSteamID())
    return result:sub(1, #result-3)
end

return steam