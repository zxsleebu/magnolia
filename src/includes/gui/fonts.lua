local render = require("libs.render")
local fonts = {
    logo = render.font("nix/magnolia/icon.ttf", 24),
    tab_icons = render.font("nix/magnolia/icon.ttf", 14),
    header = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, 0),
    avatar_question = render.font("C:/Windows/Fonts/trebucbd.ttf", 9, render.font_flags.Bold),
}
return fonts