local sockets = require("libs.sockets")
local cbs = require("libs.callbacks")
local iengine = require("includes.engine")
local steam = require("libs.steam_api")
local security = require("includes.security")
local delay = require("libs.delay")
local errors = require("libs.error_handler")

local shared = {}
---@class __shared_features_t
---@field logo gui_checkbox_t
shared.elements = {}
shared.features = {}

shared.features.presence = function()
    if security.debug_logs then
        iengine.log("presence called")
    end
    local server_info = iengine.get_server_info()
    if not server_info then return end
    local data = {
        type = "presence",
        steam_id = steam.get_steam_id(),
        ip = server_info.ip,
    }
    sockets.send(data)
end

local player_cache = {}
shared.features.update_players = errors.handle(function ()
    if not engine.is_in_game() then return end
    local playerresource = entitylist.get_entities_by_class_id(41)[1]
    if not playerresource then return end
    for _, entity in pairs(entitylist.get_players(2)) do
        local entity_steam_id = entity:get_info().steam_id64
        for cached_steam_id, cached in pairs(player_cache) do
            if entity_steam_id == cached_steam_id then
                local index = entity:get_index()
                if not cached.real_rank then
                    player_cache[cached_steam_id].real_rank = playerresource.m_nPersonaDataPublicLevel[index]
                end
                if cached.revoke then
                    playerresource.m_nPersonaDataPublicLevel[index] = player_cache[cached_steam_id].real_rank
                    player_cache[cached_steam_id] = nil
                    break
                end
                playerresource.m_nPersonaDataPublicLevel[index] = 2244
                break
            end
        end
    end
end, "shared.features.update_players")

local interval_presence
interval_presence = function ()
    delay.add(function()
        shared.features.presence()
        interval_presence()
    end, 60000 * 2)
end

sockets.add("on_socket_init", function()
    shared.features.presence()
end)


sockets.add("player", function(data)
    -- print(tostring(data))
    local steam_id = data.steam_id
    player_cache[steam_id] = player_cache[steam_id] or {}
    player_cache[steam_id].time = globalvars.get_real_time()
    shared.features.update_players()
end)

local revoke_players = function ()
    local time = globalvars.get_real_time()
    local revoked = false
    for steam_id, player in pairs(player_cache) do
        if time - player.time > 60 * 3 then
            player_cache[steam_id].revoke = true
            revoked = true
        end
    end
    if revoked then
        shared.features.update_players()
    end
end

local was_connected = false
cbs.add("paint", function ()
    if not sockets.websocket then return end
    if engine.is_in_game() then
        revoke_players()
        if not was_connected then
            was_connected = true
            shared.features.presence()
        end
    else
        if was_connected then
            shared.features.presence()
        end
        was_connected = false
    end
end)

cbs.event("player_spawn", shared.features.update_players)
cbs.add("unload", function()
    if not engine.is_in_game() then return end
    for cached_steam_id, cache in pairs(player_cache) do
        player_cache[cached_steam_id].revoke = true
    end
    shared.features.update_players()
end)

return shared