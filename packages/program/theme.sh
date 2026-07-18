# Coloid Icons
# options
#-s, --scheme VARIANTS   Specify folder colorscheme variant(s) [default|nord|dracula|gruvbox|everforest|catppuccin|all]
#-t, --theme VARIANTS    Specify folder color variant(s) [default|purple|pink|red|orange|yellow|green|teal|grey|all] (Default: blue)

if [ ! -d "$HOME/.local/share/icons/Colloid-yellow" ]; then
  echo "Downloading themes.. "
  git clone --depth 1 https://github.com/vinceliuice/Colloid-icon-theme.git &&
    cd Colloid-icon-theme &&
    ./install.sh -t yellow &&
    cd .. && rm -rf Colloid-icon-theme
else
  echo "Colloid-yellow icons already installed, skipping.."
fi

# Coloid Themes
#-t, --theme VARIANT...  Specify theme color variant(s) [default|purple|pink|red|orange|yellow|green|teal|grey|all] (Default: blue)
#-c, --color VARIANT...  Specify color variant(s) [standard|light|dark] (Default: All variants)
#--tweaks                Specify versions for tweaks
#                        1. [nord|dracula|gruvbox|everforest|catppuccin|all]  (Nord/Dracula/Gruvbox/Everforet/Catppuccin/all) ColorSchemes version
#                        2. black                       Blackness color version
#                        3. rimless                     Remove the 1px border about windows and menus
#                        4. normal                      Normal windows button style like gnome default theme (titlebuttons: max/min/close)
#                        5. float                       Floating gnome-shell panel style

if [ ! -d "$HOME/.local/share/themes/Colloid-Dark-Yellow" ]; then
  echo "Downloading themes.. "
  git clone --depth 1 https://github.com/vinceliuice/Colloid-gtk-theme.git &&
    cd Colloid-gtk-theme &&
    ./install.sh -t yellow --tweaks black &&
    cd .. && rm -rf Colloid-gtk-theme
else
  echo "Colloid-Dark-Yellow theme already installed, skipping.."
fi

# Cursors
# ls /usr/share/icons/ | grep -i "posy"
# posy-white"
# posy-black"
# posy-white-tiny"
# posy-black-tiny"
if [ ! -d "/usr/share/icons/posy-*" ]; then
  echo "Installing posy cursors.. "
  yay -S posy-cursors --needed --noconfirm
  yay -S apple_cursor --needed --noconfirm
  yay -S nwg-look --needed --noconfirm
else
  echo "Posy cursors already installed, skipping.."
fi

# set incon, cursor and themes
# Set Icon Theme
gsettings set org.gnome.desktop.interface icon-theme "Colloid-yellow"

# Set GTK Theme
gsettings set org.gnome.desktop.interface gtk-theme "Colloid-Dark-Yellow"

# Set Color Scheme to Dark (Required for GNOME 42+)
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

# Set GNOME Shell Theme (Requires User Themes extension)
#gsettings set org.gnome.shell.extensions.user-theme name "Colloid-Dark-Yellow"

# Apply Cursors
gsettings set org.gnome.desktop.interface cursor-theme "posy-white"
