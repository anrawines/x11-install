#!/bin/bash

# Quick setup - clones repo and runs installer

set -euo pipefail

REPO_URL="https://github.com/anrawines/x11-install.git"
INSTALL_DIR="$HOME/.local/x11-install"

echo "X11 Tiling WM Quick Setup"
echo "========================"

# Clone repository
if [[ -d "$INSTALL_DIR" ]]; then
    read -p "Directory already exists. Update? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$INSTALL_DIR"
        git pull origin main
    fi
else
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Make installer executable
chmod +x install.sh

# Run installer
./install.sh
