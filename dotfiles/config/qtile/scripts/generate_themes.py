#!/usr/bin/env python3
"""Generate theme template files for dunst and rofi from colors.py."""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from colors import (
    catppuccin, doomone, dracula, everforest, github_dark, gruvbox,
    gruvbox_light, kanagawa, monokai, moonfly, nord, retro,
)

THEMES_DIR = os.path.join(os.path.dirname(__file__), "..", "themes")

THEME_FUNCS = {
    "catppuccin": catppuccin,
    "doomone": doomone,
    "dracula": dracula,
    "everforest": everforest,
    "github_dark": github_dark,
    "gruvbox": gruvbox,
    "gruvbox_light": gruvbox_light,
    "kanagawa": kanagawa,
    "monokai": monokai,
    "moonfly": moonfly,
    "nord": nord,
    "retro": retro,
}


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def rgb_to_hex(r, g, b):
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}"


def darken(hex_color, factor=0.4):
    r, g, b = hex_to_rgb(hex_color)
    return rgb_to_hex(r * (1 - factor), g * (1 - factor), b * (1 - factor))


def generate_dunstrc(colors, bg, fg, workspace, fg2):
    c = [x[0] for x in colors]
    frame = c[3]
    crit_frame = c[6]
    low_bg = darken(bg, 0.2)
    crit_bg = darken(c[9], 0.7)

    return f"""[global]
    # Display
    monitor = 0
    follow = keyboard
    origin = top-right
    offset = 10x50
    width = 500
    height = 300
    indicate_hidden = yes
    shrink = no
    transparency = 0
    separator_height = 2
    padding = 15
    horizontal_padding = 15
    frame_width = 3
    frame_color = "{frame}"
    separator_color = auto
    sort = yes
    idle_threshold = 120

    # Text
    font = JetBrainsMono Nerd Font 11
    line_height = 2
    markup = full
    format = "<b>%s</b>\\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 30
    word_wrap = yes
    ellipsize = middle
    ignore_newline = yes
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes

    # Icons
    icon_position = left
    min_icon_size = 16
    max_icon_size = 32
    enable_recursive_icon_lookup = true
    icon_path = /usr/share/icons/Papirus/96x96/devices/:/usr/share/icons/Papirus/48x48/status/:/usr/share/icons/Papirus/96x96/apps/

    # History
    sticky_history = yes
    history_length = 20

    # Advanced
    dmenu = /usr/bin/dmenu -p dunst:
    browser = /usr/bin/firefox -new-tab
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 15
    force_xinerama = false

    # Progress bar
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    # Misc
    notification_limit = 5
    ignore_dbusclose = false

    # Mouse actions
    mouse_left_click = close_current
    mouse_middle_click = do_action
    mouse_right_click = close_all

    # Keyboard shortcuts
    close = ctrl+space
    close_all = ctrl+shift+space
    history = ctrl+grave
    context = ctrl+shift+period

[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "{low_bg}"
    foreground = "{c[3]}"
    frame_color = "{c[3]}"
    timeout = 10
    highlight = "{c[3]}"

[urgency_normal]
    background = "{low_bg}"
    foreground = "{fg}"
    frame_color = "{frame}"
    timeout = 10
    highlight = "{c[4]}"

[urgency_critical]
    background = "{crit_bg}"
    foreground = "{fg}"
    frame_color = "{crit_frame}"
    timeout = 30
    highlight = "{crit_frame}"
"""


def generate_rofi_config(colors, bg, fg, workspace, fg2):
    c = [x[0] for x in colors]
    return f"""  * {{
        bg: {bg};
        background-color: @bg;
    }}

    configuration {{
	    show-icons: true;
	    icon-theme: "Papirus";
	    location: 0;
	    font: "JetBrainsMono Nerd Font 12";
	    display-drun: "Launch:";
    }}

    window {{
	    width: 45%;
	    transparency: "real";
	    orientation: vertical;
	    border-color: {workspace};
        border-radius: 10px;
    }}

    mainbox {{
	    children: [inputbar, listview];
    }}


    // ELEMENT
    // -----------------------------------

    element {{
	    padding: 4 12;
	    text-color: {bg};
        border-radius: 5px;
    }}

    element selected {{
	    text-color: {fg};
	    background-color: {workspace};
    }}

    element-text {{
	    background-color: inherit;
	    text-color: inherit;
    }}

    element-icon {{
	    size: 16 px;
	    background-color: inherit;
	    padding: 0 6 0 0;
	    alignment: vertical;
    }}

	element.selected.active {{
		background-color: {bg};
		text-color: {fg};
	}}

	element.alternate.normal {{
		background-color: {bg};
		text-color: {fg};
	}}


	element.alternate.active {{
		background-color: {workspace};
		text-color: {fg};
	}}

	element.selected.normal {{
		background-color: {workspace};
		text-color: {bg};
	}}


	element.normal.active {{
		background-color: {bg};
		text-color: {fg};
	}}


	element.normal.normal {{
		background-color: {bg};
		text-color: {fg};
	}}

	element.normal.urgent {{
		background-color: {c[9]};
		text-color: {bg};
	}}



    listview {{
	    columns: 2;
	    lines: 9;
	    padding: 8 0;
	    fixed-height: true;
	    fixed-columns: true;
	    fixed-lines: true;
	    border: 0 10 6 10;
    }}

    // INPUT BAR
    //------------------------------------------------

    entry {{
	    text-color: {c[7]};
	    padding: 10 10 0 0;
	    margin: 0 -2 0 0;
    }}

    inputbar {{
	    padding: 10 0 0;
	    margin: 0 0 0 0;
    }}

    prompt {{
	    text-color: {c[3]};
	    padding: 10 6 0 10;
	    margin: 0 -2 0 0;
    }}

"""


def generate_rofi_power(colors, bg, fg, workspace, fg2):
    c = [x[0] for x in colors]
    return f"""* {{
    bg: {bg};
    background-color: @bg;
    font: "JetBrainsMono Nerd Font 12";
}}

configuration {{
    show-icons: true;
    icon-theme: "Papirus";
    location: 0;
    display-drun: "Launch:";
}}

window {{
    width: 20%;
    transparency: "real";
    orientation: vertical;
    border-color: {workspace};
    border-radius: 10px;
}}

mainbox {{
    children: [inputbar, listview];
}}

// ELEMENT
// -----------------------------------

element {{
    padding: 4 8;
    text-color: {fg};
    background-color: {bg};
    border-radius: 5px;
}}

element.selected {{
    text-color: {fg};
    background-color: {workspace};
}}

element-text {{
    background-color: inherit;
    text-color: inherit;
}}

element-icon {{
    size: 16 px;
    background-color: inherit;
    padding: 0 6 0 0;
    alignment: vertical;
}}

element.selected.active {{
    background-color: {bg};
    text-color: {fg};
}}

element.alternate.normal {{
    background-color: {bg};
    text-color: {fg};
}}

element.alternate.active {{
    background-color: {workspace};
    text-color: {fg};
}}

element.selected.normal {{
    background-color: {workspace};
    text-color: {bg};
}}

element.normal.active {{
    background-color: {bg};
    text-color: {fg};
}}

element.normal.normal {{
    background-color: {bg};
    text-color: {fg};
}}

element.normal.urgent {{
    background-color: #ff0000;
    text-color: {bg};
}}

listview {{
    columns: 1;
    lines: 8;
    padding: 8 0;
    fixed-height: true;
    fixed-columns: true;
    fixed-lines: true;
    border: 0 10 6 10;
}}

inputbar {{
    padding: 10 0 0;
    margin: 0 0 0 0;
}}

entry {{
    text-color: {c[7]};
    padding: 10 10 0 0;
    margin: 0 -2 0 0;
}}

prompt {{
    text-color: {c[3]};
    padding: 10 6 0 10;
    margin: 0 -2 0 0;
}}
"""


def generate_rofi_keybinds(colors, bg, fg, workspace, fg2):
    c = [x[0] for x in colors]
    return f"""* {{
    bg: {bg};
    background-color: @bg;
    font: "JetBrainsMono Nerd Font 12";
}}

configuration {{
    show-icons: true;
    icon-theme: "Papirus";
    location: 0;
    display-drun: "Launch:";
}}

window {{
    width: 45%;
    transparency: "real";
    orientation: vertical;
    border-color: {workspace};
    border-radius: 10px;
}}

mainbox {{
    children: [inputbar, listview];
}}

// ELEMENT
// -----------------------------------

element {{
    padding: 4 8;
    text-color: {fg};
    background-color: {bg};
    border-radius: 5px;
}}

element.selected {{
    text-color: {fg};
    background-color: {workspace};
}}

element-text {{
    background-color: inherit;
    text-color: inherit;
}}

element-icon {{
    size: 16 px;
    background-color: inherit;
    padding: 0 6 0 0;
    alignment: vertical;
}}

element.selected.active {{
    background-color: {bg};
    text-color: {fg};
}}

element.alternate.normal {{
    background-color: {bg};
    text-color: {fg};
}}

element.alternate.active {{
    background-color: {workspace};
    text-color: {fg};
}}

element.selected.normal {{
    background-color: {workspace};
    text-color: {bg};
}}

element.normal.active {{
    background-color: {bg};
    text-color: {fg};
}}

element.normal.normal {{
    background-color: {bg};
    text-color: {fg};
}}

element.normal.urgent {{
    background-color: #ff0000;
    text-color: {bg};
}}

listview {{
    columns: 1;
    lines: 24;
    padding: 8 0;
    fixed-height: true;
    fixed-columns: true;
    fixed-lines: true;
    border: 0 10 6 10;
}}

inputbar {{
    padding: 10 0 0;
    margin: 0 0 0 0;
}}

entry {{
    text-color: {c[7]};
    padding: 10 10 0 0;
    margin: 0 -2 0 0;
}}

prompt {{
    text-color: {c[3]};
    padding: 10 6 0 10;
    margin: 0 -2 0 0;
}}
"""


def main():
    os.makedirs(THEMES_DIR, exist_ok=True)

    for name, func in THEME_FUNCS.items():
        colors, bg, fg, workspace, fg2 = func()
        theme_dir = os.path.join(THEMES_DIR, name)
        os.makedirs(theme_dir, exist_ok=True)

        with open(os.path.join(theme_dir, "dunstrc"), "w") as f:
            f.write(generate_dunstrc(colors, bg, fg, workspace, fg2))

        with open(os.path.join(theme_dir, "config.rasi"), "w") as f:
            f.write(generate_rofi_config(colors, bg, fg, workspace, fg2))

        with open(os.path.join(theme_dir, "power.rasi"), "w") as f:
            f.write(generate_rofi_power(colors, bg, fg, workspace, fg2))

        with open(os.path.join(theme_dir, "keybinds.rasi"), "w") as f:
            f.write(generate_rofi_keybinds(colors, bg, fg, workspace, fg2))

        print(f"  Generated: {name}")

    print(f"\nDone. {len(THEME_FUNCS)} themes written to {THEMES_DIR}/")


if __name__ == "__main__":
    main()
