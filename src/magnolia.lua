-- jit.off()
-- jit.flush()
-- collectgarbage("stop")
require("includes.preload")
local errors = require("libs.error_handler")
errors.handle(function()
    require("includes.gui")
    local cbs = require("libs.callbacks")
    require("includes.loading")

    for callback_name, callback_fns in pairs(cbs.list) do
        client.register_callback(callback_name, function()
            for i = 1, #callback_fns do
                errors.handle(callback_fns[i])()
            end
            if cbs.critical_list[callback_name] then
                for i = 1, #cbs.critical_list[callback_name] do
                    errors.handle(cbs.critical_list[callback_name][i])()
                end
            end
        end)
    end
end, "magnolia")()