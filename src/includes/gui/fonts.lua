local render = require("libs.render")
local fonts = {
    logo = render.font("nix/magnolia/icon.ttf", 28),
    logo_shadow = render.font("nix/magnolia/icon.ttf", 32),
    tab_icons = render.font("nix/magnolia/icon.ttf", 16),
    header = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    menu = render.font("C:/Windows/Fonts/trebuc.ttf", 16, 0),
    avatar_question = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, render.font_flags.Bold),
    title_icon = render.font("nix/magnolia/icon.ttf", 21),
    tab_title = render.font("C:/Windows/Fonts/trebucbd.ttf", 18, 0),
}
return fonts