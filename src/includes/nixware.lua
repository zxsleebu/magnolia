local ffi = require("ffi")
require("libs.types")
local nixware = ffi.load("lua/libs/nixware")
local errors = require("libs.error_handler")
ffi.cdef[[
    DWORD GetAllocbase();
]]
local nix = {
    allocbase = 0,
}
nix.init = function()
    local allocbase = nixware.GetAllocbase()
    if allocbase == 0 then errors.report("couldn't find allocbase") end
    nix.allocbase = allocbase
    print(string.format("allocbase: 0x%X", allocbase))
end

return nix