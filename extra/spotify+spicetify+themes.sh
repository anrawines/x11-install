#!/bin/bash

# 1. Install Spotify and Spicetify-cli from AUR
# Using yay for both keeps everything managed by your package manager
yay -S --noconfirm --needed spotify spicetify-cli

# 2. Fix permissions
# Necessary so spicetify can write to the /opt/spotify folder
sudo chown -R $USER:$USER /opt/spotify

# 3. Setup Themes
# Check if the folder is empty or doesn't exist
if [ ! -d "$HOME/.config/spicetify/Themes" ] || [ -z "$(ls -A $HOME/.config/spicetify/Themes)" ]; then
    echo "Themes not found. Downloading..."
    mkdir -p ~/.config/spicetify/Themes
    git clone --depth=1 https://github.com/spicetify/spicetify-themes.git /tmp/spicetify-themes
    cp -r /tmp/spicetify-themes/* ~/.config/spicetify/Themes
else
    echo "Themes already exist. Skipping download."
fi

# 4. Apply Configuration
# 'spicetify backup apply' is only needed the very first time
# recommend themes : text, Blackout
# to create the original backup files.
spicetify config current_theme text color_scheme Spotify
spicetify apply
