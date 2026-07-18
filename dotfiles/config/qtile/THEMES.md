# Qtile Theme Switcher

A single keybinding (`Super + Shift + T`) that switches colors across your entire desktop: qtile bar/borders, wallpaper, notifications, launcher, terminal, GTK apps, and icons.

## The Script: `scripts/thememenu`

### Overview

The script is a bash program that presents a rofi menu, then applies the selected theme to seven different components by rewriting their config files and restarting services as needed.

### Data Structure

The script uses six bash associative arrays that map each theme to its resources:

```bash
declare -A themes          # Display name -> internal name ("Dracula" -> "dracula")
declare -A wallpapers      # internal name -> wallpaper filename
declare -A ghostty_themes  # internal name -> ghostty built-in theme name
declare -A gtk_themes      # internal name -> Orchis GTK theme variant
declare -A icon_themes     # internal name -> Colloid icon theme variant
```

Template files for dunst and rofi live in `themes/<name>/` and are copied wholesale. Ghostty and GTK use single-line `sed` replacements since only one value changes in each.

### Execution Flow

**Step 1 — Detect current theme**

```bash
current=$(grep -oP '= \K\w+(?=\(\))' "$CONFIG")
```

Reads `config.py` and extracts the function name from the line `colors, backgroundColor, ... = github_dark()`. The Perl regex `\K` discards everything before the match, and `(?=\(\))` ensures it only matches function calls.

**Step 2 — Show rofi picker**

```bash
chosen=$(printf '%s\n' "${!themes[@]}" | sort | rofi -dmenu -i -p "Theme ($current)" ...)
```

Pipes the display names from the `themes` array into rofi. The prompt shows which theme is currently active. User picks one or presses Escape to cancel.

**Step 3 — Validate selection**

The script exits early if:
- Nothing was selected (user cancelled)
- The selected theme name doesn't exist in the array
- The selected theme is already active

**Step 4 — Apply the theme (7 operations)**

1. **Qtile colors** — `sed` replaces the function call in `config.py`:
   ```bash
   sed -i "s/= ${current}()/= ${target}()/" "$CONFIG"
   ```
   This changes which color function from `colors.py` gets called when qtile loads.

2. **Wallpaper** — `feh` sets it immediately, then `sed` updates `autostart.sh` so it persists on reboot:
   ```bash
   feh --bg-fill "$WALLPAPER_DIR/$wp"
   sed -i "s|feh --bg-fill.*|feh --bg-fill $WALLPAPER_DIR/$wp \&|" "$AUTOSTART"
   ```

3. **Dunst (notifications)** — Copies the pre-generated dunstrc template, kills dunst, and relaunches it:
   ```bash
   cp "$THEMES_DIR/$target/dunstrc" "$DUNST_CONF"
   killall dunst 2>/dev/null
   dunst -config "$DUNST_CONF" &
   ```
   Dunst doesn't support live reload, so a restart is required.

4. **Rofi (launcher/menus)** — Copies three themed `.rasi` files over the active ones:
   ```bash
   cp "$THEMES_DIR/$target/config.rasi" "$ROFI_DIR/config.rasi"
   cp "$THEMES_DIR/$target/power.rasi" "$ROFI_DIR/power.rasi"
   cp "$THEMES_DIR/$target/keybinds.rasi" "$ROFI_DIR/keybinds.rasi"
   ```
   Rofi reads its config on each launch, so no restart is needed.

5. **Ghostty (terminal)** — `sed` swaps the `theme = ` line in ghostty's config:
   ```bash
   sed -i "s|^theme = .*|theme = ${ghostty_theme}|" "$GHOSTTY_CONF"
   ```
   Ghostty uses built-in iterm2 color schemes (463 available, run `ghostty +list-themes` to see them). New terminals pick up the theme automatically. Existing terminals can reload with `Ctrl+Alt+R`.

6. **GTK theme + icons** — Two-pronged approach. `sed` updates `settings.ini` for future app launches, and `gsettings` live-updates any running GTK apps:
   ```bash
   sed -i "s|^gtk-theme-name=.*|gtk-theme-name=${gtk_theme}|" "$GTK3_CONF"
   sed -i "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=${icon_theme}|" "$GTK3_CONF"
   gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
   gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
   ```
   Without the `gsettings` calls, only newly opened GTK apps would pick up the change. The `gsettings` commands make Thunar, Firefox, etc. update in-place.

7. **Restart qtile** — Applies the new bar/border/layout colors:
   ```bash
   qtile cmd-obj -o cmd -f restart
   ```

### Why Templates vs Sed

Dunst and rofi configs have colors scattered across many lines (urgency levels, element states, input bar, etc.). Using `sed` to replace individual hex values would be fragile and hard to maintain. Instead, complete config files are pre-generated per theme and copied into place.

Ghostty and GTK only need one line changed each, so `sed` is the right tool there.

## The Generator: `scripts/generate_themes.py`

A Python script that reads the color functions from `colors.py` and produces dunst + rofi template files for all 12 themes.

### How It Maps Colors

Each theme function in `colors.py` returns a 5-tuple: `(colors, backgroundColor, foregroundColor, workspaceColor, foregroundColorTwo)`. The `colors` list has 11 slots:

| Slot | Role | Used In |
|------|------|---------|
| `[0]` | Background | Dunst urgency bg (darkened) |
| `[1]` | Background-alt | — |
| `[2]` | Foreground | Dunst normal fg |
| `[3]` | Blue/accent | Dunst frame, rofi prompt color |
| `[4]` | Cyan/green | Dunst normal highlight |
| `[5]` | Disabled | — |
| `[6]` | Primary/yellow | Dunst critical frame/highlight |
| `[7]` | Pink/purple | Rofi entry (search text) color |
| `[8]` | Border | — |
| `[9]` | Red | Dunst critical bg (darkened), rofi urgent |
| `[10]` | Alert/orange | — |

The `backgroundColor`, `foregroundColor`, and `workspaceColor` values drive rofi's main colors (background, text, and selection/border accent).

### Running It

```bash
python3 ~/.config/qtile/scripts/generate_themes.py
```

Outputs to `themes/<name>/` with four files per theme: `dunstrc`, `config.rasi`, `power.rasi`, `keybinds.rasi`. Run it again after modifying `colors.py` to regenerate all templates.

## Adding a New Theme

1. Add a color function to `colors.py` following the 11-slot pattern
2. Add the function to `THEME_FUNCS` in `scripts/generate_themes.py`
3. Run `python3 scripts/generate_themes.py` to create the templates
4. Add entries to all six arrays in `scripts/thememenu` (themes, wallpapers, ghostty_themes, gtk_themes, icon_themes)
5. Drop a wallpaper in `~/.config/qtile/wallpaper/`

## File Layout

```
themes/<name>/          Pre-generated configs (dunstrc, *.rasi) — copied on switch
scripts/thememenu       The switcher script — called by Super+Shift+T
scripts/generate_themes.py  Reads colors.py, writes templates to themes/
colors.py               Theme color definitions (one function per theme)
dunst/dunstrc           Active dunst config (overwritten on switch)
rofi/*.rasi             Active rofi configs (overwritten on switch)
wallpaper/              One wallpaper image per theme
```

External files modified on switch:
```
~/.config/ghostty/config        theme = line
~/.config/gtk-3.0/settings.ini  gtk-theme-name and gtk-icon-theme-name
```

## Theme Mappings

| Theme | Wallpaper | Ghostty | GTK | Icons |
|-------|-----------|---------|-----|-------|
| Catppuccin | wallhaven-d61z1m | Catppuccin Mocha | Orchis-Purple-Dark | Colloid-Catppuccin-Dark |
| Doom One | wallhaven-d8633m | Doom One | Orchis-Dark | Colloid-Dark |
| Dracula | wallhaven-kw5yy7 | Dracula | Orchis-Purple-Dark-Dracula | Colloid-Dracula-Dark |
| Everforest | wallhaven-d697og | Everforest Dark Hard | Orchis-Green-Dark | Colloid-Everforest-Dark |
| GitHub Dark | wallhaven-218x7m | GitHub Dark | Orchis-Grey-Dark | Colloid-Grey-Dracula-Dark |
| Gruvbox | gruvbox-dark-debian | Gruvbox Dark | Orchis-Orange-Dark | Colloid-Gruvbox-Dark |
| Gruvbox Light | gruvbox-dark-debian | Gruvbox Light | Orchis-Orange-Dark | Colloid-Gruvbox-Light |
| Kanagawa | wallhaven-jx9mzp | Kanagawa Wave | Orchis-Orange-Dark | Colloid-Dark |
| Monokai | wallhaven-3q9vmd | Monokai Remastered | Orchis-Pink-Dark | Colloid-Dark |
| Moonfly | wallhaven-x6gmxl | Moonfly | Orchis-Dark | Colloid-Dark |
| Nord | nord.jpg | Nord | Orchis-Dark-Nord | Colloid-Nord-Dark |
| Retro | debdino.png | Retro | Orchis-Orange-Dark | Colloid-Dark |
