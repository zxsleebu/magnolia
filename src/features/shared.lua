local sockets = require("libs.sockets")
local cbs = require("libs.callbacks")
local iengine = require("includes.engine")
local steam = require("libs.steam_api")
local security = require("includes.security")
local errors = require("libs.error_handler")
local delay = require("libs.delay")

local shared = {}
---@class __shared_features_t
---@field logo gui_checkbox_t
shared.elements = {}
shared.features = {}

local last_time_presence = globalvars.get_real_time() + 10
shared.features.presence = function()
    if not sockets.websocket then return end
    last_time_presence = globalvars.get_real_time()
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
    iengine.log("update players")
    if not engine.is_in_game() then return end
    local playerresource = entitylist.get_entities_by_class_id(41)[1]
    if not playerresource then return end
    for cached_steam_id, cached in pairs(player_cache) do
        local entity = entitylist.get_entity_by_steam_id(cached_steam_id)
        if entity then
            iengine.log("update presence on " .. entity:get_info().name)
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
end, "shared.features.update_players")

local last_heartbeat = globalvars.get_real_time()

cbs.add("paint", function ()
    if not sockets.websocket then return end
    local realtime = globalvars.get_real_time()
    if realtime > last_heartbeat + 20 then
        if security.debug_logs then
            iengine.log("heartbeat called")
        end
        sockets.send({type = "heartbeat"})
        last_heartbeat = realtime
    end
    if not engine.is_in_game() then return end
    if globalvars.get_real_time() - last_time_presence > 120 then
        shared.features.presence()
    end
end)

sockets.add("on_socket_init", function()
    if engine.is_in_game() then return end
    shared.features.presence()
end)


sockets.add("player", function(data)
    local steam_id = data.steam_id
    player_cache[steam_id] = player_cache[steam_id] or {}
    player_cache[steam_id].time = globalvars.get_real_time()
    if data.unload then
        player_cache[steam_id].revoke = true
    end
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
            shared.features.update_players()
        end
    else
        if was_connected then
            shared.features.presence()
        end
        was_connected = false
    end
end)

cbs.event("player_spawn", function()
    delay.add(shared.features.update_players, 3000)
end)
cbs.add("unload", function()
    if security.debug_logs then
        iengine.log("unload")
    end
    sockets.send({type = "unload"}, true)
    if not engine.is_in_game() then return end
    for cached_steam_id, _ in pairs(player_cache) do
        player_cache[cached_steam_id].revoke = true
    end
    shared.features.update_players()
end)

return shared