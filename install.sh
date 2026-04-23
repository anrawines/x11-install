#!/usr/bin/env bash

##############################################################################
# bspwm Arch Linux Installer - Main Script
# A modular installer for bspwm with all necessary components
##############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"

##############################################################################
# Logging Functions
##############################################################################

log_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

##############################################################################
# Utility Functions
##############################################################################

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root!"
        exit 1
    fi
}

check_arch() {
    if ! command -v pacman &> /dev/null; then
        log_error "This script requires Arch Linux (pacman not found)"
        exit 1
    fi
}

source_module() {
    local module="$1"
    local module_path="${MODULES_DIR}/${module}.sh"

    if [[ ! -f "$module_path" ]]; then
        log_error "Module not found: $module"
        return 1
    fi

    source "$module_path"
}

##############################################################################
# Main Installation Flow
##############################################################################

main() {
    log_info "=========================================="
    log_info "  bspwm Arch Linux Installer"
    log_info "=========================================="

    # Verify environment
    check_root
    check_arch

    # Load modules
    log_info "Loading modules..."
    source_module "packages"
    source_module "system"
    source_module "directories"
    source_module "dotfiles"
    source_module "config"

    # Confirmation prompt
    echo ""
    log_warn "This installer will:"
    echo "  • Install bspwm and dependencies"
    echo "  • Create necessary directories in ~/.config"
    echo "  • Sync dotfiles to appropriate locations"
    echo "  • Configure login manager"
    echo ""
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Installation cancelled"
        exit 0
    fi

    # Installation steps
    log_info "Step 1/5: Installing packages..."
    install_packages

    log_info "Step 2/5: Setting up system..."
    setup_system_services

    log_info "Step 3/5: Creating directories..."
    create_user_directories

    log_info "Step 4/5: Syncing dotfiles..."
    sync_dotfiles

    log_info "Step 5/5: Configuring system..."
    configure_login_manager

    # Summary
    echo ""
    log_success "=========================================="
    log_success "  Installation Complete!"
    log_success "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Log out and back in to apply changes"
    echo "  2. Select bspwm from your login manager"
    echo "  3. Configure bspc rules in ~/.config/bspwm/bspwmrc"
    echo ""
}

# Run main
main "$@"
