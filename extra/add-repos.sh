#!/bin/bash

# Optional script to add third-party repositories
# Use this for CachyOS, Chaotic-AUR, etc.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/modules/colors.sh"
source "${SCRIPT_DIR}/modules/logger.sh"
source "${SCRIPT_DIR}/modules/helpers.sh"

add_chaotic_aur() {
    log_info "Adding Chaotic-AUR..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
                 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    fi
    log_success "Chaotic-AUR added."
}

main() {
    log_section "Extra Repository Configuration"
    
    if helpers::prompt_yn "Would you like to add Chaotic-AUR?"; then
        add_chaotic_aur
    fi
    
    # Add templates for other repos here
    # if helpers::prompt_yn "Would you like to add CachyOS Repos?"; then ...

    log_info "Updating package database..."
    sudo pacman -Sy
}

main "$@"