local ffi = require("ffi")
local nixware = ffi.load("lua/libs/nixware")
local error_handler, report = require("libs.error_handler")()
ffi.cdef[[
    typedef unsigned long DWORD;
    DWORD GetAllocbase();
]]
local nix = {
    allocbase = 0,
}
nix.init = function()
    local allocbase = nixware.GetAllocbase()
    if allocbase == 0 then report("couldn't find allocbase") end
    nix.allocbase = allocbase
    print(string.format("allocbase: 0x%X", allocbase))
end

return nix