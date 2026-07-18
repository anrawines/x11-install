#!/bin/bash

# Maintenance script to keep Arch Linux clean

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/modules/colors.sh"
source "${SCRIPT_DIR}/modules/logger.sh"
source "${SCRIPT_DIR}/modules/helpers.sh"

clean_orphans() {
  log_info "Checking for orphaned packages..."
  local orphans
  orphans=$(pacman -Qdtq 2>/dev/null || true)
  if [[ -n "$orphans" ]]; then
    echo "$orphans"
    if helpers::prompt_yn "Would you like to remove these orphans?"; then
      sudo pacman -Rs $orphans
      log_success "Orphans removed."
    fi
  else
    log_success "No orphaned packages found."
  fi
}

clean_pacman_cache() {
  log_info "Cleaning pacman cache..."
  if ! command -v paccache &>/dev/null; then
    log_warn "pacman-contrib not found. Installing it to use paccache..."
    sudo pacman -S --noconfirm pacman-contrib
  fi

  # Paccache is not thread-safe. Run sequentially to avoid race conditions.
  log_info "Keeping only the last 2 versions of installed packages..."
  sudo paccache -rk2
  log_info "Removing all cached versions of uninstalled packages..."
  sudo paccache -ruk0
  log_success "Pacman cache cleaned."
}

clean_journal() {
  log_info "Vacuuming systemd journal logs..."
  # More robust vacuuming
  sudo journalctl --vacuum-time=3d --vacuum-size=50M
  log_success "Journal vacuumed."
}

clean_aur_cache() {
  if command -v yay &>/dev/null; then
    log_info "Cleaning yay cache..."
    yay -Sc --noconfirm
    log_success "yay cache cleaned."
  elif command -v paru &>/dev/null; then
    log_info "Cleaning paru cache..."
    paru -Sc --noconfirm
    log_success "paru cache cleaned."
  fi
}

clean_user_cache() {
  local cache_size
  cache_size=$(du -sh ~/.cache | cut -f1)
  log_info "Current user cache (~/.cache) size: $cache_size"

  if helpers::prompt_yn "Would you like to clear the user cache folder?"; then
    rm -rf ~/.cache/*
    log_success "User cache cleared."
  fi
}

clean_dangling_symlinks() {
  log_info "Checking for dangling symlinks..."
  # Using -xtype l is more robust and faster than -exec test
  local dangling
  dangling=$(find /usr /opt /home -xtype l -print 2>/dev/null)
  if [[ -n "$dangling" ]]; then
    echo "$dangling"
    if helpers::prompt_yn "Would you like to remove these dangling symlinks?"; then
      echo "$dangling" | xargs rm -f
      log_success "Dangling symlinks removed."
    fi
  else
    log_success "No dangling symlinks found."
  fi
}

check_failed_services() {
  log_info "Checking for failed systemd services..."
  # More robust way to check failed services
  local failed_count
  failed_count=$(systemctl list-units --failed --no-legend | wc -l)
  if [[ "$failed_count" -gt 0 ]]; then
    log_warn "There are $failed_count failed systemd services:"
    systemctl list-units --failed --no-legend
  else
    log_success "No failed systemd services found."
  fi
}

main() {
  log_section "Arch System Maintenance"

  if [[ $EUID -eq 0 ]]; then
    log_error "Please do not run this script as root directly. It will ask for sudo when needed."
    exit 1
  fi

  # Cache password upfront to avoid multiple sudo prompts
  #sudo -v

  # Run cleanup tasks sequentially to avoid sudo prompt conflicts
  log_info "Starting cleanup tasks..."
  clean_orphans
  clean_journal
  clean_pacman_cache
  clean_aur_cache

  log_success "Cleanup tasks finished."
  log_info "Running user-space cleanup..."
  clean_user_cache
  check_failed_services

  log_section "Maintenance Complete"
  log_success "Your system is now leaner and cleaner!"
}

main "$@"
