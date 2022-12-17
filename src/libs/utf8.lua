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
    local b = string.byte
    local c = 0
    local bm = { [0] = 0, 0x7F, 0x7FF, 0xFFFF, 0x1FFFFF }
    local bytes = { b(char, 1, -1) }
    for i, v in ipairs(bytes) do
        if v > 127 then
            c = (c * 64) + (v % 64)
        else
            c = v
            break
        end
    end
    return c
end
utf8.map = function(str, fn)
    return str:gsub("[%z\1-\127\194-\244][\128-\191]*", fn)
end
return utf8