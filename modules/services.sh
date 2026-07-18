#!/bin/bash

# Guard against multiple sourcing
if [[ -n "${_SERVICES_SOURCED:-}" ]]; then
    return
fi
readonly _SERVICES_SOURCED=1

source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Service activation functions

services::detect_available_dm() {
    local -n result=$1
    # Mapping table: DM name -> Service name (if different)
    # Using an associative array is cleaner if you have many
    local all_dms=("lightdm" "sddm" "gdm" "lxdm" "xdm" "ly" "greetd")
    local found_count=0
    
    for dm in "${all_dms[@]}"; do
        # Check if the binary exists in PATH (more reliable than just pacman)
        if command -v "$dm" &>/dev/null; then
            result+=("$dm")
            ((found_count++))
            log_debug "Found display manager: $dm"
        fi
    done
    
    return 0
}

services::select_login_manager() {
    log_section "Display Manager Setup"
    
    local available_dms=()
    services::detect_available_dm available_dms
    
    # Check if a DM is already enabled
    local enabled_dm
    enabled_dm=$(systemctl list-unit-files --type=service 2>/dev/null | grep -E "gdm|sddm|lightdm|lxdm|ly|greetd" | grep "enabled" | awk '{print $1}' | head -n 1)

    if [[ -n "$enabled_dm" ]]; then
        log_success "Display Manager already enabled: $enabled_dm"
        if ! helpers::prompt_yn "Change to a different display manager?"; then
            log_info "Keeping current display manager configuration"
            return 0
        fi
    fi

    if [[ ${#available_dms[@]} -eq 0 ]]; then
        log_warn "No display managers installed on system"
        
        if helpers::prompt_yn "Install lightdm now?"; then
            log_info "Installing lightdm..."
            # Note: lightdm usually needs a greeter to work out of the box
            if helpers::run_with_helper "$PACMAN_HELPER" lightdm lightdm-gtk-greeter; then
                log_success "lightdm installed"
                available_dms=("lightdm")
            else
                log_error "Failed to install lightdm"
                return 1
            fi
        else
            log_info "Skipping display manager setup"
            return 0
        fi
    fi
    
    local selected_dm
    
    if [[ ${#available_dms[@]} -eq 1 ]]; then
        selected_dm="${available_dms[0]}"
        log_info "Found installed display manager: $selected_dm"
        if ! helpers::prompt_yn "Enable $selected_dm?"; then
            return 0
        fi
    else
        # Multiple DMs Choice
        log_info "Found ${#available_dms[@]} display manager(s):"
        for i in "${!available_dms[@]}"; do
            echo "  $((i+1)). ${available_dms[$i]}"
        done
        echo "  $((${#available_dms[@]}+1)). Skip"
        
        local choice
        read -p "Select display manager to enable [1-$((${#available_dms[@]}+1))]: " choice
        
        if [[ $choice -eq $((${#available_dms[@]}+1)) ]] || [[ -z "$choice" ]]; then
            return 0
        fi
        
        selected_dm="${available_dms[$((choice-1))]}"
    fi

    # Handle the Service Enabling
    log_info "Configuring $selected_dm..."
    
    # Disable any existing DMs first to avoid conflicts
    sudo systemctl disable display-manager.service &>/dev/null
    
    if sudo systemctl enable "${selected_dm}.service" --force; then
        log_success "Enabled: $selected_dm"
        
        if helpers::prompt_yn "Start $selected_dm now? (Warning: This will log you out of your current session)"; then
            sudo systemctl start "${selected_dm}.service"
            
        fi
    else
        log_error "Failed to enable $selected_dm"
        return 1
    fi
}

services::setup_login_manager() {
    services::select_login_manager
}

services::setup_user_groups() {
    log_section "Configuring User Groups"
    
    local groups=("video" "audio" "input" "kvm")
    local current_user="${SUDO_USER:-$USER}"
    
    for group in "${groups[@]}"; do
        if getent group "$group" &>/dev/null; then
            if id -nG "$current_user" | grep -q "\b${group}\b"; then
                log_info "User already in group: $group"
            else
                log_info "Adding $current_user to group: $group"
                if sudo usermod -aG "$group" "$current_user"; then
                    log_success "Added $current_user to $group"
                else
                    log_warn "Failed to add $current_user to $group"
                fi
            fi
        fi
    done
    
    log_info "Please log out and log back in for group changes to take effect"
}