#!/usr/bin/env bash

##############################################################################
# Config Module - Final configuration and login manager setup
##############################################################################

configure_login_manager() {
    log_info "Configuring login manager..."

    # Detect available login managers
    local available_lms=()

    command -v startx &> /dev/null && available_lms+=("xinit")
    [[ -f /usr/share/xsessions/lightdm.desktop ]] && available_lms+=("lightdm")
    [[ -f /usr/share/xsessions/gdm.desktop ]] && available_lms+=("gdm")
    [[ -f /usr/share/xsessions/sddm.desktop ]] && available_lms+=("sddm")

    if [[ ${#available_lms[@]} -eq 0 ]]; then
        log_warn "No login manager detected"
        return 0
    fi

    log_info "Available login managers: ${available_lms[@]}"
    read -p "Select login manager (1-${#available_lms[@]}) or press Enter to skip: " lm_choice

    if [[ -z "$lm_choice" ]]; then
        log_warn "Login manager setup skipped"
        return 0
    fi

    if [[ ! "$lm_choice" =~ ^[0-9]+$ ]] || (( lm_choice < 1 || lm_choice > ${#available_lms[@]} )); then
        log_error "Invalid choice"
        return 1
    fi

    local selected_lm="${available_lms[$((lm_choice - 1))]}"
    configure_lm "$selected_lm"
}

configure_lm() {
    local lm=$1

    case "$lm" in
        xinit)
            configure_xinit
            ;;
        lightdm)
            configure_lightdm
            ;;
        gdm)
            configure_gdm
            ;;
        sddm)
            configure_sddm
            ;;
        *)
            log_error "Unknown login manager: $lm"
            return 1
            ;;
    esac
}

configure_xinit() {
    log_info "Configuring xinit with bspwm..."

    local xinitrc="${HOME}/.xinitrc"
    [[ -f "$xinitrc" ]] && cp "$xinitrc" "${xinitrc}.bak"

    cat > "$xinitrc" << 'EOF'
#!/bin/bash

# Set keyboard layout (optional)
# setxkbmap us

# Start D-Bus
if command -v dbus-launch >/dev/null 2>&1; then
    eval "$(dbus-launch --sh-syntax)"
fi

# Merge X resources
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# Start window manager
exec bspwm
EOF

    chmod +x "$xinitrc"
    log_success "xinit configured for bspwm"
    log_info "Start with: startx"
}

configure_lightdm() {
    log_info "Configuring lightdm..."

    if ! sudo test -f /etc/lightdm/lightdm.conf; then
        log_error "lightdm not properly installed"
        return 1
    fi

    # Ensure lightdm is enabled
    sudo systemctl enable lightdm
    sudo systemctl start lightdm

    log_success "lightdm configured"
    log_warn "Please select bspwm from the session selector on the login screen"
}

configure_gdm() {
    log_info "Configuring GDM..."

    if ! sudo test -f /etc/gdm/custom.conf; then
        log_error "GDM not properly installed"
        return 1
    fi

    # Ensure GDM is enabled
    sudo systemctl enable gdm
    sudo systemctl start gdm

    log_success "GDM configured"
    log_warn "Please select bspwm from the session selector on the login screen"
}

configure_sddm() {
    log_info "Configuring SDDM..."

    if ! sudo test -f /etc/sddm.conf.d/kde_settings.conf; then
        log_error "SDDM not properly installed"
        return 1
    fi

    # Ensure SDDM is enabled
    sudo systemctl enable sddm
    sudo systemctl start sddm

    log_success "SDDM configured"
    log_warn "Please select bspwm from the session selector on the login screen"
}

# Additional configuration utilities
setup_shell_profile() {
    log_info "Setting up shell profile..."

    # Add ~/.local/bin to PATH if not already there
    local shell_config="${HOME}/.bashrc"

    if grep -q "~/.local/bin" "$shell_config" 2>/dev/null; then
        log_info "PATH already includes ~/.local/bin"
    else
        cat >> "$shell_config" << 'EOF'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"
EOF
        log_success "Added ~/.local/bin to PATH"
    fi
}

configure_fonts() {
    log_info "Building font cache..."
    fc-cache -fv ~/.local/share/fonts/ 2>/dev/null || \
    log_warn "Could not update font cache"
}
