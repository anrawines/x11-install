#!/bin/bash

# Xmonad package installer with post-install configuration
# This script handles:
# - Base package installation
# - Xmonad compilation with custom config
# - Companion tools (xmobar, picom)

packages::install() {
    local base_packages=(
        "xmonad"
        "xmonad-contrib"
        "xmobar"
    )

    local companion_packages=(
        "picom"
        "rofi"
        "dunst"
    )

    local display_packages=(
        "xorg-server"
        "xorg-xinit"
        "xorg-xrandr"
        "xorg-xsetroot"
        "xorg-xprop"
        "xorg-xhost"
        "xorg-xbacklight"
        "xorg-xmessage"
    )

    local sound_packages=(
      "pavucontrol"
      "pulsemixer"
      "pamixer"
      "pipewire-audio"
    )

    local utils=(
        "wget"
        "curl"
        "unzip"
        "zip"
    )

    local fonts=(
        "ttf-dejavu"
        "ttf-liberation"
        "noto-fonts"
        "ttf-nerd-fonts-symbols"
    )

    log_info "Installing Xmonad base packages..."
    if ! helpers::run_with_helper "$PACMAN_HELPER" "${base_packages[@]}"; then
        log_error "Failed to install base Xmonad packages"
        return 1
    fi

    log_info "Installing companion packages (picom, rofi, dunst)..."
    if ! helpers::run_with_helper "$PACMAN_HELPER" "${companion_packages[@]}"; then
        log_warn "Some companion packages failed (continuing)"
    fi

    log_info "Installing display server packages..."
    if ! helpers::run_with_helper "$PACMAN_HELPER" "${display_packages[@]}"; then
        log_warn "Some display packages failed (continuing)"
    fi

    log_info "Installing sound packages..."
    if ! helpers::run_with_helper "$PACMAN_HELPER" "${sound_packages[@]}"; then
        log_warn "Some sound packages failed (continuing)"
    fi

    log_info "Installing utilities..."
    if ! helpers::run_with_helper "$PACMAN_HELPER" "${utils[@]}"; then
        log_warn "Some utilities failed (continuing)"
    fi

    log_info "Installing fonts..."
    if ! helpers::run_with_helper "$PACMAN_HELPER" "${fonts[@]}"; then
        log_warn "Some fonts failed (continuing)"
    fi

    # Post-install: Compile xmonad configuration
    log_section "Xmonad Post-Installation Setup"
    log_info "Building Xmonad configuration..."

    if command -v xmonad &>/dev/null; then
        if xmonad --recompile 2>&1; then
            log_success "Xmonad configuration compiled successfully"
        else
            log_warn "Xmonad --recompile returned non-zero (config may need manual compilation)"
            log_info "You may need to run 'xmonad --recompile' manually after editing ~/.xmonad/xmonad.hs"
        fi
    else
        log_warn "Xmonad not found in PATH - compilation skipped"
    fi

    log_success "Xmonad installation complete"
    return 0
}
