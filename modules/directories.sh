#!/bin/bash

# Guard against multiple sourcing
if [[ -n "${_DIRECTORIES_SOURCED:-}" ]]; then
    return
fi
readonly _DIRECTORIES_SOURCED=1

source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Directory creation functions

directories::create_user_dirs() {
    local dirs=(
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/.local/share"
        "$HOME/.local/share/fonts"
        "$HOME/.local/share/themes"
        "$HOME/.local/share/icons"
        "$HOME/.local/share/applications"
        "$HOME/.cache"
        "$HOME/.themes"
        "$HOME/.icons"
        "$HOME/Pictures/wallpapers"
        "$HOME/Music"
        "$HOME/Videos"
        "$HOME/Downloads"
        "$HOME/Documents"
        "$HOME/Projects"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir"; then
                log_success "Created: $dir"
            else
                log_error "Failed to create: $dir"
                return 1
            fi
        else
            log_info "Exists: $dir"
        fi
    done
}
