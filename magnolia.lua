local nixware = require("includes.nixware")
local cbs = require("libs.callbacks")
require("includes.loading")
local error_handler = require("libs.error_handler")()
nixware.init()


for callback_name, callback_fns in pairs(cbs.list) do
    client.register_callback(callback_name, function()
        for i = 1, #callback_fns do
            error_handler(callback_fns[i])()
        end
    end)
end