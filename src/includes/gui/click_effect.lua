local anims = require("libs.anims")
local col = require("libs.colors")
local click_effects = {
    ---@type { pos: vec2_t, anims: __anims_mt }[]
    list = {},
}
click_effects.draw = function()
    for i = #click_effects.list, 1, -1 do
        local effect = click_effects.list[i]
        if effect then
            local alpha = effect.anims.alpha(0)
            local size = effect.anims.size(12)
            if alpha <= 0 then
                table.remove(click_effects.list, i)
            else
                renderer.circle(effect.pos, size, 15, true, col(255, 255, 255, alpha))
            end
        end
    end
end
click_effects.add = function()
    local pos = renderer.get_cursor_pos()
    table.insert(click_effects.list, {
        pos = pos,
        anims = anims.new({
            alpha = 175,
            size = 0,
        }),
    })
end

return click_effects