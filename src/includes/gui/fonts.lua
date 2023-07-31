local render = require("libs.render")
local fonts = {
    logo = render.font("nix/magnolia/icon.ttf", 28),
    logo_shadow = render.font("nix/magnolia/icon.ttf", 32),
    tab_icons = render.font("nix/magnolia/icon.ttf", 16),
    header = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    menu = render.font("C:/Windows/Fonts/trebuc.ttf", 16, 0),
    label = render.font("C:/Windows/Fonts/trebuc.ttf", 16, 0),
    menu_small = render.font("C:/Windows/Fonts/trebuc.ttf", 13, 0),
    gamesense = render.font("C:/Windows/Fonts/verdana.ttf", 12, 128 + 16),
    slider = render.font("C:/Windows/Fonts/trebuc.ttf", 24, 0),
    slider_small = render.font("C:/Windows/Fonts/trebuc.ttf", 8, render.font_flags.ForceAutoHint),
    avatar_question = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, render.font_flags.Bold),
    title_icon = render.font("nix/magnolia/icon.ttf", 21),
    tab_title = render.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    subtab_title = render.font("C:/Windows/Fonts/trebucbd.ttf", 10, 0),
    menu_icons = render.font("nix/magnolia/icon.ttf", 22),
    magnolia_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 80, 0),
    percentage_font = render.font("C:/Windows/Fonts/trebucbd.ttf", 14, render.font_flags.MonoHinting),
    large_logo_font = render.font("nix/magnolia/icon.ttf", 250),
    nade_warning = render.font("nix/magnolia/csgo.ttf", 18)
}
return fonts