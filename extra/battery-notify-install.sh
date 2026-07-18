#!/bin/bash
# ============================================================
#  Battery Notification Installer for Arch Linux (minimal)
#  Run with: bash battery-notify-install.sh
# ============================================================

set -e

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[•]${RESET} $1"; }
success() { echo -e "${GREEN}[✓]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $1"; }
error()   { echo -e "${RED}[✗]${RESET} $1"; exit 1; }
header()  { echo -e "\n${BOLD}$1${RESET}"; }

# ── Must NOT run as root ─────────────────────────────────────
[[ "$EUID" -eq 0 ]] && error "Don't run as root. The script will call sudo when needed."

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   Battery Notification Setup — Arch      ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# ── Mode selection ───────────────────────────────────────────
MODE="${1:-}"
if [[ -z "$MODE" ]]; then
    echo -e "  What would you like to do?\n"
    echo -e "  ${BOLD}1)${RESET} Install"
    echo -e "  ${BOLD}2)${RESET} Uninstall"
    echo ""
    read -rp "  Enter choice [1/2]: " MODE_INPUT
    case "$MODE_INPUT" in
        1) MODE="install" ;;
        2) MODE="uninstall" ;;
        *) error "Invalid choice. Run with 'install' or 'uninstall'." ;;
    esac
elif [[ "$MODE" == "--uninstall" || "$MODE" == "uninstall" ]]; then
    MODE="uninstall"
else
    MODE="install"
fi

# ════════════════════════════════════════════════════════════
#  UNINSTALL
# ════════════════════════════════════════════════════════════
if [[ "$MODE" == "uninstall" ]]; then
    header "Uninstalling battery notifications..."

    # Detect which daemon was installed
    if pacman -Qi mako &>/dev/null; then
        DAEMON_BIN="mako"
        DAEMON_PKG="mako"
    else
        DAEMON_BIN="dunst"
        DAEMON_PKG="dunst"
    fi

    # Stop and disable systemd timer
    if systemctl is-active --quiet battery-check.timer 2>/dev/null; then
        sudo systemctl stop battery-check.timer
        success "Stopped battery-check.timer"
    fi
    if systemctl is-enabled --quiet battery-check.timer 2>/dev/null; then
        sudo systemctl disable battery-check.timer
        success "Disabled battery-check.timer"
    fi

    # Remove systemd units
    for f in /etc/systemd/system/battery-check.timer /etc/systemd/system/battery-check.service; do
        if [[ -f "$f" ]]; then
            sudo rm -f "$f"
            success "Removed $f"
        fi
    done
    sudo systemctl daemon-reload

    # Remove udev rule
    if [[ -f /etc/udev/rules.d/99-battery-notify.rules ]]; then
        sudo rm -f /etc/udev/rules.d/99-battery-notify.rules
        sudo udevadm control --reload-rules
        success "Removed udev rule"
    fi

    # Remove battery script
    if [[ -f /usr/local/bin/battery-notify.sh ]]; then
        sudo rm -f /usr/local/bin/battery-notify.sh
        success "Removed /usr/local/bin/battery-notify.sh"
    fi

    # Remove state file
    rm -f /tmp/battery-notify-state
    success "Removed state file"

    # Remove autostart entry
    AUTOSTART_FILE="$HOME/.config/autostart/${DAEMON_BIN}.desktop"
    if [[ -f "$AUTOSTART_FILE" ]]; then
        rm -f "$AUTOSTART_FILE"
        success "Removed autostart entry"
    fi

    # Remove from .xinitrc
    XINITRC="$HOME/.xinitrc"
    if [[ -f "$XINITRC" ]] && grep -q "dunst" "$XINITRC"; then
        sed -i '/dunst \&/d' "$XINITRC"
        success "Removed dunst from ~/.xinitrc"
    fi

    # Kill running daemon
    if pgrep -x "$DAEMON_BIN" > /dev/null; then
        pkill -x "$DAEMON_BIN" && success "Stopped $DAEMON_BIN"
    fi

    # Ask about removing packages
    echo ""
    read -rp "  Remove packages (libnotify + $DAEMON_PKG) too? [y/N]: " RM_PKGS
    if [[ "$RM_PKGS" =~ ^[Yy]$ ]]; then
        sudo pacman -Rns --noconfirm libnotify "$DAEMON_PKG" 2>/dev/null \
            && success "Packages removed" \
            || warn "Could not remove packages (may be used by other apps)"
    else
        info "Packages kept"
    fi

    echo ""
    echo -e "${BOLD}${GREEN}Uninstall complete!${RESET} All battery notification files removed."
    echo ""
    exit 0
fi

# ════════════════════════════════════════════════════════════
#  INSTALL
# ════════════════════════════════════════════════════════════

# ── Detect display server ────────────────────────────────────
header "Detecting environment..."
if [[ -n "$WAYLAND_DISPLAY" ]] || [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    DISPLAY_SERVER="wayland"
    DAEMON_PKG="mako"
    DAEMON_BIN="mako"
    info "Wayland detected → will install mako"
elif [[ -n "$DISPLAY" ]] || [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
    DISPLAY_SERVER="x11"
    DAEMON_PKG="dunst"
    DAEMON_BIN="dunst"
    info "X11 detected → will install dunst"
else
    DISPLAY_SERVER="x11"
    DAEMON_PKG="dunst"
    DAEMON_BIN="dunst"
    warn "Could not detect display server — defaulting to X11/dunst"
fi

# ── Detect battery path ──────────────────────────────────────
BATTERY_PATH=""
for bat in /sys/class/power_supply/BAT{0,1,2}; do
    if [[ -f "$bat/capacity" ]]; then
        BATTERY_PATH="$bat"
        break
    fi
done
[[ -z "$BATTERY_PATH" ]] && error "No battery found in /sys/class/power_supply/. Is this a laptop?"
success "Battery found: $BATTERY_PATH"

# ── Get current user info ────────────────────────────────────
CURRENT_USER="$USER"
USER_UID=$(id -u)
info "Installing for user: $CURRENT_USER (UID $USER_UID)"

# ── Install packages ─────────────────────────────────────────
header "Installing packages..."
PKGS=("libnotify" "$DAEMON_PKG" "sound-theme-freedesktop" "libpulse")
MISSING=()
for pkg in "${PKGS[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        MISSING+=("$pkg")
    else
        success "$pkg already installed"
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    info "Installing: ${MISSING[*]}"
    sudo pacman -S --noconfirm "${MISSING[@]}" || error "pacman install failed"
    success "Packages installed"
fi

# ── Write battery-notify.sh ──────────────────────────────────
header "Creating battery notification script..."
sudo tee /usr/local/bin/battery-notify.sh > /dev/null << SCRIPT
#!/bin/bash
# Battery notification script — auto-generated by installer

BATTERY_PATH="${BATTERY_PATH}"
CAPACITY=\$(cat "\$BATTERY_PATH/capacity" 2>/dev/null) || exit 1
STATUS=\$(cat "\$BATTERY_PATH/status" 2>/dev/null) || exit 1

SOUND_DIR="/usr/share/sounds/freedesktop/stereo"

notify() {
    sudo -u ${CURRENT_USER} DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${USER_UID}/bus" \
        XDG_RUNTIME_DIR="/run/user/${USER_UID}" \
        notify-send "\$@" 2>/dev/null || true
}

play_sound() {
    local sound="\${SOUND_DIR}/\$1.oga"
    if [[ -f "\$sound" ]]; then
        sudo -u ${CURRENT_USER} DISPLAY=:0 \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${USER_UID}/bus" \
            XDG_RUNTIME_DIR="/run/user/${USER_UID}" \
            paplay "\$sound" 2>/dev/null || true
    fi
}

# Charger plug/unplug (called by udev)
if [[ "\$1" == "plugged" ]]; then
    play_sound "power-plug"
    notify -u normal "🔌 Charger connected" "Battery at \${CAPACITY}%"
    exit 0
elif [[ "\$1" == "unplugged" ]]; then
    play_sound "power-unplug"
    notify -u normal "🔋 Charger disconnected" "Battery at \${CAPACITY}%"
    exit 0
fi

# Prevent duplicate notifications using a state file
STATE_FILE="/tmp/battery-notify-state"
PREV_STATE=\$(cat "\$STATE_FILE" 2>/dev/null || echo "none")

determine_state() {
    if [[ "\$STATUS" == "Full" ]]; then echo "full"
    elif [[ "\$CAPACITY" -le 15 ]];  then echo "critical"
    elif [[ "\$CAPACITY" -le 25 ]]; then echo "low"
    elif [[ "\$CAPACITY" -le 35 ]]; then echo "warning"
    else echo "ok"
    fi
}

CURRENT_STATE=\$(determine_state)

# Only notify when state changes (avoid spam)
if [[ "\$CURRENT_STATE" != "\$PREV_STATE" ]]; then
    case "\$CURRENT_STATE" in
        full)
            play_sound "complete"
            notify -u normal "✅ Battery full" "You can unplug the charger"
            ;;
        critical)
            play_sound "dialog-warning"
            notify -u critical "🚨 Battery critical!" "\${CAPACITY}% — plug in NOW"
            ;;
        low)
            play_sound "dialog-warning"
            notify -u critical "⚠️  Battery low" "\${CAPACITY}% remaining"
            ;;
        warning)
            play_sound "dialog-information"
            notify -u normal "🔋 Battery getting low" "\${CAPACITY}% remaining"
            ;;
        ok) : ;;
    esac
    echo "\$CURRENT_STATE" > "\$STATE_FILE"
fi
SCRIPT

sudo chmod +x /usr/local/bin/battery-notify.sh
success "Script created at /usr/local/bin/battery-notify.sh"

# ── udev rule ────────────────────────────────────────────────
header "Setting up udev rule (charger plug/unplug)..."
sudo tee /etc/udev/rules.d/99-battery-notify.rules > /dev/null << UDEV
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="/usr/local/bin/battery-notify.sh plugged"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="/usr/local/bin/battery-notify.sh unplugged"
UDEV

sudo udevadm control --reload-rules
success "udev rule created and reloaded"

# ── systemd timer ────────────────────────────────────────────
header "Setting up systemd timer (battery level polling)..."

sudo tee /etc/systemd/system/battery-check.service > /dev/null << SERVICE
[Unit]
Description=Battery level check notification

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/battery-notify.sh
SERVICE

sudo tee /etc/systemd/system/battery-check.timer > /dev/null << TIMER
[Unit]
Description=Check battery level every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target
TIMER

sudo systemctl daemon-reload
sudo systemctl enable --now battery-check.timer
success "systemd timer enabled and started"

# ── Autostart notification daemon ────────────────────────────
header "Setting up notification daemon autostart..."

AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

if [[ "$DISPLAY_SERVER" == "x11" ]]; then
    # Also add to .xinitrc if it exists
    XINITRC="$HOME/.xinitrc"
    if [[ -f "$XINITRC" ]] && ! grep -q "dunst" "$XINITRC"; then
        # Insert before the last exec line
        sed -i '/^exec /i dunst \&' "$XINITRC"
        success "Added dunst to ~/.xinitrc"
    elif [[ ! -f "$XINITRC" ]]; then
        warn "No ~/.xinitrc found — start dunst manually or add it to your WM autostart"
    else
        success "dunst already in ~/.xinitrc"
    fi
fi

# Write a .desktop autostart entry (works for most WMs with XDG autostart support)
cat > "$AUTOSTART_DIR/${DAEMON_BIN}.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=${DAEMON_BIN}
Exec=${DAEMON_BIN}
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
DESKTOP
success "Autostart entry created at $AUTOSTART_DIR/${DAEMON_BIN}.desktop"

# ── Start daemon now for immediate testing ───────────────────
header "Starting notification daemon..."
if pgrep -x "$DAEMON_BIN" > /dev/null; then
    success "$DAEMON_BIN already running"
else
    nohup $DAEMON_BIN &>/dev/null &
    disown
    sleep 1
    if pgrep -x "$DAEMON_BIN" > /dev/null; then
        success "$DAEMON_BIN started"
    else
        warn "Could not start $DAEMON_BIN — you may need to start it manually after login"
    fi
fi

# ── Test notification ────────────────────────────────────────
header "Sending test notification..."
sleep 1
notify-send "✅ Battery notifications ready!" \
    "Alerts set for: charger plug/unplug, full, low (35%), critical (25%), emergency (15%)" \
    -u normal 2>/dev/null && success "Test notification sent!" \
    || warn "notify-send failed — daemon may need a restart. Try running: $DAEMON_BIN &"

# ── Summary ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}All done!${RESET} Here's what was installed:"
echo -e "  ${CYAN}Script:${RESET}  /usr/local/bin/battery-notify.sh"
echo -e "  ${CYAN}udev:${RESET}    /etc/udev/rules.d/99-battery-notify.rules"
echo -e "  ${CYAN}Timer:${RESET}   battery-check.timer (every 60s)"
echo -e "  ${CYAN}Daemon:${RESET}  $DAEMON_BIN (autostart configured)"
echo -e "  ${CYAN}Battery:${RESET} $BATTERY_PATH"
echo ""
echo -e "  ${YELLOW}Tip:${RESET} Notifications fire when state changes (low→critical etc.)"
echo -e "       to avoid spamming you every 60 seconds."
echo ""
