# Contributing to X11 Installer

Thank you for your interest in improving this installer!

## How to Contribute

### Adding New Packages

Package definitions are located in `packages/wm/` and `packages/program/` directories.

#### Simple Package Lists (.txt format)

For straightforward package installations without post-install steps, use `.txt` files:

Format: One package per line, with optional comments starting with `#`

Example: `packages/wm/i3.txt`
```
# Window manager
i3-wm
i3-gaps

# Status bar
i3status

# Utilities
dmenu
```

#### Complex Package Installers (.sh format)

For window managers or programs that require:
- Post-install configuration/compilation
- Build-time steps (suckless tools)
- Conditional installations
- Service enablement

Use `.sh` files. The installer system will automatically detect and execute them.

Example structure for `packages/wm/xmonad.sh`:

```bash
#!/bin/bash

packages::install() {
    # Define package groups
    local base_packages=("xmonad" "xmonad-contrib")
    local utils=("rofi" "picom")
    
    # Install packages
    log_info "Installing Xmonad packages..."
    if ! helpers::run_with_helper "$PACMAN_HELPER" "${base_packages[@]}"; then
        log_error "Failed to install"
        return 1
    fi
    
    # Post-install steps
    log_info "Compiling Xmonad configuration..."
    xmonad --recompile
    
    log_success "Xmonad installation complete"
    return 0
}
```

**Key requirements for .sh installers:**
- Must define a `packages::install()` function
- Function must return 0 on success, non-zero on failure
- Use logging functions: `log_info()`, `log_success()`, `log_warn()`, `log_error()`
- Use `helpers::run_with_helper "$PACMAN_HELPER"` for package installation
- Can use all variables from main install context (e.g., `$SCRIPT_DIR`, `$PACMAN_HELPER`)

**Example: Suckless tool (dwm.sh)**
```bash
packages::install() {
    # Install build deps
    helpers::run_with_helper "$PACMAN_HELPER" "base-devel" "git" "libx11"
    
    # Clone and compile from source
    local src_dir="${HOME}/.local/src"
    mkdir -p "$src_dir"
    cd "$src_dir"
    
    git clone https://git.suckless.org/dwm
    cd dwm
    make
    sudo make install
    
    log_success "DWM built and installed"
    return 0
}
```

### Creating New Modules

1. Create a new file in `modules/` with a descriptive name
2. Follow the existing module pattern:
   ```bash
   #!/usr/bin/env bash

   ##############################################################################
   # Module Name - Brief Description
   ##############################################################################

   main_function() {
       log_info "Starting..."
       # Your code here
       log_success "Done!"
   }
   ```

3. Source the module in `install.sh`
4. Call the appropriate function in the main workflow

### Adding Configuration Examples

1. Create new example files in `config/` directory
2. Use `.example` extension
3. Add comprehensive comments
4. Reference them in the README

### Improving Existing Modules

- Ensure backward compatibility
- Add comments for complex logic
- Test on clean Arch installations
- Update README if behavior changes

## Code Style

- Use `set -euo pipefail` for error handling
- Use the provided log functions: `log_info`, `log_success`, `log_warn`, `log_error`
- Keep functions focused and modular
- Add descriptive comments
- Use meaningful variable names

## Testing

Before submitting changes:

1. Test on a fresh Arch Linux installation (VM recommended)
2. Test with different inputs (skip steps, use alternatives)
3. Verify all configuration files are created
4. Check that backups are created correctly
5. Test with different login managers (if modified)
6. For package .sh files: verify both installation and post-install steps work

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/description`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages: `git commit -m "Add/Fix: Clear description"`
6. Push to your fork
7. Create a Pull Request with description of changes

## Documentation

- Update README.md if adding features
- Add inline comments for complex logic
- Document any new configuration options
- Include usage examples
- For new .sh installers: document what post-install steps are performed

## Issues and Suggestions

- Check existing issues first
- Describe the problem clearly
- Include steps to reproduce (for bugs)
- Suggest solutions if you have them
- Mention your Arch Linux version and environment

## Code Review Standards

Code will be reviewed for:
- Correctness and reliability
- Security implications
- Code style and clarity
- Documentation quality
- Backward compatibility

## Questions?

Feel free to open an issue with the `question` label or discussion thread.

---

Thank you for helping make this installer better! 🚀
