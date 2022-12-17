jit.off()
jit.flush()
collectgarbage("stop")
local cbs = require("libs.callbacks")
require("includes.loading")
local errors = require("libs.error_handler")
-- require("libs.websockets")

for callback_name, callback_fns in pairs(cbs.list) do
    client.register_callback(callback_name, function()
        for i = 1, #callback_fns do
            errors.handle(callback_fns[i])()
        end
    end)
end