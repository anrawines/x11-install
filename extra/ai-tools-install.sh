#!/bin/bash
# ============================================================
#  Terminal Tools Installer (AI & Git)
#  Allows choosing and installing various CLI programs.
#  Run with: bash ai-tools-install.sh
# ============================================================

set -e

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info() { echo -e "${CYAN}[•]${RESET} $1"; }
success() { echo -e "${GREEN}[✓]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
error() {
  echo -e "${RED}[✗]${RESET} $1"
  exit 1
}
header() { echo -e "\n${BOLD}$1${RESET}"; }

# ── Must NOT run as root ─────────────────────────────────────
[[ "$EUID" -eq 0 ]] && error "Don't run as root. The script will call sudo when needed."

# ── Dependency Check ──────────────────────────────────────────
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    warn "$1 is missing. Attempting to install $1 via pacman..."
    sudo pacman -S "$1" --noconfirm || error "Failed to install $1. Please install it manually."
  fi
}

# ── Add local bin to PATH for detection ──────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Status Check ─────────────────────────────────────────────
is_installed() {
  local bin=$1
  if [[ "$bin" == "gh-copilot" ]]; then
    # Check for gh extension, or standalone binaries
    if command -v gh &>/dev/null && gh extension list | grep -q "github/gh-copilot"; then return 0; fi
    if command -v copilot &>/dev/null; then return 0; fi
    if command -v github-copilot-cli &>/dev/null; then return 0; fi
    return 1
  fi

  if command -v "$bin" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

get_status_label() {
  if is_installed "$1"; then
    echo -e "${GREEN}[Installed]${RESET}"
  else
    echo -e "${YELLOW}[Not Installed]${RESET}"
  fi
}

# ── Installation Helper ──────────────────────────────────────
install_tool() {
  local name=$1
  local bin=$2
  local desc=$3
  local link=$4
  local cmd=$5

  header "Setup: $name"

  if is_installed "$bin"; then
    success "$name is already installed at $(command -v "$bin")"
    read -rp "  Do you want to reinstall/update it? [y/N]: " choice
    [[ ! "$choice" =~ ^[yY]$ ]] && return
  fi

  echo -e "${BOLD}Description:${RESET} $desc"
  echo -e "${BOLD}Setup Info: ${RESET} ${CYAN}$link${RESET}"
  echo ""

  # Pre-checks for common package managers
  if [[ "$cmd" == *"npm"* ]]; then check_dep "npm"; fi
  if [[ "$cmd" == *"pip"* ]]; then check_dep "python-pip"; fi
  if [[ "$cmd" == *"curl"* ]]; then check_dep "curl"; fi

  info "Executing installation command..."
  echo -e "  ${CYAN}$cmd${RESET}\n"

  if eval "$cmd"; then
    success "$name installed successfully!"
    echo -e "\nFollow setup instructions at: ${CYAN}$link${RESET}"
  else
    warn "Installation of $name might have failed or was cancelled."
  fi
  echo ""
  read -rp "Press Enter to return to menu..."
}

# ── Uninstallation Helpers ────────────────────────────────────
uninstall_tool() {
  local name=$1
  local bin=$2
  local cmd=$3

  header "Uninstall: $name"

  if ! is_installed "$bin"; then
    warn "$name is not installed."
    read -rp "Press Enter to return..."
    return
  fi

  read -rp "  Are you sure you want to uninstall $name? [y/N]: " choice
  [[ ! "$choice" =~ ^[yY]$ ]] && return

  info "Executing uninstallation command..."
  echo -e "  ${CYAN}$cmd${RESET}\n"

  if eval "$cmd"; then
    success "$name uninstalled successfully!"
  else
    warn "Uninstallation of $name might have failed."
  fi
  echo ""
  read -rp "Press Enter to return..."
}

uninstall_menu() {
  while true; do
    clear
    echo -e "${BOLD}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║      Uninstall Tools                    ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${RESET}"

    echo -e "  ${BOLD}1)${RESET} OpenCode"
    echo -e "  ${BOLD}2)${RESET} Aider"
    echo -e "  ${BOLD}3)${RESET} Crush"
    echo -e "  ${BOLD}4)${RESET} Copilot CLI"
    echo -e "  ${BOLD}5)${RESET} Pi"
    echo -e "  ${BOLD}6)${RESET} Ollama"
    echo -e "  ${BOLD}7)${RESET} Hermes Agent"
    echo -e "  ${BOLD}8)${RESET} Antigravity CLI"
    echo -e "  ${BOLD}9)${RESET} GitHub CLI"
    echo -e "  ${BOLD}10)${RESET} Lazygit"
    echo -e "  ${BOLD}11)${RESET} Oh My Pi"
    echo ""
    echo -e "  ${BOLD}r)${RESET} Return to main menu"
    read -rp "Select tool to uninstall [1-11, r]: " u_choice

    case $u_choice in
    1) uninstall_tool "OpenCode" "opencode" "sudo pacman -Rs opencode --noconfirm 2>/dev/null || rm -f ~/.local/bin/opencode" ;;
    2) uninstall_tool "Aider" "aider" "pip uninstall aider-chat --break-system-packages -y" ;;
    3)
      if command -v yay &>/dev/null; then
        CMD="yay -Rs crush-bin --noconfirm"
      elif command -v paru &>/dev/null; then
        CMD="paru -Rs crush-bin --noconfirm"
      else CMD="sudo npm uninstall -g @charmland/crush"; fi
      uninstall_tool "Crush" "crush" "$CMD"
      ;;
    4) uninstall_tool "GitHub Copilot CLI" "gh-copilot" "gh extension remove github/gh-copilot" ;;
    5) uninstall_tool "Pi" "pi" "rm -f ~/.local/bin/pi" ;;
    6) uninstall_tool "Ollama" "ollama" "sudo systemctl stop ollama && sudo systemctl disable ollama && sudo rm /usr/local/bin/ollama" ;;
    7) uninstall_tool "Hermes Agent" "hermes" "rm -rf ~/.hermes && rm -f ~/.local/bin/hermes" ;;
    8) uninstall_tool "Antigravity CLI" "agy" "rm -f ~/.local/bin/agy" ;;
    9) uninstall_tool "GitHub CLI" "gh" "sudo pacman -Rs github-cli --noconfirm 2>/dev/null || sudo npm uninstall -g gh" ;;
    10) uninstall_tool "Lazygit" "lazygit" "sudo pacman -Rs lazygit --noconfirm" ;;
    11) uninstall_tool "Oh My Pi" "omp" "rm -f ~/.local/bin/omp" ;;
    r | R) break ;;
    *)
      warn "Invalid option"
      sleep 1
      ;;
    esac
  done
}

# ── Main Menu ────────────────────────────────────────────────
while true; do
  clear
  echo -e "${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║      Terminal Tools Installer            ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${RESET}"

  echo -e "${BOLD}── AI Terminal Tools ──────────────────────────${RESET}"
  echo -e "  ${BOLD}1)${RESET} $(get_status_label "opencode") OpenCode             - Open-source AI coding agent (TUI)"
  echo -e "  ${BOLD}2)${RESET} $(get_status_label "aider") Aider            - Professional AI pair programming"
  echo -e "  ${BOLD}3)${RESET} $(get_status_label "crush") Crush                - Polished AI agent by Charm"
  echo -e "  ${BOLD}4)${RESET} $(get_status_label "gh-copilot") Copilot CLI          - GitHub Copilot in your terminal"
  echo -e "  ${BOLD}5)${RESET} $(get_status_label "pi") Pi                   - Pi is a minimal terminal coding harness."
  echo -e "  ${BOLD}6)${RESET} $(get_status_label "ollama") Ollama           - Run LLMs locally (Recommended)"
  echo -e "  ${BOLD}7)${RESET} $(get_status_label "hermes") Hermes Agent       - AI coding assistant by Nous Research"
  echo -e "  ${BOLD}8)${RESET} $(get_status_label "agy") Antigravity CLI    - AI coding agent with rich terminal interface"
  echo -e "  ${BOLD}9)${RESET} $(get_status_label "gh") GitHub CLI           - Official GitHub tool (gh)"
  echo -e "  ${BOLD}10)${RESET} $(get_status_label "lazygit") Lazygit              - Simple terminal UI for git"
  echo -e "  ${BOLD}11)${RESET} $(get_status_label "omp") Oh My Pi         - Oh My Pi coding agent (omp)"
  echo ""
  echo -e "  ${BOLD}u)${RESET} Uninstall AI Tools"
  echo -e "  ${BOLD}q)${RESET} Quit"
  echo ""
  read -rp "Selection [1-11, u, q]: " choice

  case $choice in
  1)
    if pacman -Si opencode &>/dev/null; then
      INSTALL_CMD="sudo pacman -S opencode --noconfirm"
    else
      INSTALL_CMD="curl -fsSL https://opencode.ai/install | bash"
    fi
    install_tool "OpenCode" "opencode" \
      "An open-source AI coding agent with a rich terminal interface. Supports MCP." \
      "https://opencode.ai" \
      "$INSTALL_CMD"
    ;;
  2)
    install_tool "Aider" "aider" \
      "AI pair programming in your terminal. Best for complex codebases." \
      "https://aider.chat" \
      "pip install aider-chat --break-system-packages"
    ;;
  3)
    if command -v yay &>/dev/null; then
      INSTALL_CMD="yay -S crush-bin --noconfirm"
    elif command -v paru &>/dev/null; then
      INSTALL_CMD="paru -S crush-bin --noconfirm"
    else
      INSTALL_CMD="sudo npm install -g @charmland/crush"
    fi
    install_tool "Crush" "crush" \
      "A terminal-native AI coding agent built for speed and beauty by Charm." \
      "https://github.com/charmbracelet/crush" \
      "$INSTALL_CMD"
    ;;
  4)
    # GitHub Copilot CLI is now a gh extension
    if ! is_installed "gh"; then
      warn "GitHub CLI (gh) is required for Copilot CLI."
      read -rp "Install gh first? [Y/n]: " install_gh
      if [[ ! "$install_gh" =~ ^[nN]$ ]]; then
        sudo pacman -S github-cli --noconfirm
      else
        continue
      fi
    fi
    install_tool "GitHub Copilot CLI" "gh-copilot" \
      "GitHub Copilot directly in your terminal as a gh extension." \
      "https://github.com/github/copilot-cli" \
      "gh extension install github/gh-copilot"
    ;;
  5)
    # Pi
    install_tool "Pi" "pi" \
      "Pi is a minimal terminal coding harness." \
      "curl -fsSL https://pi.dev/install.sh | sh"
    ;;
  6)
    install_tool "Ollama" "ollama" \
      "The best way to run large language models locally on your machine." \
      "https://ollama.com" \
      "curl -fsSL https://ollama.com/install.sh | sh"
    ;;
  7)
    install_tool "Hermes Agent" "hermes" \
      "Open-source AI coding assistant from Nous Research." \
      "https://hermes-agent.nousresearch.com" \
      "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
    ;;
  8)
    # Antigravity CLI
    INSTALL_CMD="curl -fsSL https://antigravity.google/cli/install.sh | bash"
    install_tool "Antigravity CLI" "agy" \
      "Antigravity AI coding agent with rich terminal interface." \
      "https://antigravity.google" \
      "$INSTALL_CMD"
    ;;
  9)
    # GitHub CLI
    install_tool "GitHub CLI" "gh" \
      "Official tool for managing repositories, PRs, and issues." \
      "https://cli.github.com" \
      "sudo pacman -S github-cli --noconfirm"
    ;;
  10)
    install_tool "Lazygit" "lazygit" \
      "A simple terminal UI for git commands, written in Go with the gocui library." \
      "https://github.com/jesseduffield/lazygit" \
      "sudo pacman -S lazygit --noconfirm"
    ;;
  11)
    # Oh My Pi (OMP)
    install_tool "Oh My Pi" "omp" \
      "A coding agent for your terminal. Installs the omp binary." \
      "https://omp.sh" \
      "curl -fsSL https://omp.sh/install | sh"
    ;;
  u | U)
    uninstall_menu
    ;;
  q | Q)
    success "Exiting. Happy coding!"
    exit 0
    ;;
  *)
    warn "Invalid option. Please choose 1-11 or q."
    sleep 1
    ;;
  esac
done
