#!/bin/bash

# DWM (suckless) package installer with compilation from source
# This script handles:
# - Build dependencies
# - Cloning dwm from official repository
# - Compilation with optional patches
# - Installation to system
# - Creating .xinitrc entry

packages::install() {
  local build_deps=(
    "base-devel"
    "git"
    "libx11"
    "libxinerama"
    "libxft"
    "fontconfig"
  )

  local companion_packages=(
    "picom"
    "rofi"
    "dunst"
    "dmenu"
  )

  local display_packages=(
    "xorg-server"
    "xorg-xinit"
    "xorg-xrandr"
    "xorg-xsetroot"
    "xorg-xprop"
    "xorg-xhost"
    "xorg-xbacklight"
    "xorg-xmessage"
  )

  local sound_packages=(
    "pavucontrol"
    "pulsemixer"
    "pamixer"
    "pipewire-audio"
  )

  local fonts=(
    "ttf-dejavu"
    "ttf-liberation"
    "noto-fonts"
    "ttf-nerd-fonts-symbols"
  )

  log_info "Installing build dependencies for DWM..."
  if ! helpers::run_with_helper "$PACMAN_HELPER" "${build_deps[@]}"; then
    log_error "Failed to install build dependencies"
    return 1
  fi

  log_info "Installing companion packages..."
  if ! helpers::run_with_helper "$PACMAN_HELPER" "${companion_packages[@]}"; then
    log_warn "Some companion packages failed (continuing)"
  fi

  log_info "Installing display server packages..."
  if ! helpers::run_with_helper "$PACMAN_HELPER" "${display_packages[@]}"; then
    log_warn "Some display packages failed (continuing)"
  fi

  log_info "Installing sound packages..."
  if ! helpers::run_with_helper "$PACMAN_HELPER" "${sound_packages[@]}"; then
    log_warn "Some sound packages failed (continuing)"
  fi

  log_info "Installing fonts..."
  if ! helpers::run_with_helper "$PACMAN_HELPER" "${fonts[@]}"; then
    log_warn "Some fonts failed (continuing)"
  fi

  # Build suckless tools from local configs
  log_section "Building Suckless Tools"

  local config_dir="${SCRIPT_DIR}/dotfiles/config/dwm"

  for tool in dwm slstatus st; do
    if [[ ! -d "$config_dir/$tool" ]]; then
      log_error "Config directory not found: $config_dir/$tool"
      return 1
    fi

    log_info "Building $tool..."
    cd "$config_dir/$tool" || return 1

    if ! make clean; then
      log_warn "make clean failed for $tool (continuing)"
    fi

    if ! make; then
      log_error "$tool compilation failed"
      return 1
    fi

    log_info "Installing $tool..."
    if ! sudo make install; then
      log_error "$tool installation failed"
      return 1
    fi

    log_success "$tool installed successfully"
  done

  # Create desktop entries
  log_info "Creating desktop entries..."

  sudo mkdir -p /usr/share/xsessions
  cat <<EOF | sudo tee /usr/share/xsessions/dwm.desktop >/dev/null
[Desktop Entry]
Name=dwm
Comment=Dynamic window manager
Exec=dwm
Type=XSession
EOF

  mkdir -p ~/.local/share/applications
  cat >~/.local/share/applications/st.desktop <<EOF
[Desktop Entry]
Name=st
Comment=Simple Terminal
Exec=st
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
EOF

  log_success "Desktop entries created"

  return 0
}

packages::check() {
  local missing=()

  log_info "Verifying DWM installation..."

  # Check if main tools are installed
  for tool in dwm st slstatus; do
    if ! command -v "$tool" &>/dev/null; then
      missing+=("$tool")
    fi
  done

  # Check for desktop entries
  if [[ ! -f /usr/share/xsessions/dwm.desktop ]]; then
    missing+=("dwm.desktop")
  fi

  if [[ ! -f ~/.local/share/applications/st.desktop ]]; then
    missing+=("st.desktop")
  fi

  if [[ ${#missing[@]} -eq 0 ]]; then
    log_success "DWM installation verified: all components present"
    return 0
  else
    log_warn "DWM installation incomplete, missing: ${missing[*]}"
    return 1
  fi
}
