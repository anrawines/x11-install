#!/bin/bash

# Guard against multiple sourcing
if [[ -n "${_REPOS_SOURCED:-}" ]]; then
    return
fi
readonly _REPOS_SOURCED=1

source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Repository configuration

# Internal helper to set or update a pacman.conf option
_pacman_set_option() {
    local key=$1
    local value=$2
    local conf="/etc/pacman.conf"

    # Check if already set correctly
    if grep -q "^\s*${key}\s*=\s*${value}\s*$" "$conf"; then
        return 0
    fi

    if grep -q "^\s*#\?\s*${key}\s*=" "$conf"; then
        sudo sed -i "s/^\s*#\?\s*${key}\s*=.*/${key} = ${value}/" "$conf"
    else
        sudo sed -i "/\[options\]/a ${key} = ${value}" "$conf"
    fi
    return 1
}

# Internal helper to enable a pacman.conf flag
_pacman_enable_flag() {
    local flag=$1
    local conf="/etc/pacman.conf"

    # Check if already enabled
    if grep -q "^\s*${flag}\s*$" "$conf"; then
        return 0
    fi

    if grep -q "^\s*#\?\s*${flag}\s*$" "$conf"; then
        sudo sed -i "s/^\s*#\?\s*${flag}\s*$/${flag}/" "$conf"
    else
        sudo sed -i "/\[options\]/a ${flag}" "$conf"
    fi
    return 1
}

pacman::enable_parallel_downloads() {
    log_info "Configuring pacman options..."

    local pacman_conf="/etc/pacman.conf"

    # Check if any changes are actually needed
    local needs_change=0
    if ! grep -q "^\s*ParallelDownloads\s*=\s*25\s*$" "$pacman_conf"; then needs_change=1; fi
    if ! grep -q "^\s*DisableDownloadTimeout\s*$" "$pacman_conf"; then needs_change=1; fi
    if ! grep -q "^\s*ILoveCandy\s*$" "$pacman_conf"; then needs_change=1; fi
    if ! grep -q "^\s*Color\s*$" "$pacman_conf"; then needs_change=1; fi

    if [[ $needs_change -eq 0 ]]; then
        log_success "Pacman configuration is already optimized"
        return 0
    fi

    # Backup pacman.conf
    local backup="${pacman_conf}.backup.$(date +%s)"
    if ! sudo cp "$pacman_conf" "$backup"; then
        log_error "Failed to backup $pacman_conf"
        return 1
    fi

    log_info "Applying pacman optimizations..."
    _pacman_set_option "ParallelDownloads" "25"
    _pacman_enable_flag "ILoveCandy"
    _pacman_enable_flag "DisableDownloadTimeout"

    log_success "Pacman configuration updated (backup: $backup)"
}

pacman::setup_all() {
    pacman::enable_parallel_downloads
}
