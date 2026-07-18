# Copyright (c) 2025 JustAGuyLinux

from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen, ScratchPad, DropDown
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
import os
import subprocess
from typing import List

from libqtile import hook
from colors import *

def notify_layout():
    """Show current layout in notification"""
    def _notify_layout(qtile):
        layout_name = qtile.current_group.layout.name
        layout_map = {
            "monadtall": "Monad Tall",
            "columns": "Columns", 
            "bsp": "BSP",
            "treetab": "Tree Tab",
            "matrix": "Matrix",
            "plasma": "Plasma",
            "floating": "Floating",
            "spiral": "Spiral",
            "ratiotile": "Ratio Tile",
            "max": "Maximized",
            "monadwide": "Monad Wide",
            "tile": "Tile",
            "verticaltile": "Vertical Tile",
            "stack": "Stack",
            "zoomy": "Zoomy"
        }
        display_name = layout_map.get(layout_name, layout_name.title())
        subprocess.run(["notify-send", "Layout", display_name, "-t", "1500", "-u", "low"])
    return _notify_layout

def notify_restart():
    """Show restart notification"""
    def _notify_restart(qtile):
        subprocess.run(["notify-send", "Qtile", "Restarting...", "-t", "2000", "-u", "normal"])
    return _notify_restart

def toggle_float_center():
    """Toggle floating and center at 75% size"""
    def _toggle_float_center(qtile):
        window = qtile.current_window
        if window:
            was_floating = window.floating
            window.toggle_floating()
            if not was_floating and window.floating:
                # Only resize/center when going from tiled to floating
                screen = qtile.current_screen
                width = int(screen.width * 0.70)
                height = int(screen.height * 0.60)
                window.set_size_floating(width, height)
                window.center()
    return _toggle_float_center

def resize_left():
    """Resize window left - intuitive based on focus"""
    def _resize_left(qtile):
        if not qtile.current_window:
            return
        layout = qtile.current_layout.name
        group = qtile.current_group

        if layout in ["bsp", "columns"]:
            qtile.current_layout.grow_left()
        elif layout in ["monadtall", "monadwide", "tile", "ratiotile"]:
            current_idx = group.windows.index(qtile.current_window)
            if current_idx == 0:
                qtile.current_layout.shrink()
            else:
                qtile.current_layout.grow()
        else:
            qtile.current_layout.shrink()
    return _resize_left

def resize_right():
    """Resize window right - intuitive based on focus"""
    def _resize_right(qtile):
        if not qtile.current_window:
            return
        layout = qtile.current_layout.name
        group = qtile.current_group

        if layout in ["bsp", "columns"]:
            qtile.current_layout.grow_right()
        elif layout in ["monadtall", "monadwide", "tile", "ratiotile"]:
            current_idx = group.windows.index(qtile.current_window)
            if current_idx == 0:
                qtile.current_layout.grow()
            else:
                qtile.current_layout.shrink()
        else:
            qtile.current_layout.grow()
    return _resize_right

def focus_left():
    """Focus window to the left, or cycle if floating"""
    def _focus_left(qtile):
        if not qtile.current_window:
            return
        if qtile.current_layout.name == "floating" or qtile.current_window.floating:
            qtile.current_group.prev_window()
        else:
            qtile.current_layout.left()
    return _focus_left

def focus_right():
    """Focus window to the right, or cycle if floating"""
    def _focus_right(qtile):
        if not qtile.current_window:
            return
        if qtile.current_layout.name == "floating" or qtile.current_window.floating:
            qtile.current_group.next_window()
        else:
            qtile.current_layout.right()
    return _focus_right

@hook.subscribe.startup_once
def autostart():
   home = os.path.expanduser('~/.config/qtile/scripts/autostart.sh')
   subprocess.run([home])

@hook.subscribe.startup
def set_wallpaper():
   autostart = os.path.expanduser('~/.config/qtile/scripts/autostart.sh')
   with open(autostart) as f:
       for line in f:
           if 'feh' in line:
               cmd = line.strip().rstrip('&').strip()
               subprocess.Popen(cmd, shell=True)



mod = "mod4"
terminal = "alacritty"
browser = "firefox"

colors, backgroundColor, foregroundColor, workspaceColor, foregroundColorTwo = github_dark()

keys = [

# Add dedicated sxhkdrc to autostart.sh script

# === WM CONTROL ===
    Key([mod], "q", lazy.window.kill(), desc="Close focused window"),
    Key([mod, "shift"], "r", lazy.function(notify_restart()), lazy.restart(), desc="Restart Qtile"),
    Key([mod, "shift"], "q", lazy.shutdown(), desc="Exit Qtile"),
   #  Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),

# === WINDOW NAVIGATION ===
    Key([mod], "Up", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "Down", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "Left", lazy.function(focus_left()), desc="Move focus left"),
    Key([mod], "Right", lazy.function(focus_right()), desc="Move focus right"),
    
    # CYCLE THROUGH ALL WINDOWS (INCLUDING FLOATING)
    Key([mod], "j", lazy.group.next_window(), desc="Focus next window"),
    Key([mod], "k", lazy.group.prev_window(), desc="Focus previous window"),
    Key(["mod1"], "Tab", lazy.group.next_window(), desc="Alt-Tab window switching"),


# === WINDOW MOVE ===
    Key([mod, "shift"], "k",
        lazy.layout.shuffle_up(),
        lazy.layout.shuffle_left(),
        desc="Move window up/left"),
    Key([mod, "shift"], "j",
        lazy.layout.shuffle_down(),
        lazy.layout.shuffle_right(),
        desc="Move window down/right"),

    Key([mod, "shift"], "Left", 
        lazy.layout.shuffle_left(),
        lazy.layout.swap_left(),
        desc="Move window left"),
    Key([mod, "shift"], "Right", 
        lazy.layout.shuffle_right(),
        lazy.layout.swap_right(),
        desc="Move window right"),
    Key([mod, "shift"], "Up", 
        lazy.layout.shuffle_up(),
        desc="Move window up"),
    Key([mod, "shift"], "Down", 
        lazy.layout.shuffle_down(),
        desc="Move window down"),

# === WINDOW RESIZE ===
    Key([mod, "control"], "Right",
        lazy.function(resize_right()),
        desc="Resize window right"
        ),
    Key([mod, "control"], "Left",
        lazy.function(resize_left()),
        desc="Resize window left"
        ),
    Key([mod, "control"], "Up",
        lazy.layout.grow_up(),
        lazy.layout.grow(),
        lazy.layout.decrease_nmaster(),
        desc="Grow window up"
        ),
    Key([mod, "control"], "Down",
        lazy.layout.grow_down(),
        lazy.layout.shrink(),
        lazy.layout.increase_nmaster(),
        desc="Grow window down"
        ),

# === LAYOUTS ===
    Key([mod], "Tab", lazy.next_layout(), lazy.function(notify_layout()), desc="Toggle between layouts"),
    Key([mod, "shift"], "l", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/layoutmenu")), desc="Layout menu"),
    Key([mod, "shift"], "t", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/thememenu")), desc="Theme switcher"),

# === WINDOW STATE ===
    Key([mod, "shift"], "space",
        lazy.function(toggle_float_center()),
        desc="Toggle floating and center at 75%"),
    Key([mod, "shift"], "z", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod], "t", lazy.layout.toggle_split(), desc="Toggle split direction in BSP"),

# === LAUNCH ===
    Key([mod], "b", lazy.spawn(browser), desc="Launch browser"),
    Key([mod, "shift"], "b", lazy.spawn("firefox -private-window"), desc="Launch Firefox (Private)"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "space", lazy.spawn("rofi -show drun -modi drun -line-padding 4 -hide-scrollbar -show-icons -theme ~/.config/qtile/rofi/config.rasi"), desc="Launch Rofi"),
    Key([mod], "slash", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/help")), desc="Show keybindings"),
    Key([mod], "f", lazy.spawn("thunar"), desc="Launch file manager"),
    Key([mod], "e", lazy.spawn("geany"), desc="Launch text editor"),
    Key([mod], "g", lazy.spawn("gimp"), desc="Launch GIMP"),
    Key([mod], "d", lazy.spawn("Discord"), desc="Launch Discord"),
    Key([mod], "o", lazy.spawn("obs"), desc="Launch OBS"),
    Key([mod], "x", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/power")), desc="Power menu"),

# === MEDIA & BRIGHTNESS ===
    Key([mod], "F12", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume up")), desc="Volume up"),
    Key([mod], "F11", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume down")), desc="Volume down"),
    Key([mod], "F10", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume mute")), desc="Mute/Unmute"),
    Key([], "XF86AudioRaiseVolume", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume up")), desc="Volume up"),
    Key([], "XF86AudioLowerVolume", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume down")), desc="Volume down"),
    Key([], "XF86AudioMute", lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/changevolume mute")), desc="Mute/Unmute"),
    Key([], "XF86MonBrightnessUp", lazy.spawn("xbacklight +10"), desc="Brightness up"),
    Key([], "XF86MonBrightnessDown", lazy.spawn("xbacklight -10"), desc="Brightness down"),

# === SCREENSHOTS ===
    Key([], "Print", lazy.spawn("flameshot full --path " + os.path.expanduser("~/Screenshots/")), desc="Screenshot (full screen)"),
    Key([mod], "Print", lazy.spawn("flameshot gui --path " + os.path.expanduser("~/Screenshots/")), desc="Screenshot (region select)"),
    Key([mod], "s", lazy.spawn("flameshot full --path " + os.path.expanduser("~/Screenshots/")), desc="Screenshot (full screen)"),
    Key([mod, "shift"], "s", lazy.spawn("flameshot gui --path " + os.path.expanduser("~/Screenshots/")), desc="Screenshot (region select)"),
    ]

# Scratchpad keybindings
keys.extend([
    Key([mod, "shift"], "Return", lazy.group['scratchpad'].dropdown_toggle('terminal')),
    Key([mod], "v", lazy.group['scratchpad'].dropdown_toggle('volume'), desc="Toggle volume scratchpad"),
])

# end of keys

#groups = [Group(i) for i in ["", "", "", "", "阮", "", "", "", ""]]
# groups = [Group(i) for i in ["1", "2", "3", "4", "5", "6", "7", "8", "9"]]
groups = [
	Group('1', label="1", layout="monadtall"),
	Group('2', label="2", layout="monadtall"),
	Group('3', label="3", layout="monadtall"),
	Group('4', label="4", layout="monadtall"),
	Group('5', label="5", layout="monadtall"),
	Group('6', label="6", layout="monadtall"),
	Group('7', label="7", layout="monadtall"),
	Group('8', label="8", matches=[Match(wm_class='discord')], layout="monadtall"),
	Group('9', label="9", matches=[Match(wm_class='gimp')], layout="max"),
	Group('0', label="10", matches=[Match(wm_class='obs')], layout="columns"),
	Group('minus', label="11", layout="monadtall"),
	Group('equal', label="12", layout="monadtall"),
]

# Define scratchpads
groups.append(ScratchPad("scratchpad", [
    DropDown("terminal", "st", width=0.6, height=0.6, x=0.2, y=0.02, opacity=0.95),
    DropDown("volume", "st -c volume -e pulsemixer", width=0.5, height=0.5, x=0.25, y=0.02, opacity=0.95),
]))



#groups = [Group(i) for i in ["www", "dev", "dir", "txt", "vid", "mus", "gfx", "dis", "obs"]]
# group_hotkeys = "123456789"

for i in groups:
    if i.name != "scratchpad":  # Skip scratchpad groups
        keys.extend(
            [
                # mod1 + letter of group = switch to group
                Key(
                    [mod],
                    i.name,
                    lazy.group[i.name].toscreen(),
                    desc="Switch to group {}".format(i.name),
                ),
                # mod1 + shift + letter of group = switch to & move focused window to group
                Key(
                    [mod, "shift"],
                    i.name,
                    lazy.window.togroup(i.name, switch_group=True),
                    desc="Switch to & move focused window to group {}".format(i.name),
                ),
                # Or, use below if you prefer not to switch to that group.
                # # mod1 + shift + letter of group = move focused window to group
                # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
                #     desc="move focused window to group {}".format(i.name)),
            ]
        )

# Define layouts and layout themes
layout_theme = {
        "margin":5,
        "border_width": 4,
        "border_focus": colors[3],
        "border_normal": colors[1]
    }

# Layout preference by monitor type:
# MonadTall - Default layout (master-stack tiling)
# BSP - Traditional monitors (16:9, 4:3)
# Columns - Ultrawide monitors (21:9, 32:9)
layouts = [
    layout.MonadTall(**layout_theme),
    layout.Bsp(**layout_theme),
    layout.Columns(**layout_theme, num_columns=3),
    layout.Max(**layout_theme),
    layout.Floating(**layout_theme),
    layout.Zoomy(**layout_theme),
]

# Updated widget defaults to match Polybar styling
widget_defaults = dict(
    font='Roboto Mono Nerd Font',  # Match Polybar font
    background=backgroundColor,
    foreground=foregroundColor,
    fontsize=16,  # Increased font size
    padding=4,
)
extension_defaults = widget_defaults.copy()

# Custom separator to match Polybar
def create_separator():
    return widget.TextBox(
        text="|",
        foreground=foregroundColorTwo,  # disabled color
        padding=8,
        fontsize=14
    )


screens = [
    Screen(
        top=bar.Bar(
            [
                # Left modules - Layout icon, workspaces, window title
                widget.Spacer(length=8),
                # CurrentLayoutIcon was removed in qtile 0.33+ (forky ships 0.35).
                # Fall back to CurrentLayout (text) on newer qtile; keep icons
                # everywhere they're still available (trixie ships 0.31).
                (widget.CurrentLayoutIcon(
                    custom_icon_paths=[os.path.expanduser("~/.config/qtile/icons/layouts")],
                    foreground=colors[6][0],
                    scale=0.65,
                    padding=4
                ) if hasattr(widget, "CurrentLayoutIcon") else widget.CurrentLayout(
                    foreground=colors[6][0],
                    padding=4
                )),
                create_separator(),
                widget.GroupBox(
                    disable_drag=True,
                    use_mouse_wheel=False,
                    active=foregroundColor,
                    inactive=foregroundColorTwo,
                    highlight_method='line',
                    highlight_color=[backgroundColor, backgroundColor],
                    this_current_screen_border=colors[3][0],
                    this_screen_border=colors[1][0],
                    other_current_screen_border=colors[1][0],
                    other_screen_border=backgroundColor,
                    urgent_alert_method='text',
                    urgent_text=colors[10][0],
                    rounded=False,
                    margin_x=0,
                    margin_y=3,
                    padding_x=10,
                    padding_y=6,
                    borderwidth=3,
                    hide_unused=False,
                ),
                create_separator(),
                widget.WindowName(
                    format='{name}',
                    max_chars=60,
                    foreground=foregroundColor,
                    padding=6
                ),

                # Right modules
                widget.TextBox(
                    text="󰋊",
                    foreground="#ffc107",
                    padding=6,
                    fontsize=18,
                ),
                widget.DF(
                    visible_on_warn=False,
                    format='{r:.0f}%',
                    partition='/',
                    foreground=foregroundColor,
                    padding=6
                ),
                create_separator(),
                widget.TextBox(
                    text="󰕾",
                    foreground="#b3e5fc",
                    padding=6,
                    fontsize=18,
                ),
                widget.Volume(
                    fmt="{}",
                    mute_command="pamixer -t",
                    volume_up_command="pamixer -i 2",
                    volume_down_command="pamixer -d 2",
                    get_volume_command="pamixer --get-volume-human",
                    check_mute_command="pamixer --get-mute",
                    check_mute_string="true",
                    foreground=foregroundColor,
                    padding=6
                ),
                create_separator(),
                widget.TextBox(
                    text="󰍛",
                    foreground="#4fc3f7",
                    padding=6,
                    fontsize=18,
                ),
                widget.Memory(
                    format='{MemPercent:2.0f}%',
                    foreground=foregroundColor,
                    padding=6
                ),
                create_separator(),
                widget.TextBox(
                    text="󰻠",
                    foreground="#ff6b6b",
                    padding=6,
                    fontsize=18,
                ),
                widget.CPU(
                    format="{load_percent:2.0f}%",
                    foreground=foregroundColor,
                    padding=6
                ),
                create_separator(),
                widget.Clock(
                    format='%a %b %-d',
                    foreground=foregroundColor,
                    padding=6,
                    mouse_callbacks={'Button1': lazy.spawn('gsimplecal')}
                ),
                create_separator(),
                widget.Clock(
                    format='%-l:%M %p',
                    foreground=colors[6][0],
                    padding=6,
                ),
                create_separator(),
                widget.GenPollText(
                    func=lambda: " CAPS " if "Caps Lock:   on" in subprocess.run(['xset', 'q'], capture_output=True, text=True).stdout else "",
                    update_interval=1,
                    padding=4,
                    foreground=backgroundColor,
                    background=colors[10][0],
                ),
                widget.TextBox(
                    text="󰻛",
                    foreground=colors[4][0],
                    padding=10,
                    fontsize=18,
                    mouse_callbacks={'Button1': lazy.spawn('flameshot gui')}
                ),
                widget.TextBox(
                    text="󰐥",
                    foreground=colors[10][0],
                    padding=10,
                    fontsize=18,
                    mouse_callbacks={'Button1': lazy.spawn(os.path.expanduser('~/.config/qtile/scripts/power'))}
                ),
                widget.Systray(
                    icon_size=20,
                    padding=8,
                ),
                widget.Spacer(length=8),
            ],
            34,
            background=backgroundColor,
            margin=[0, 0, 0, 0],
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
border_width=4,
border_focus=colors[3],
border_normal=colors[1],
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="qimgv"),  # q image viewer
        Match(wm_class="lxappearance"),  # lxappearance
        Match(wm_class="pavucontrol"),  # pavucontrol
        Match(wm_class="Galculator"),  # calculator
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

wmname = "qtile"
