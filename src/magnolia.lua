-- jit.off()
-- jit.flush()
-- collectgarbage("stop")

menu.add_check_box("My Checkbox!", "Misc/Misc", false, "magnolia")

math.randomseed(os.time())

require("includes.preload")
local errors = require("libs.error_handler")
errors.handler(function()
    require("includes.gui")
    local cbs = require("libs.callbacks")
    require("includes.loading")

    for callback_name, callback_fns in pairs(cbs.list) do
        register_callback(callback_name, function(...)
            for i = 1, #callback_fns do
                local callback = callback_fns[i]
                errors.handler(callback.fn, callback.name)(...)
            end
            if cbs.critical_list[callback_name] then
                for i = 1, #cbs.critical_list[callback_name] do
                    errors.handler(cbs.critical_list[callback_name][i])(...)
                end
            end
        end)
    end
end, "magnolia")()
-- client.register_callback("unload", function()
--     clientstate.force_full_update()
-- end)