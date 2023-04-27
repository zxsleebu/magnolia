local sockets = require("libs.sockets")
local cbs = require("libs.callbacks")
local engine_lib = require("includes.engine")

local shared = {}
---@class __shared_features_t
---@field logo gui_checkbox_t
shared.elements = {}
shared.features = {}

shared.features.presence = function()
    local lp = entitylist.get_local_player()
    if not lp then return end
    local logo = shared.elements.logo
    if not logo:value() then return end
end

sockets.add("on_socket_init", function(websocket)

end)

cbs.event("player_spawn", function (event)
    local user = engine.get_player_for_user_id(event:get_int("userid", 0))
    local lp = entitylist.get_local_player()
    if not lp or lp:get_index() ~= user then return end
    -- shared.features.presence()
end)

return shared