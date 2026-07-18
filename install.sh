#!/bin/bash

# X11 Tiling Window Manager Installer for Arch Linux
# Main entry point

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/modules/colors.sh"
source "${SCRIPT_DIR}/modules/logger.sh"
source "${SCRIPT_DIR}/modules/validators.sh"
source "${SCRIPT_DIR}/modules/helpers.sh"
source "${SCRIPT_DIR}/modules/directories.sh"
source "${SCRIPT_DIR}/modules/packages.sh"
source "${SCRIPT_DIR}/modules/dotfiles.sh"
source "${SCRIPT_DIR}/modules/services.sh"
source "${SCRIPT_DIR}/modules/pacman.sh"

# Global variable to store laptop installation choice
INSTALL_ON_LAPTOP=0
# --- Helper Functions for Main Flow ---

_show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

_run_pre_checks() {
    log_section "Pre-installation Checks"
    validators::check_system
    validators::check_pacman
    validators::check_internet
    validators::check_disk_space
    log_success "All pre-checks passed."
}

_configure_system_and_helpers() {
    log_section "System Configuration & Helper Selection"
    pacman::setup_all # Assuming this enables multilib, etc.
    helpers::choose_package_helper
}

_select_installation_options() {
    helpers::select_window_managers
    helpers::select_optional_programs
}

_display_and_confirm_choices() {
    log_section "Installation Summary"
    log_info "The following will be installed and configured:"
    if [[ ${#SELECTED_WMS[@]} -gt 0 ]]; then
        log_info "  - Selected Window Managers: ${!SELECTED_WMS[@]}"
    else
        log_warn "  - No Window Managers selected (X11 may not work properly without one)"
    fi
    log_info "  - Package Helper: ${PACMAN_HELPER}"
    if [[ ${#SELECTED_PROGRAMS[@]} -gt 0 ]]; then
        log_info "  - Selected Additional Programs: ${!SELECTED_PROGRAMS[@]}"
    fi
    log_info "  - User directories (~/.config, ~/.local/bin, ~/.local/share/fonts, etc.)"
    log_info "  - Dotfiles synchronization"
    log_info "  - User group setup (e.g., video, audio)"
    log_info "  - Display Manager configuration"
    echo

    if ! helpers::prompt_yn "Do you want to proceed with the installation?"; then
        log_warn "Installation cancelled by user."
        exit 0
    fi
}

_install_components() {
    log_section "Installing Components"

    log_info "Creating user directories..."
    directories::create_user_dirs

    log_info "Installing window manager specific packages..."
    packages::install_wm_packages & _show_spinner $!

    log_info "Installing selected programs and additional packages..."
    packages::install_selected_programs & _show_spinner $!

    if [[ "$INSTALL_ON_LAPTOP" -eq 1 ]]; then
        log_info "Installing laptop-specific packages..."
        packages::install_laptop & _show_spinner $!
    fi

    log_info "Syncing dotfiles..."
    if ! dotfiles::sync_configs; then
        log_warn "Dotfiles sync encountered issues, but continuing installation."
    fi
}

_run_post_install_hooks() {
    log_section "Post-Installation Hooks"
    log_info "Updating font cache..."
    fc-cache -fv >/dev/null 2>&1 || log_warn "Failed to update font cache"

    log_info "Reloading user systemd daemon..."
    systemctl --user daemon-reload >/dev/null 2>&1 || true
}

_finalize_setup() {
    log_section "Finalizing Setup"

    log_info "Setting up user groups..."
    services::setup_user_groups

    log_info "Configuring display manager..."
    if ! services::setup_login_manager; then
        log_warn "Display manager setup encountered issues."
    fi
}

_display_post_install_instructions() {
    log_success "Installation complete!"
    echo
    log_section "Next Steps"
    log_info "1. Log out and log back in for group changes to take effect."
    log_info "2. Select your preferred window manager at the login screen."
    log_info "3. Customize your configurations in '$HOME/.config'."
    log_info "4. Install additional themes/fonts in '$HOME/.local/share'."
    log_info "5. Consider running 'fc-cache -fv' to refresh font caches."
    echo
    log_info "Thank you for using the X11 Tiling WM Installer!"
}

main() {
    log_section "X11 Tiling WM Installer for Arch Linux" # Keep this initial banner
    _run_pre_checks
    _configure_system_and_helpers
    _select_installation_options
    _display_and_confirm_choices # New confirmation step
    _install_components
    _run_post_install_hooks
    _finalize_setup
    _display_post_install_instructions
}

main "$@"
