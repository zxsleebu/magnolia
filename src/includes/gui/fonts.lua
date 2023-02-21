local render = require("libs.render")
local fonts = {
    logo = render.font("nix/magnolia/icon.ttf", 24),
    tab_icons = render.font("nix/magnolia/icon.ttf", 14),
    header = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, 0),
    menu = render.font("C:/Windows/Fonts/segoeui.ttf", 16, 0),
    avatar_question = render.font("C:/Windows/Fonts/trebucbd.ttf", 13, render.font_flags.Bold),
    title_icon = render.font("nix/magnolia/icon.ttf", 18),
    tab_title = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
}
return fonts