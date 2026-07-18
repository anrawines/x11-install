# Copilot Instructions for X11 Installer

This is a **modular Bash installation framework** for setting up tiling window managers and packages on Arch Linux. The codebase uses a namespace pattern and module-based architecture to maintain clarity and reusability.

## Architecture Overview

**High-level flow:**
1. `install.sh` (main orchestrator) sources all modules from `modules/`
2. Modules handle specific concerns: validation, helpers, packages, dotfiles, services
3. Package installers in `packages/wm/` and `packages/program/` are loaded dynamically
4. Modules communicate via global arrays and functions; no sub-processes

**Key design patterns:**
- **Guard sourcing**: Each module begins with `if [[ -n "${_MODULE_SOURCED:-}" ]]; then return; fi` to prevent duplicate sourcing
- **Namespace functions**: All functions use `module::function_name()` format (e.g., `helpers::prompt_yn()`)
- **Bash name references**: Functions return arrays using `local -n array_name=$1` to avoid subshells
- **Error handling**: All scripts use `set -euo pipefail` at the top for strict error handling
- **Logging**: All user feedback goes through `log_info()`, `log_success()`, `log_warn()`, `log_error()`, `log_section()`

## Key Modules

### Module Interaction Flow

```
install.sh (main)
├── validators.sh      → Check Arch, internet, disk, pacman
├── pacman.sh          → Enable multilib, parallel downloads
├── helpers.sh         → Present selection menus, detect installed WMs
├── packages.sh        → Load, filter, install packages
│   └── packages/{wm,program}/*.{sh,txt}  → Per-package installers
├── directories.sh     → Create XDG directories
├── dotfiles.sh        → Sync configs from dotfiles/
└── services.sh        → Setup display manager & user groups
```

### Module Responsibilities

| Module | Key Functions | Returns |
|--------|---------------|---------|
| `helpers.sh` | `list_category_options()`, `detect_installed_wms()`, `select_window_managers()`, `select_optional_programs()`, `run_with_helper()` | Arrays, user selections |
| `packages.sh` | `load_package_list()`, `filter_installed()`, `run_script_installer()`, `install_wm_packages()` | Success/failure codes |
| `dotfiles.sh` | `sync_configs()` | Success/failure codes |
| `services.sh` | `detect_available_dm()`, `setup_login_manager()` | DM names, success codes |
| `validators.sh` | `is_arch_based()`, `check_system()`, `is_valid_wm()` | Boolean checks, exits on failure |

## Global Variables

```bash
SCRIPT_DIR              # Root of this repository (set in install.sh)
PACMAN_HELPER           # "yay", "paru", or "" (selected by user)
declare -gA SELECTED_WMS          # Hash map of selected WMs: ["i3"]="1"
declare -gA SELECTED_PROGRAMS     # Hash map of selected programs: ["laptop"]="1"
INSTALL_ON_LAPTOP       # Boolean flag (0 or 1)
```

All global arrays/maps are read/modified across modules via this pattern:
```bash
# In helpers.sh: set a global
SELECTED_WMS["i3"]="1"

# In packages.sh: read it
for wm in "${!SELECTED_WMS[@]}"; do
    packages::install_wm "$wm"
done
```

## Package Installer System

**Two formats for packages:**

### `.txt` files (simple package lists)
Used for packages with no post-install steps. Format: one package per line, `#` comments allowed.
- Example: `packages/wm/i3.txt`, `packages/program/dev.txt`
- Installation: `helpers::run_with_helper` directly installs from package list

### `.sh` files (complex installers)
Used for packages needing build steps, compilation, or verification. Must define:
- `packages::install()` - Main install function, return 0 on success
- `packages::check()` (optional) - Verify installation success

Example `.sh` structure:
```bash
#!/bin/bash

packages::install() {
    log_info "Installing..."
    helpers::run_with_helper "$PACMAN_HELPER" "base-devel" "git"
    # Custom steps...
    log_success "Done"
    return 0
}

packages::check() {
    log_info "Verifying..."
    if command -v dwm &>/dev/null; then
        log_success "Verified"
        return 0
    fi
    log_error "Not found"
    return 1
}
```

**How installers are called:**
1. `packages::get_installer()` finds `.sh` or `.txt` for a package
2. For `.sh`: `packages::run_script_installer()` sources it, calls `packages::install()`, then `packages::check()` if defined
3. For `.txt`: `packages::load_package_list()` extracts package names, then `packages::filter_installed()` skips already-installed, then `helpers::run_with_helper` installs

## Common Tasks

### Add a new window manager or program

1. Create `packages/wm/newwm.txt` (or `.sh` if build steps needed):
   ```
   # Packages for newwm
   newwm
   xorg-server
   xorg-xinit
   ```

2. Add dotfiles in `dotfiles/config/newwm/` with configuration

3. If `.sh` installer needed, define `packages::install()` to:
   - Install base packages via `helpers::run_with_helper`
   - Perform build/config steps
   - Return 0 on success

### Detect an installed window manager correctly

The `helpers::detect_installed_wms()` function:
- For `.txt` files: checks if first package (main WM) is installed via `pacman -Qi`
- For `.sh` files: sources the script and calls `packages::check()`, or falls back to checking if binary is in PATH

When adding a new window manager, ensure:
- Main package is listed first in `.txt`, or
- `packages::check()` correctly verifies installation in `.sh`

### Add logging to output

Use these functions (sourced from `logger.sh`):
```bash
log_info "Informational message"
log_success "✓ Action completed"
log_warn "Warning message (yellow)"
log_error "Error message (red, to stderr)"
log_section "Major section header"
```

### Work with arrays in functions

Return arrays via name reference to avoid subshells:
```bash
# Function that returns an array
my_function() {
    local -n result=$1  # $1 is the name of the array variable
    result+=("value1")
    result+=("value2")
}

# Calling code
local my_array=()
my_function my_array  # Pass variable name as string
echo "${my_array[@]}"  # Contains value1, value2
```

### Running commands with the selected package helper

Always use `helpers::run_with_helper` for pacman/AUR operations:
```bash
helpers::run_with_helper "$PACMAN_HELPER" "package1" "package2"
```

This respects user's choice (yay/paru) and handles both official and AUR packages transparently.

## Code Patterns to Follow

### Error handling in modules
```bash
#!/bin/bash
set -euo pipefail  # At top of file

if ! some_command; then
    log_error "Failed to do something"
    return 1
fi
```

### Conditional logging with DEBUG flag
```bash
DEBUG=1 ./install.sh  # To see debug output
# Inside code:
log_debug "Detailed info"  # Only shown if DEBUG=1
```

### Handling paths with SCRIPT_DIR
Always use `$SCRIPT_DIR` to reference files relative to repo root:
```bash
local wm_folder="${SCRIPT_DIR}/packages/wm"
local config_dir="${SCRIPT_DIR}/dotfiles/config/i3"
```

## Testing & Validation

There is no automated test suite. Validation is manual:

- **Test new packages**: Run `./install.sh`, select the new package, verify installation
- **Test detection**: After installing a WM, run `install.sh` and check that detection marks it as "✓ INSTALLED"
- **Test on fresh system**: Use a VM with clean Arch installation
- **Verify configs**: Check that `~/.config/wm/` files are synced correctly after installation

## Important Files to Know

- `install.sh` - Main entry point, orchestrates all steps
- `modules/helpers.sh` - User selection, menu display, package helper setup (most modified for UI changes)
- `modules/packages.sh` - Package loading and installation logic
- `packages/wm/` - Window manager definitions (both `.txt` and `.sh`)
- `packages/program/` - Optional program categories
- `dotfiles/` - Configuration templates synced to user home

## Documentation References

- **Contributing guide** (CONTRIBUTING.md): How to add packages, code style requirements
- **README** (README.md): User-facing installation flow, troubleshooting

For questions on contributor expectations, see CONTRIBUTING.md.
