#!/usr/bin/env bash

##############################################################################
# System Module - Handles system services and configuration
##############################################################################

setup_system_services() {
    log_info "Configuring system services..."

    # Enable multilib if on x86_64 (useful for gaming/32-bit apps)
    if [[ $(uname -m) == "x86_64" ]]; then
        enable_multilib
    fi

    # Set up dbus if needed
    setup_dbus

    log_success "System services configured"
}

enable_multilib() {
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        log_info "Multilib already enabled"
    else
        log_warn "Enabling multilib in pacman.conf..."
        sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist$/ s/^#//' /etc/pacman.conf
        sudo pacman -Sy
        log_success "Multilib enabled"
    fi
}

setup_dbus() {
    # D-Bus is usually installed with some packages, but make sure the service is available
    if command -v dbus-launch &> /dev/null; then
        log_success "D-Bus is available"
    else
        log_warn "D-Bus not found, consider installing it manually"
    fi
}

# Additional service utilities
enable_service() {
    local service=$1
    if systemctl list-unit-files | grep -q "^${service}"; then
        log_info "Enabling $service..."
        sudo systemctl enable "$service"
        sudo systemctl start "$service"
    fi
}

disable_service() {
    local service=$1
    if systemctl list-unit-files | grep -q "^${service}"; then
        log_info "Disabling $service..."
        sudo systemctl stop "$service"
        sudo systemctl disable "$service"
    fi
}
