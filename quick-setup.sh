#!/bin/bash

##############################################################################
# Quick Start Script for bspwm Setup
# Run this script to quickly clone and setup bspwm
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   bspwm Arch Linux Quick Installer     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git first:"
    echo "  sudo pacman -S git"
    exit 1
fi

# Clone repository if not already present
REPO_DIR="${HOME}/Projects/x11-bspwm"

if [ ! -d "$REPO_DIR" ]; then
    echo "📦 Cloning repository..."
    git clone https://github.com/anrawines/x11-bspwm.git "$REPO_DIR"
else
    echo "✓ Repository already exists at $REPO_DIR"
    echo "  Updating..."
    cd "$REPO_DIR"
    git pull origin main
fi

cd "$REPO_DIR"

echo ""
echo "${GREEN}✓${NC} Repository ready at: $REPO_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $REPO_DIR"
echo "  2. Review and customize packages/base.txt and packages/additional.txt"
echo "  3. ./install.sh"
echo ""
echo "For more information, see README.md"
echo ""
