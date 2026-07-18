#!/bin/bash

# Guard against multiple sourcing
if [[ -n "${_PACKAGES_SOURCED:-}" ]]; then
    return
fi
readonly _PACKAGES_SOURCED=1

source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Package installation functions

# Determine package file type (.txt or .sh)
packages::get_installer() {
    local package_name=$1
    local package_dir=$2
    
    if [[ -f "${package_dir}/${package_name}.sh" ]]; then
        echo "${package_dir}/${package_name}.sh"
    elif [[ -f "${package_dir}/${package_name}.txt" ]]; then
        echo "${package_dir}/${package_name}.txt"
    else
        return 1
    fi
}

# Execute a .sh package installer
packages::run_script_installer() {
    local script=$1
    local pkg_name=$2
    
    log_info "Running custom installer for $pkg_name..."
    
    if ! source "$script"; then
        log_error "Failed to source installer script: $script"
        return 1
    fi
    
    if ! packages::install; then
        log_error "Custom installer failed for $pkg_name"
        return 1
    fi
    
    log_success "$pkg_name installation completed"
    
    # Verify installation if check function exists
    if declare -f packages::check &>/dev/null; then
        if ! packages::check; then
            log_error "$pkg_name verification failed"
            return 1
        fi
    fi
    
    return 0
}

packages::load_package_list() {
    local file=$1
    local -n arr=$2
    
    if [[ ! -f "$file" ]]; then
        log_warn "Package file not found: $file"
        return 1
    fi
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        # Strip carriage returns and leading/trailing whitespace
        local cleaned_pkg=$(echo "$line" | sed 's/\r//g' | xargs)
        [[ -z "$cleaned_pkg" ]] && continue
        arr+=("$cleaned_pkg")
    done < "$file"
}

packages::filter_installed() {
    local helper=$1
    shift
    local -n input_packages=$1
    local -n output_packages=$2
    
    for pkg in "${input_packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            output_packages+=("$pkg")
        else
            log_info "Already installed: $pkg"
        fi
    done
}

packages::check_available() {
    local helper=$1
    shift
    local -n input_packages=$1
    local -n output_packages=$2
    
    for pkg in "${input_packages[@]}"; do
        case "$helper" in
            pacman)
                if pacman -Si "$pkg" &>/dev/null; then
                    output_packages+=("$pkg")
                else
                    log_warn "Package not found in repos: $pkg"
                fi
                ;;
            yay|paru)
                # For AUR helpers, we skip the pre-check because -Si can be slow 
                # or require interaction. The helper will handle errors during install.
                output_packages+=("$pkg")
                ;;
        esac
    done
}

packages::install_wm_packages() {
    log_section "Installing Window Manager Packages"
    
    for wm in "${!SELECTED_WMS[@]}"; do
        local pkg_dir="${SCRIPT_DIR}/packages/wm"
        local installer
        
        if ! installer=$(packages::get_installer "$wm" "$pkg_dir"); then
            log_warn "No installer found for $wm (skipping)"
            continue
        fi
        
        if [[ "$installer" == *.sh ]]; then
            if ! packages::run_script_installer "$installer" "$wm"; then
                log_error "$wm installation failed"
            fi
        else
            local packages=()
            local to_install=()
            local available=()
            
            if ! packages::load_package_list "$installer" packages; then
                continue
            fi
            
            log_info "Processing $wm packages (${#packages[@]} total)..."
            
            packages::filter_installed "$PACMAN_HELPER" packages to_install
            
            if [[ ${#to_install[@]} -eq 0 ]]; then
                log_success "$wm: all packages already installed"
                continue
            fi
            
            packages::check_available "$PACMAN_HELPER" to_install available
            
            if [[ ${#available[@]} -eq 0 ]]; then
                log_warn "$wm: no packages available to install"
                continue
            fi
            
            log_info "Installing ${#available[@]} packages for $wm..."
            if helpers::run_with_helper "$PACMAN_HELPER" "${available[@]}"; then
                log_success "$wm packages installed"
            else
                log_error "Failed to install $wm packages"
            fi
        fi
    done
}

packages::install_selected_programs() {
    log_section "Installing Selected Programs"
    
    if [[ ${#SELECTED_PROGRAMS[@]} -eq 0 ]]; then
        log_info "No programs selected"
        return 0
    fi
    
    for program in "${!SELECTED_PROGRAMS[@]}"; do
        local pkg_dir="${SCRIPT_DIR}/packages/program"
        local installer
        
        if ! installer=$(packages::get_installer "$program" "$pkg_dir"); then
            log_warn "No installer found for $program (skipping)"
            continue
        fi
        
        if [[ "$installer" == *.sh ]]; then
            if ! packages::run_script_installer "$installer" "$program"; then
                log_error "$program installation failed"
            fi
        else
            local packages=()
            local to_install=()
            local available=()
            
            if ! packages::load_package_list "$installer" packages; then
                continue
            fi
            
            log_info "Processing $program packages (${#packages[@]} total)..."
            
            packages::filter_installed "$PACMAN_HELPER" packages to_install
            
            if [[ ${#to_install[@]} -eq 0 ]]; then
                log_success "$program: all packages already installed"
                continue
            fi
            
            packages::check_available "$PACMAN_HELPER" to_install available
            
            if [[ ${#available[@]} -eq 0 ]]; then
                log_warn "$program: no packages available to install"
                continue
            fi
            
            log_info "Installing ${#available[@]} packages for $program..."
            if helpers::run_with_helper "$PACMAN_HELPER" "${available[@]}"; then
                log_success "$program packages installed"
            else
                log_warn "Failed to install $program packages (continuing)"
            fi
        fi
    done
}

packages::install_laptop() {
    local laptop_file="${SCRIPT_DIR}/packages/laptop.txt"
    local laptop_packages=()
    
    if ! packages::load_package_list "$laptop_file" laptop_packages; then
        log_warn "Laptop packages file not found"
        return 1
    fi
    
    log_info "Processing laptop packages (${#laptop_packages[@]} total)..."
    
    local to_install=()
    packages::filter_installed "$PACMAN_HELPER" laptop_packages to_install
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_success "All laptop packages already installed"
        return 0
    fi
    
    local available=()
    packages::check_available "$PACMAN_HELPER" to_install available
    
    if [[ ${#available[@]} -gt 0 ]]; then
        log_info "Installing ${#available[@]} laptop packages..."
        if helpers::run_with_helper "$PACMAN_HELPER" "${available[@]}"; then
            log_success "Laptop packages installed"
        else
            log_warn "Some laptop packages failed to install"
        fi
    fi
}
