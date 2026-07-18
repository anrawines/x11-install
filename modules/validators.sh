#!/bin/bash

# Guard against multiple sourcing
if [[ -n "${_VALIDATORS_SOURCED:-}" ]]; then
    return
fi
readonly _VALIDATORS_SOURCED=1

source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Supported Arch-based distributions
readonly ARCH_DISTROS=(
    "Arch"
    "Arch Linux"
    "CachyOS"
    "Artix Linux"
    "Manjaro"
    "EndeavourOS"
    "Endeavour"
    "ArcoLinux"
    "ArchLabs"
    "Garuda"
    "Rebornos"
)

# Validation functions

validators::check_system() {
    if ! validators::is_arch_based; then
        log_error "This script requires an Arch-based Linux distribution"
        log_info "Supported: ${ARCH_DISTROS[*]}"
        exit 1
    fi
    
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root"
        exit 1
    fi
    
    log_success "System requirements met"
}

validators::is_arch_based() {
    local os_name
    os_name=$(grep "^NAME=" /etc/os-release | cut -d'"' -f2)
    
    for distro in "${ARCH_DISTROS[@]}"; do
        if [[ "$os_name" == *"$distro"* ]]; then
            log_info "Detected: $os_name"
            return 0
        fi
    done
    
    return 1
}

validators::check_internet() {
    log_info "Checking internet connectivity..."
    
    # Try multiple DNS servers for reliability
    if ! ping -c 1 8.8.8.8 &>/dev/null && \
       ! ping -c 1 1.1.1.1 &>/dev/null && \
       ! ping -c 1 9.9.9.9 &>/dev/null; then
        log_error "No internet connection detected"
        exit 1
    fi
    
    log_success "Internet connection OK"
}

validators::check_disk_space() {
    log_info "Checking disk space..."
    
    local available
    available=$(df / | awk 'NR==2 {print $4}')
    
    if [[ $available -lt 2097152 ]]; then # 2GB in KB
        log_warn "Low disk space: $(numfmt --to=iec-i --suffix=B $((available * 1024)))"
    else
        log_success "Disk space OK"
    fi
}

validators::is_valid_wm() {
    local wm=$1
    [[ "$wm" =~ ^(awesome|bspwm|dwm|i3|openbox|qtile|xmonad)$ ]]
}

validators::get_installed_wms() {
    local -n installed_arr=$1
    local search_paths=(
        "/usr/share/xsessions"
        "/usr/share/wayland-sessions"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]]; then
            while IFS= read -r file; do
                local name
                name=$(basename "$file" .desktop)
                # Avoid duplicates and empty strings
                if [[ -n "$name" && ! " ${installed_arr[@]} " =~ " $name " ]]; then
                    installed_arr+=("$name")
                fi
            done < <(ls "$path"/*.desktop 2>/dev/null)
        fi
    done
}

validators::check_pacman() {
    log_info "Checking pacman availability..."
    
    if ! command -v pacman &>/dev/null; then
        log_error "pacman not found - required for Arch-based systems"
        exit 1
    fi
    
    log_success "pacman found"
}
