local render = require("libs.render")
local fonts = {
    logo = render.font("nix/magnolia/icon.ttf", 28),
    logo_shadow = render.font("nix/magnolia/icon.ttf", 32),
    tab_icons = render.font("nix/magnolia/icon.ttf", 16),
    header = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    menu = render.font("C:/Windows/Fonts/trebuc.ttf", 16, 0),
    slider = render.font("C:/Windows/Fonts/trebuc.ttf", 24, 0),
    slider_small = render.font("C:/Windows/Fonts/trebuc.ttf", 8, render.font_flags.ForceAutoHint),
    avatar_question = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, render.font_flags.Bold),
    title_icon = render.font("nix/magnolia/icon.ttf", 21),
    tab_title = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    subtab_title = render.font("C:/Windows/Fonts/trebucbd.ttf", 10, 0),
    menu_icons = render.font("nix/magnolia/icon.ttf", 16),
}
return fonts