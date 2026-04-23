#!/usr/bin/env bash

##############################################################################
# Packages Module - Handles package installation
##############################################################################

# Source package lists
PACKAGES_DIR="${SCRIPT_DIR}/packages"

install_packages() {
    # Check if package lists exist
    if [[ ! -f "${PACKAGES_DIR}/base.txt" ]] || [[ ! -f "${PACKAGES_DIR}/additional.txt" ]]; then
        log_error "Package lists not found in ${PACKAGES_DIR}/"
        log_info "Creating default package lists..."
        create_default_packages
    fi

    # Determine if we need AUR helper
    local has_aur_packages=false
    if [[ -f "${PACKAGES_DIR}/aur.txt" ]]; then
        has_aur_packages=true
    fi

    # Update pacman
    log_info "Updating pacman package database..."
    sudo pacman -Syu --noconfirm

    # Install base packages
    log_info "Installing base packages..."
    local base_packages=$(cat "${PACKAGES_DIR}/base.txt" | grep -v '^#' | grep -v '^$' | tr '\n' ' ')
    if [[ ! -z "$base_packages" ]]; then
        sudo pacman -S --noconfirm $base_packages
    fi

    # Install additional packages
    log_info "Installing additional packages..."
    local additional_packages=$(cat "${PACKAGES_DIR}/additional.txt" | grep -v '^#' | grep -v '^$' | tr '\n' ' ')
    if [[ ! -z "$additional_packages" ]]; then
        sudo pacman -S --noconfirm $additional_packages
    fi

    # Install AUR packages if available
    if $has_aur_packages; then
        install_aur_packages
    fi

    log_success "Packages installed successfully"
}

install_aur_packages() {
    local aur_helper=""

    # Check for existing AUR helper
    if command -v yay &> /dev/null; then
        aur_helper="yay"
    elif command -v paru &> /dev/null; then
        aur_helper="paru"
    else
        log_warn "No AUR helper found (yay/paru)"
        read -p "Install yay for AUR support? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_yay
            aur_helper="yay"
        else
            log_warn "Skipping AUR packages"
            return 0
        fi
    fi

    log_info "Installing AUR packages with $aur_helper..."
    local aur_packages=$(cat "${PACKAGES_DIR}/aur.txt" | grep -v '^#' | grep -v '^$' | tr '\n' ' ')

    if [[ ! -z "$aur_packages" ]]; then
        $aur_helper -S --noconfirm $aur_packages
    fi

    log_success "AUR packages installed successfully"
}

install_yay() {
    log_info "Installing yay AUR helper..."
    local tmpdir=$(mktemp -d)
    cd "$tmpdir"

    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm

    cd /
    rm -rf "$tmpdir"
    log_success "yay installed successfully"
}

create_default_packages() {
    mkdir -p "${PACKAGES_DIR}"

    # Create default base packages file
    cat > "${PACKAGES_DIR}/base.txt" << 'EOF'
# Core bspwm packages
bspwm
sxhkd
xcb-util
xcb-util-wm

# Display and graphics
xorg-server
xorg-xinit
xorg-xrandr
xorg-setxkbmap
libxinerama

# Terminal and shell
alacritty
bash
zsh

# Additional tools
dmenu
dunst
polybar

# Fonts
ttf-dejavu
ttf-liberation
noto-fonts
ttf-nerd-fonts-symbols

# Utilities
git
curl
wget
nano
vim
sudo
EOF

    # Create default additional packages file
    cat > "${PACKAGES_DIR}/additional.txt" << 'EOF'
# Media and editors
feh
mpv
imagemagick

# Development
base-devel
rustup
nodejs
npm
python

# Productivity
firefox
thunar
gedit

# System utilities
htop
neofetch
lsof
strace
unzip
EOF

    log_success "Default package lists created in ${PACKAGES_DIR}/"
}
