local cbs = require("libs.callbacks")
local fns = {}
cbs.paint(function()
    for i = 1, #fns do
        if fns[i] and fns[i].time <= globalvars.get_real_time() then
            fns[i].fn()
            table.remove(fns, i)
        end
    end
end)

return {
    add = function(fn, time)
        fns[#fns+1] = {
            fn = fn,
            time = globalvars.get_real_time() + time / 1000,
        }
    end,
}