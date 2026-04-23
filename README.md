# bspwm Arch Linux Installer

A modular, automated installer script for setting up **bspwm** (Binary Space Partitioning Window Manager) on Arch Linux with all necessary components and configuration.

## Features

✅ **Modular Design** - Organized scripts for different installation phases
✅ **Automatic Package Management** - Handles both pacman and AUR packages
✅ **Configuration Management** - Creates directory structure and syncs dotfiles
✅ **Login Manager Support** - Auto-detects and configures xinit, lightdm, gdm, sddm
✅ **Easy Customization** - Simple package lists and example configurations
✅ **Safe Installation** - Backs up existing configuration files

## Project Structure

```
x11-bspwm/
├── install.sh              # Main installation script
├── README.md               # This file
├── modules/                # Modular installation scripts
│   ├── packages.sh         # Package installation logic
│   ├── system.sh           # System services configuration
│   ├── directories.sh      # Directory structure setup
│   ├── dotfiles.sh         # Dotfiles synchronization
│   └── config.sh           # Login manager and final config
├── packages/               # Package lists
│   ├── base.txt            # Essential packages
│   ├── additional.txt       # Optional packages
│   └── aur.txt             # AUR packages
├── config/                 # Example configuration files
│   ├── bspwmrc.example     # bspwm configuration
│   ├── sxhkdrc.example     # Hotkey configuration
│   ├── polybar.example     # Status bar configuration
│   └── picom.example       # Compositor configuration
└── dotfiles/               # Your dotfiles (to be synced)
    ├── config/             # ~/.config files
    ├── local_bin/          # ~/.local/bin scripts
    └── local_share/        # ~/.local/share files
```

## Prerequisites

- **Arch Linux** system
- **sudo** access (without requiring password for pacman, optional)
- **git** installed
- Internet connection

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/x11-bspwm.git
cd x11-bspwm
```

### 2. Make the install script executable

```bash
chmod +x install.sh
```

### 3. Run the installer

```bash
./install.sh
```

The installer will:
1. Check system requirements
2. Install base and additional packages
3. Create necessary directory structure
4. Sync dotfiles
5. Configure login manager
6. Provide next steps

## Customization

### Modify Package Lists

Edit the package files to add/remove packages:

```bash
# Essential packages
vim packages/base.txt

# Optional packages
vim packages/additional.txt

# AUR packages (optional)
vim packages/aur.txt
```

### Add Your Dotfiles

Place your configuration files in the appropriate directories:

```bash
# bspwm configuration
cp ~/.config/bspwm/bspwmrc dotfiles/config/bspwm/

# Hotkey configuration
cp ~/.config/sxhkd/sxhkdrc dotfiles/config/sxhkd/

# Custom scripts
cp ~/.local/bin/myscript dotfiles/local_bin/

# Shell configuration
cp ~/.bashrc dotfiles/
cp ~/.zshrc dotfiles/
```

### Use Your Own Configurations

Replace the example files:

```bash
# For bspwmrc
cp your-bspwmrc config/bspwmrc.example

# For sxhkdrc
cp your-sxhkdrc config/sxhkdrc.example

# For polybar
cp your-polybar config/polybar.example
```

## Files Overview

### Main Script (`install.sh`)
- Handles logging and user interaction
- Loads and executes modules
- Provides step-by-step installation feedback

### Modules

#### `modules/packages.sh`
- Installs packages from pacman repositories
- Handles optional AUR package installation
- Auto-generates default package lists if missing
- Supports yay or paru as AUR helpers

#### `modules/system.sh`
- Enables multilib repository (for 64-bit systems)
- Configures D-Bus
- Provides utilities for service management

#### `modules/directories.sh`
- Creates ~/.config subdirectories
- Creates ~/.local/bin and ~/.local/share structure
- Optionally generates skeleton configuration files

#### `modules/dotfiles.sh`
- Syncs dotfiles from the dotfiles/ directory
- Backs up existing configurations with .bak suffix
- Supports .bashrc, .zshrc, and custom configurations

#### `modules/config.sh`
- Detects available login managers
- Configures selected login manager
- Generates ~/.xinitrc for xinit users
- Sets up font cache

## Configuration Examples

### Example: bspwmrc

The `config/bspwmrc.example` includes:
- Monitor and desktop setup
- Border and gap configuration
- Color scheme (Nord theme)
- Autostart applications (sxhkd, picom, dunst)
- Window rules for specific applications

Customize by editing the example or providing your own.

### Example: sxhkdrc

The `config/sxhkdrc.example` includes:
- Terminal launcher (super + Return)
- Application menu (super + space)
- Window navigation and management
- Desktop switching
- Volume/brightness controls

### Example: polybar

Basic polybar configuration with:
- bspwm workspace indicators
- Window title display
- System stats (CPU, RAM)
- Date and time
- Pulse audio volume control

### Example: picom

Compositor configuration with:
- Shadow effects
- Smooth fading transitions
- Opacity rules
- Backend optimization

## Usage After Installation

### Starting bspwm

**With xinit:**
```bash
startx
```

**With a login manager:**
1. Log in through the login screen
2. Select "bspwm" from the session menu
3. Enter your password

### Hotkey Cheat Sheet

| Action | Keys |
|--------|------|
| New terminal | `super + Return` |
| App launcher | `super + space` |
| Close window | `super + w` |
| Focus window | `super + hjkl` |
| Move window | `super + shift + hjkl` |
| Switch desktop | `super + 1-5` |
| Send to desktop | `super + shift + 1-5` |
| Toggle floating | `super + shift + space` |
| Fullscreen | `super + f` |
| Monocle layout | `super + m` |

See `config/sxhkdrc.example` for complete hotkey list.

## Troubleshooting

### Installation fails at package installation

- Ensure you have internet connectivity
- Try updating pacman first: `sudo pacman -Syu`
- Check that the package names in `packages/base.txt` are correct for your Arch version

### X won't start

- Verify xorg packages are installed: `pacman -Q xorg-server`
- Check ~/.xinitrc exists and is executable
- Review logs: `startx 2>&1 | tee startx.log`

### bspwm doesn't start

- Ensure bspwm is installed: `pacman -Q bspwm`
- Check ~/.config/bspwm/bspwmrc exists and is executable
- Verify sxhkd is running and configured correctly

### AUR package installation fails

- Install an AUR helper: `yay -Sy` or `paru -Sy`
- Update packages: `yay -Su`

## Contributing

Feel free to improve this installer! Some ideas:

- Add support for other Linux distributions
- Create themed package/config variants
- Add pre/post-installation hooks
- Create configuration wizard mode

## License

MIT License - Feel free to use and modify

## Resources

- [bspwm Documentation](https://github.com/baskerville/bspwm)
- [sxhkd Documentation](https://github.com/baskerville/sxhkd)
- [Arch Wiki - bspwm](https://wiki.archlinux.org/title/bspwm)
- [Arch Wiki - xinit](https://wiki.archlinux.org/title/Xinit)

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review configuration examples in `config/`
3. Consult the official documentation links
4. Open an issue on the repository

---

**Happy tiling!** 🎹

