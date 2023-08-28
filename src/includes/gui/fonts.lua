local irender = require("libs.render")
local fonts = {
    logo = irender.font("nix/magnolia/icon.ttf", 28),
    logo_shadow = irender.font("nix/magnolia/icon.ttf", 32),
    tab_icons = irender.font("nix/magnolia/icon.ttf", 16),
    header = irender.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    menu = irender.font("C:/Windows/Fonts/trebuc.ttf", 16, 0),
    label = irender.font("C:/Windows/Fonts/trebuc.ttf", 16, 0),
    menu_small = irender.font("C:/Windows/Fonts/trebuc.ttf", 13, 0),
    gamesense = irender.font("C:/Windows/Fonts/verdana.ttf", 12, 128 + 16),
    slider = irender.font("C:/Windows/Fonts/trebuc.ttf", 24, 0),
    slider_small = irender.font("C:/Windows/Fonts/trebuc.ttf", 8, irender.font_flags.ForceAutoHint),
    avatar_question = irender.font("C:/Windows/Fonts/trebucbd.ttf", 14, irender.font_flags.Bold),
    title_icon = irender.font("nix/magnolia/icon.ttf", 21),
    tab_title = irender.font("C:/Windows/Fonts/trebucbd.ttf", 16, 0),
    subtab_title = irender.font("C:/Windows/Fonts/trebucbd.ttf", 10, 0),
    menu_icons = irender.font("nix/magnolia/icon.ttf", 22),
    magnolia_font = irender.font("C:/Windows/Fonts/trebucbd.ttf", 80, 0),
    percentage_font = irender.font("C:/Windows/Fonts/trebucbd.ttf", 14, irender.font_flags.MonoHinting),
    large_logo_font = irender.font("nix/magnolia/icon.ttf", 250),
    nade_warning = irender.font("nix/magnolia/csgo.ttf", 18)
}
return fonts