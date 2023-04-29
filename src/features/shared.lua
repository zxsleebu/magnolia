local sockets = require("libs.sockets")
local cbs = require("libs.callbacks")
local iengine = require("includes.engine")

local shared = {}
---@class __shared_features_t
---@field logo gui_checkbox_t
shared.elements = {}
shared.features = {}

shared.features.presence = function()
    iengine.log("presence called")
    local lp = entitylist.get_local_player()
    if not lp then return end
    print(tostring(iengine.get_server_info().ip))
end

sockets.add("on_socket_init", function(websocket)
    shared.features.presence()
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

cbs.add("create_move", function()
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive() then return end
    ---@type entity_t
    local playerresource = entitylist.get_entities_by_class_id(41)
    if not playerresource or #playerresource == 0 then return end
    playerresource = playerresource[1]
    playerresource.m_nPersonaDataPublicLevel[lp:get_index()] = 2244
end)

return shared