console.log("Starting build process...")
//change working directory to the root of the project
const { writeFileSync, readFileSync } = require('fs');
const { execSync } = require('child_process');
const luactor = require('luactor');
const { bundle } = require('luabundle');

console.log("Bundling...")
process.chdir(__dirname + "/../src/");
var bundledLua = bundle('magnolia.lua', {
    // paths: ['../src/?.lua', '../src/?/init.lua'],
    metadata: false,
    luaVersion: "LuaJIT",
});
//create dist and temp directories if they don't exist
try {
    fs.mkdirSync('../dist');
} catch (e) { }
try {
    fs.mkdirSync('../dist/temp');
} catch (e) { }
writeFileSync('../dist/temp/magnolia_bundled.lua', bundledLua);
console.log("Bundled!")
process.chdir(__dirname + "/../")

// execSync('"builder/Prometheus/luajit.exe" "builder/Prometheus/cli.lua" --c builder/Prometheus/config.lua dist/temp/magnolia_bundled.lua --o dist/temp/magnolia_virtualized.lua',
    // { stdio: 'inherit' })
// var virtualizedLua = readFileSync('dist/temp/magnolia_virtualized.lua', 'utf8');
// console.log("Virtualized!")

var luac = new luactor({
    // antidecompiler: false,
    // scoper: false,
    // thiscallproxy: false,
    // literals: false,
    // objects: false,
    // globals: false,
    // functions: false,
    // jit: false
});
// luac.compile(virtualizedLua, 'dist/magnolia_build.lua')
luac.compile(bundledLua, 'dist/magnolia_build.lua')