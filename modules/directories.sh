#!/usr/bin/env bash

##############################################################################
# Directories Module - Creates necessary directory structure
##############################################################################

create_user_directories() {
    log_info "Creating user directories..."

    # Create main config directory structure
    mkdir -p ~/.config/{bspwm,sxhkd,alacritty,polybar}
    mkdir -p ~/.local/bin
    mkdir -p ~/.local/share/{fonts,themes,icons}
    mkdir -p ~/.config/dunst
    mkdir -p ~/.config/picom
    mkdir -p ~/.vim/colors
    mkdir -p ~/.cache/bspwm

    log_success "Directories created"

    log_info "Directory structure created:"
    echo "  ~/.config/bspwm/"
    echo "  ~/.config/sxhkd/"
    echo "  ~/.config/alacritty/"
    echo "  ~/.config/polybar/"
    echo "  ~/.config/dunst/"
    echo "  ~/.config/picom/"
    echo "  ~/.local/bin/"
    echo "  ~/.local/share/fonts/"
    echo "  ~/.local/share/themes/"
    echo "  ~/.local/share/icons/"
}

# Optional: Create skeleton config files if they don't exist
create_skeleton_configs() {
    # Only create if files don't exist

    if [[ ! -f ~/.config/bspwm/bspwmrc ]]; then
        cp "${SCRIPT_DIR}/config/bspwmrc.example" ~/.config/bspwm/bspwmrc 2>/dev/null || \
        create_default_bspwmrc
    fi

    if [[ ! -f ~/.config/sxhkd/sxhkdrc ]]; then
        cp "${SCRIPT_DIR}/config/sxhkdrc.example" ~/.config/sxhkd/sxhkdrc 2>/dev/null || \
        create_default_sxhkdrc
    fi
}

create_default_bspwmrc() {
    cat > ~/.config/bspwm/bspwmrc << 'EOF'
#!/bin/bash

# Monitor
bspc monitor -d 1 2 3 4 5

# Defaults
bspc config border_width 2
bspc config window_gap 10
bspc config split_ratio 0.52
bspc config borderless_monocle true
bspc config gapless_monocle true
bspc config focus_follows_pointer true

# Colors
bspc config normal_border_color "#444444"
bspc config focused_border_color "#ffffff"
bspc config presel_feedback_color "#5e81ac"

# Rules
bspc rule -a Gimp desktop='^4' state=floating
bspc rule -a Chromium desktop='^2'
bspc rule -a Firefox desktop='^2'

# Autostart
pgrep -x "sxhkd" > /dev/null || sxhkd &
pgrep -x "picom" > /dev/null || picom &
pgrep -x "dunst" > /dev/null || dunst &
EOF

    chmod +x ~/.config/bspwm/bspwmrc
    log_success "Created default bspwmrc"
}

create_default_sxhkdrc() {
    cat > ~/.config/sxhkd/sxhkdrc << 'EOF'
# Terminal
super + Return
  alacritty

# Application menu
super + @space
  dmenu_run

# bspwm hotkeys
super + alt + q
  bspc quit

super + w
  bspc node -c

# Focus
super + {h,j,k,l}
  bspc node -f {west,south,north,east}

# Move
super + shift + {h,j,k,l}
  bspc node -s {west,south,north,east}

# Desktop
super + {1-5}
  bspc desktop -f '^{1-5}'

super + shift + {1-5}
  bspc node -d '^{1-5}'

# Fullscreen
super + f
  bspc node -t ~fullscreen
EOF

    log_success "Created default sxhkdrc"
}
