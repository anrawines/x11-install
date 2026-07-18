#!/bin/bash

# Guard against multiple sourcing
if [[ -n "${_DOTFILES_SOURCED:-}" ]]; then
    return
fi
readonly _DOTFILES_SOURCED=1

source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

##############################################################################
# Dotfiles Module - Syncs configuration files
##############################################################################

# Helper to ensure scripts in .config are executable
_ensure_scripts_executable() {
    log_info "Ensuring configuration scripts are executable..."

    # 1. Handle .local/bin
    if [[ -d "$HOME/.local/bin" ]]; then
        chmod +x "$HOME/.local/bin"/* 2>/dev/null || true
    fi

    # 2. Handle common script patterns in .config (like polybar/launch.sh)
    # We look for files ending in .sh or specifically named launch.sh
    find "$HOME/.config" -type f \( -name "*.sh" -o -name "launch.sh" \) -exec chmod +x {} + 2>/dev/null || true

    log_success "Script permissions updated."
}

# Helper to sync home-level dotfiles (bashrc, zshrc, etc)
_sync_home_dotfiles() {
    local src_home="${SCRIPT_DIR}/dotfiles/home"
    if [[ ! -d "$src_home" ]]; then
        return 0
    fi

    if ! helpers::prompt_yn "Sync home dotfiles (like .bashrc, .zshrc)?"; then
        log_info "Skipping home dotfiles sync."
        return 0
    fi

    log_info "Syncing home dotfiles (.bashrc, .zshrc, etc.)..."
    # We use dotglob to catch files starting with '.'
    shopt -s dotglob
    for file in "$src_home"/*; do
        local filename=$(basename "$file")
        local target="$HOME/$filename"

        [[ -f "$target" ]] && cp "$target" "${target}.bak.$(date +%s)"
        cp -r "$file" "$target"
        log_info "Synced $filename"
    done
    shopt -u dotglob
}

# Dotfiles syncing functions

dotfiles::sync_configs() {
    local dotfiles_src="${SCRIPT_DIR}/dotfiles"

    log_section "Syncing Configuration Files"

    # Check if dotfiles directory exists
    if [[ ! -d "$dotfiles_src" ]]; then
        log_error "Dotfiles directory not found: $dotfiles_src"
        return 1
    fi

    local synced_count=0

    # 1. Sync Home dotfiles
    _sync_home_dotfiles

    # Sync WM-specific configs
    log_info "Syncing window manager configs..."
    for wm in "${!SELECTED_WMS[@]}"; do
        local src="${dotfiles_src}/config/${wm}"
        local dst="$HOME/.config/${wm}"

        if [[ ! -d "$src" ]]; then
            log_warn "Config directory not found for $wm: $src"
            continue
        fi

        log_info "Processing $wm configuration..."

        # Backup existing config
        if [[ -d "$dst" ]]; then
            local backup="${dst}.backup.$(date +%s)"
            log_warn "Backing up existing config to: $backup"
            if ! mv "$dst" "$backup"; then
                log_error "Failed to backup $dst"
                continue
            fi
        fi

        # Copy new config
        if cp -r "$src" "$dst"; then
            log_success "Synced $wm configuration"
            ((synced_count++))
        else
            log_error "Failed to sync $wm configuration"
        fi
    done

    # Sync common app configs (alacritty, kitty, picom, etc)
    if helpers::prompt_yn "Sync common application configs (Alacritty, Kitty, Thunar etc.)?"; then
        log_info "Syncing common application configs..."
        local common_apps=("alacritty" "kitty" "bash" "zsh" "Thunar" "gtk-2.0" "gtk-3.0" "gtk-4.0" "rofi")

        for app in "${common_apps[@]}"; do
            local src="${dotfiles_src}/config/${app}"
            local dst="$HOME/.config/${app}"

            if [[ ! -d "$src" ]]; then
                log_info "No config found for $app (skipping)"
                continue
            fi

            log_info "Syncing $app configuration..."

            # Backup existing config
            if [[ -d "$dst" ]]; then
                local backup="${dst}.backup.$(date +%s)"
                log_warn "Backing up existing $app config to: $backup"
                if ! mv "$dst" "$backup"; then
                    log_warn "Failed to backup $dst"
                fi
            fi

            # Copy new config
            if cp -r "$src" "$dst"; then
                log_success "Synced $app configuration"
                ((synced_count++))
            else
                log_warn "Failed to sync $app configuration"
            fi
        done
    else
        log_info "Skipping common application configurations."
    fi

    # Sync local-bin scripts
    local local_bin_src="${dotfiles_src}/local-bin"
    if [[ -d "$local_bin_src" ]]; then
        log_info "Syncing local bin scripts..."
        local bin_count
        bin_count=$(find "$local_bin_src" -type f 2>/dev/null | wc -l)

        if [[ $bin_count -gt 0 ]]; then
            mkdir -p "$HOME/.local/bin"
            if cp -r "$local_bin_src"/* "$HOME/.local/bin/" 2>/dev/null; then
                log_success "Synced $bin_count local bin scripts"
                ((synced_count++))
            else
                log_warn "Failed to sync local bin scripts"
            fi
        else
            log_info "No bin scripts found (skipping)"
        fi
    fi

    # Sync local-share files (fonts, themes, icons, etc)
    local local_share_src="${dotfiles_src}/local-share"
    if [[ -d "$local_share_src" ]]; then
        log_info "Syncing local share files..."
        local share_count
        share_count=$(find "$local_share_src" -type f 2>/dev/null | wc -l)

        if [[ $share_count -gt 0 ]]; then
            if cp -r "$local_share_src"/* "$HOME/.local/share/" 2>/dev/null; then
                log_success "Synced $share_count local share files"
                ((synced_count++))
            else
                log_warn "Failed to sync local share files"
            fi
        else
            log_info "No share files found (skipping)"
        fi
    fi

    # Sync Wallpapers
    local wallpaper_src="${dotfiles_src}/wallpapers"
    local wallpaper_dst="${HOME}/Pictures/wallpapers"
    if [[ -d "$wallpaper_src" ]]; then
        log_info "Syncing wallpapers to $wallpaper_dst..."
        mkdir -p "$wallpaper_dst"
        if cp -r "$wallpaper_src"/* "$wallpaper_dst/" 2>/dev/null; then
            log_success "Wallpapers synced"
        else
            log_warn "Failed to sync wallpapers"
        fi
    fi

    # Ensure all scripts are executable after copying
    _ensure_scripts_executable

    log_success "Dotfiles sync complete ($synced_count items synced)"
    return 0
}
