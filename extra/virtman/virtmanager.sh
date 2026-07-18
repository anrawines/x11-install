#!/usr/bin/env bash

# set -euo pipefail

# Determine script and project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
MODULES_DIR="${PARENT_DIR}/modules"

# Source project modules
if [[ -f "${MODULES_DIR}/logger.sh" ]]; then
    source "${MODULES_DIR}/logger.sh"
else
    echo "Error: Logger module not found at ${MODULES_DIR}/logger.sh"
    exit 1
fi

if [[ -f "${MODULES_DIR}/helpers.sh" ]]; then
    source "${MODULES_DIR}/helpers.sh"
fi

# Packages needed for Virt-Manager
VIRT_PACKAGES=(
    "dnsmasq"
    "dmidecode"
    "qemu-full"
    "vde2"
    "openbsd-netcat"
    "virt-manager"
    "libvirt"
    "bridge-utils"
    "ebtables"
    "iptables-nft"
)

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &>/dev/null
}

# 1. Install Packages
install_virt_packages() {
    log_section "Installing Virt-Manager and QEMU"
    
    local to_install=()
    for pkg in "${VIRT_PACKAGES[@]}"; do
        if is_installed "$pkg"; then
            log_info "Package already installed: $pkg"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing missing packages: ${to_install[*]}"
        sudo pacman -S --needed --noconfirm "${to_install[@]}"
    else
        log_success "All required packages are already installed."
    fi
}

# 2. Configure Libvirtd
configure_libvirtd() {
    log_section "Configuring Libvirtd"
    
    # Ensure directory exists
    sudo mkdir -p /etc/libvirt

    # Copy libvirtd.conf
    if [[ -f "${SCRIPT_DIR}/libvirtd.conf" ]]; then
        log_info "Applying libvirtd.conf..."
        sudo cp -v "${SCRIPT_DIR}/libvirtd.conf" /etc/libvirt/libvirtd.conf
    fi

    # Copy network.conf
    if [[ -f "${SCRIPT_DIR}/network.conf" ]]; then
        log_info "Applying network.conf..."
        sudo cp -v "${SCRIPT_DIR}/network.conf" /etc/libvirt/network.conf
    fi
}

# 3. User Group Setup
setup_user_group() {
    log_section "User Group Configuration"
    local current_user="${SUDO_USER:-$USER}"
    
    if id -nG "$current_user" | grep -q "\blibvirt\b"; then
        log_success "User $current_user is already in the libvirt group."
    else
        log_info "Adding $current_user to libvirt group..."
        sudo usermod -a -G libvirt "$current_user"
        log_warn "You may need to log out and back in for group changes to take effect."
    fi
}

# 4. Service Management
manage_services() {
    log_section "Service Management"
    
    log_info "Enabling and starting libvirtd..."
    sudo systemctl enable --now libvirtd
    
    if systemctl is-active --quiet libvirtd; then
        log_success "libvirtd service is active."
    else
        log_error "Failed to start libvirtd service."
    fi
}

# 5. Network Configuration
configure_network() {
    log_section "Network Configuration"
    
    # Check if default network is already defined
    if sudo virsh net-list --all | grep -q "default"; then
        log_info "Default network is already defined."
    else
        log_info "Defining default network..."
        # Try to find the default xml if it exists
        if [[ -f /etc/libvirt/qemu/networks/default.xml ]]; then
             sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
        else
             log_warn "Default network XML not found at /etc/libvirt/qemu/networks/default.xml"
             log_info "Attempting to use libvirt's built-in default network..."
        fi
    fi

    # Start and autostart default network
    log_info "Ensuring default network is active and set to autostart..."
    sudo virsh net-start default 2>/dev/null || true
    sudo virsh net-autostart default
    
    if sudo virsh net-list --active | grep -q "default"; then
        log_success "Default network is active and set to autostart."
    else
        log_warn "Default network is defined but could not be started automatically. This is common if bridge-utils/iptables are missing."
    fi
}

# Main Execution
main() {
    log_section "Virt-Manager Setup Script"
    
    install_virt_packages
    configure_libvirtd
    setup_user_group
    manage_services
    configure_network
    
    log_section "Setup Complete"
    log_success "Virt-Manager and QEMU have been configured."
    log_info "Reboot or relog is recommended to apply all changes."
}

main "$@"
