local errors = require("libs.error_handler")
local o_require = require
require = function (lib)
    local result = nil
    errors.handler(function()
        result = o_require(lib)
    end)()
    return result
end

