#!/usr/bin/env bash

##############################################################################
# Dotfiles Module - Syncs configuration files
##############################################################################

sync_dotfiles() {
    log_info "Syncing dotfiles..."

    local dotfiles_dir="${SCRIPT_DIR}/dotfiles"
    local config_dir="${HOME}/.config"
    local local_dir="${HOME}/.local"

    # Check if dotfiles directory exists
    if [[ ! -d "$dotfiles_dir" ]]; then
        log_warn "No dotfiles directory found at $dotfiles_dir"
        log_info "Creating structure for future dotfiles..."
        mkdir -p "$dotfiles_dir"/{config,local_bin,local_share}
        return 0
    fi

    # Sync .config files
    if [[ -d "${dotfiles_dir}/config" ]]; then
        log_info "Syncing config files..."
        rsync -av --backup --suffix=.bak "${dotfiles_dir}/config/" "${config_dir}/" 2>/dev/null || \
        cp -rv "${dotfiles_dir}/config"/* "${config_dir}/" 2>/dev/null || \
        log_warn "Could not sync config files"
    fi

    # Sync .local/bin files
    if [[ -d "${dotfiles_dir}/local_bin" ]]; then
        log_info "Syncing local bin files..."
        mkdir -p "${local_dir}/bin"
        rsync -av --backup --suffix=.bak "${dotfiles_dir}/local_bin/" "${local_dir}/bin/" 2>/dev/null || \
        cp -rv "${dotfiles_dir}/local_bin"/* "${local_dir}/bin/" 2>/dev/null || \
        log_warn "Could not sync bin files"

        # Make scripts executable
        chmod +x "${local_dir}/bin"/* 2>/dev/null || true
    fi

    # Sync .local/share files
    if [[ -d "${dotfiles_dir}/local_share" ]]; then
        log_info "Syncing local share files..."
        mkdir -p "${local_dir}/share"
        rsync -av --backup --suffix=.bak "${dotfiles_dir}/local_share/" "${local_dir}/share/" 2>/dev/null || \
        cp -rv "${dotfiles_dir}/local_share"/* "${local_dir}/share/" 2>/dev/null || \
        log_warn "Could not sync share files"
    fi

    # Sync shell configs if present
    if [[ -f "${dotfiles_dir}/.bashrc" ]]; then
        log_info "Syncing .bashrc..."
        if [[ -f "${HOME}/.bashrc" ]]; then
            cp "${HOME}/.bashrc" "${HOME}/.bashrc.bak.$(date +%s)"
        fi
        cp "${dotfiles_dir}/.bashrc" "${HOME}/.bashrc"
    fi

    if [[ -f "${dotfiles_dir}/.zshrc" ]]; then
        log_info "Syncing .zshrc..."
        if [[ -f "${HOME}/.zshrc" ]]; then
            cp "${HOME}/.zshrc" "${HOME}/.zshrc.bak.$(date +%s)"
        fi
        cp "${dotfiles_dir}/.zshrc" "${HOME}/.zshrc"
    fi

    log_success "Dotfiles synced successfully"
}

# Function to add a dotfile to the synced list
add_dotfile() {
    local source="$1"
    local target="${SCRIPT_DIR}/dotfiles/$(basename "$source")"

    if [[ ! -f "$source" ]]; then
        log_error "File not found: $source"
        return 1
    fi

    mkdir -p "$(dirname "$target")"
    cp "$source" "$target"
    log_success "Added dotfile: $(basename "$source")"
}
