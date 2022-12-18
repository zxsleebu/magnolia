local utf8 = {}
utf8.char = function(val)
    local c = string.char
    local bm = { { 0x7FF, 192 }, { 0xFFFF, 224 }, { 0x1FFFFF, 240 } }
    if val < 128 then return c(val) end
    local cbts = {}
    for bts, vals in ipairs(bm) do
        if val <= vals[1] then
            for b = bts + 1, 2, -1 do
                local mod = val % 64
                val = (val - mod) / 64
                cbts[b] = c(128 + mod)
            end
            cbts[1] = c(vals[2] + val)
            break
        end
    end
    return table.concat(cbts)
end
utf8.byte = function(char)
    local c = 0
    local bytes = { string.byte(char, 1, -1) }
    for _, v in ipairs(bytes) do
        if v > 127 then
            c = (c * 64) + (v % 64)
        else
            c = v
            break
        end
    end
    return c
end
local unescape_bytes = function(str)
    return str:gsub("\\([0-9A-F]+)", function(a)
        return utf8.char(tonumber(a, 16))
    end)
end
local pattern = "[%z\\1-\\127\\194-\\244][\\128-\\191]*"
local unescaped_pattern = unescape_bytes(pattern)
utf8.map = function(str, fn)
    return str:gsub(unescaped_pattern, fn)
end
return utf8