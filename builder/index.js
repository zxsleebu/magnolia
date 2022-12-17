//change working directory to the root of the project
process.chdir(__dirname + "/../src/");
const { bundle } = require('luabundle');
const { writeFileSync } = require('fs');
var bundledLua = bundle('magnolia.lua', {
    metadata: false,
    luaVersion: "LuaJIT",
});
writeFileSync('../dist/magnolia_build.lua', bundledLua);