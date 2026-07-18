# X11 Tiling Window Manager Installer for Arch Linux

A clean, modular installer for setting up **multiple tiling window managers** on Arch Linux with all necessary packages and configurations.

## Features

- ✅ **Multi-WM Support** - Install multiple window managers (i3, bspwm, xmonad, awesome, dwm, etc.)
- ✅ **Category-Based Selection** - Choose WMs and program packages by category (laptop, dev, additional)
- ✅ **Modular & Organized** - Clear separation of concerns with easy customization
- ✅ **Smart Package Management** - Skips already-installed packages, handles both pacman and AUR
- ✅ **Configuration Sync** - Automatically syncs dotfiles to ~/.config and ~/.local/
- ✅ **Display Manager Auto-Config** - Detects and configures lightdm, sddm, gdm, lxdm
- ✅ **Safe & Non-Destructive** - Backs up existing configs before syncing

## Quick Start

### Clone and Run
```bash
git clone --depth 1 https://github.com/anrawines/x11-install.git
cd x11-install
chmod +x install.sh
./install.sh
```

### One-Command Setup
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/anrawines/x11-install/main/quick-setup.sh)
```

## Installation Flow

1. **System Checks** - Verify Arch Linux, internet, and disk space
2. **Helper Selection** - Choose pacman helper (pacman, yay, or paru)
3. **Window Manager Selection** - Select WMs from `packages/wm/` by number
4. **Program Selection** - Choose optional program packages (laptop, dev, additional, etc.)
5. **Installation & Config** - Install packages and sync dotfiles

## Project Structure

```
x11-install/
├── install.sh                  # Main installation script
├── quick-setup.sh              # One-liner setup
├── README.md                   # This file
├── modules/                    # Installation modules
│   ├── colors.sh               # Color definitions
│   ├── logger.sh               # Logging functions
│   ├── validators.sh           # System validation
│   ├── helpers.sh              # User input & selection
│   ├── directories.sh          # Directory setup
│   ├── packages.sh             # Package installation
│   ├── dotfiles.sh             # Config syncing
│   ├── services.sh             # Display manager setup
│   └── pacman.sh               # Pacman configuration
├── packages/                   # Package lists by category
│   ├── wm/                     # Window managers
│   │   ├── i3.txt
│   │   ├── bspwm.txt
│   │   ├── xmonad.txt
│   │   └── awesome.txt
│   ├── program/                # Optional programs (user selectable)
│   │   ├── laptop.txt          # Laptop-specific packages
│   │   ├── additional.txt      # General utilities
│   │   └── dev.txt             # Development tools
│   └── laptop.txt              # Always installed on laptops
└── dotfiles/                   # Configuration templates
    ├── config/                 # ~/.config/
    ├── local-bin/              # ~/.local/bin/
    └── local-share/            # ~/.local/share/ (fonts, themes, icons)
```

## Customization

### Add or Modify Package Lists

Create a new category file in `packages/program/`:
```bash
# Create a new category
nano packages/program/gaming.txt

# Add packages (one per line)
steam
lutris
wine
```

Then when you run the installer, `gaming` will appear as an option to select.

### Edit Existing Categories
```bash
# Modify window managers
nano packages/wm/i3.txt

# Modify program categories
nano packages/program/laptop.txt
nano packages/program/dev.txt
```

### Add Your Dotfiles

```bash
# Copy your configs (installer will sync these)
cp -r ~/.config/i3 dotfiles/config/
cp -r ~/.config/alacritty dotfiles/config/
cp -r ~/.local/bin/myscript dotfiles/local-bin/
cp -r ~/.local/share/fonts/* dotfiles/local-share/fonts/
```

## Modules Overview

| Module | Purpose |
|--------|---------|
| `install.sh` | Main orchestrator |
| `validators.sh` | System checks (Arch, internet, disk) |
| `helpers.sh` | User selection menus & prompts |
| `directories.sh` | XDG directory setup |
| `packages.sh` | Package loading, filtering, installation |
| `dotfiles.sh` | Configuration file syncing |
| `services.sh` | Display manager detection & setup |

## Usage

### After Installation

1. **Log out and back in** for group changes to take effect
2. **Select WM at login screen** from session menu
3. **Customize config** in `~/.config/<wm>/`
4. **Add scripts** to `~/.local/bin/`

### Keybind Reference
Press `WIN+/` to view keybindings in most WMs (if configured).

### Important Directories
```
~/.config/i3/              # i3 config
~/.config/alacritty/       # Terminal config
~/.local/bin/              # Custom scripts
~/.local/share/fonts/      # Custom fonts
```

## Troubleshooting

### Installation fails - package not found
```bash
# Check package name
pacman -Ss package-name
yay -Ss package-name  # For AUR packages
```

### Window manager won't start
```bash
# Verify installation
pacman -Q i3

# Check config
cat ~/.config/i3/config

# Test start
i3 --version
```

### Display manager issues
```bash
# Check status
systemctl status lightdm

# View logs
journalctl -u lightdm -n 50

# Restart
sudo systemctl restart lightdm
```

### Package conflicts (AUR)
The installer uses `--ask=4` for automatic resolution. If issues persist:
```bash
# Manual install
yay -S package-name --ask=4
```

## Contributing

Areas for improvement:
- Add support for more window managers
- Create themed configuration variants
- Add configuration wizard mode
- Improve error recovery
- Add uninstall functionality

## Resources

**Window Managers**
- [i3 WM](https://i3wm.org/)
- [bspwm](https://github.com/baskerville/bspwm)
- [XMonad](https://xmonad.org/)
- [Awesome](https://awesomewm.org/)

**Arch Wiki**
- [General recommendations](https://wiki.archlinux.org/title/General_recommendations)
- [Display Manager](https://wiki.archlinux.org/title/Display_manager)
- [Xorg](https://wiki.archlinux.org/title/Xorg)

## License

MIT License - Feel free to use and modify

## Support

For issues:
1. Check **Troubleshooting** section above
2. Review config examples in `dotfiles/`
3. Open an issue on [GitHub](https://github.com/anrawines/x11-install/issues)

---

**Happy tiling!** 🎹✨
