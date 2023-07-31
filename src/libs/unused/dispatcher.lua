local cbs = require("libs.callbacks")
local dispatcher_t = {
    query = {}
}
dispatcher_t.add = function(fn)
    dispatcher_t.query[#dispatcher_t.query + 1] = fn
end
cbs.paint(function()
    for i, v in pairs(dispatcher_t.query) do
        v()
    end
    dispatcher_t.query = {}
end)

return dispatcher_t