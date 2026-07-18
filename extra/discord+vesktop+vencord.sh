#!/bin/bash

# Define paths
VESKTOP_THEME_DIR="$HOME/.config/vesktop/themes"
THEME_URL="https://raw.githubusercontent.com/refact0r/system24/refs/heads/main/theme/system24.theme.css"

# 1. Install Discord and Vencord
yay -S --noconfirm --needed discord vencord-bin

# 2. Setup Themes
# -f checks if the FILE exists
if [ ! -f "$VESKTOP_THEME_DIR/system24.theme.css" ]; then
    echo "Theme file not found. Downloading..."
    mkdir -p "$VESKTOP_THEME_DIR"
    wget -O "$VESKTOP_THEME_DIR/system24.theme.css" "$THEME_URL"
else
    echo "System24 theme already exists. Skipping download."
fi

# 3. Launch Vesktop change themes system24
echo "Launch Vesktop change themes system24"

vesktop
