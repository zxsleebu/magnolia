local sockets = require("libs.sockets")
local cbs = require("libs.callbacks")
local iengine = require("includes.engine")
local steam = require("libs.steam_api")
local security = require("includes.security")

local shared = {}
---@class __shared_features_t
---@field logo gui_checkbox_t
shared.elements = {}
shared.features = {}

shared.features.presence = function(force_disconnected)
    if security.debug_logs then
        iengine.log("presence called")
    end
    local data = {
        type = "presence",
        steam_id = steam.get_steam_id(),
    }
    local server_info = iengine.get_server_info()
    if server_info and not force_disconnected then
        data.ip = server_info.ip
    end
    sockets.send(data)
end

local player_cache = {}
shared.features.update_players = function ()
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
                playerresource.m_nPersonaDataPublicLevel[index] = 2244
                break
            end
        end
    end
end

sockets.add("on_socket_init", function(websocket)
    shared.features.presence()
end)


sockets.add("player", function(websocket, data)
    local steam_id = data.steam_id
    player_cache[steam_id] = player_cache[steam_id] or {}
    shared.features.update_players()
end)

local was_connected = false
cbs.add("paint", function ()
    if engine.is_in_game() then
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
    shared.features.presence(true)
    if not engine.is_in_game() then return end
    local playerresource = entitylist.get_entities_by_class_id(41)[1]
    if not playerresource then return end
    for _, entity in pairs(entitylist.get_players(2)) do
        local entity_steam_id = entity:get_info().steam_id64
        for cached_steam_id, cache in pairs(player_cache) do
            if entity_steam_id == cached_steam_id then
                playerresource.m_nPersonaDataPublicLevel[entity:get_index()] = cache.real_rank
                break
            end
        end
    end
end)

return shared