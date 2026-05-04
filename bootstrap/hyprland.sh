#!/usr/bin/env bash
# =============================================================================
# hyprland.sh
# Instalação do Hyprland e dependências do ambiente desktop
# Suporte: Fedora/RHEL (dnf) | Arch Linux (pacman)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()     { echo -e "${GREEN}[bootstrap]${NC} $*"; }
warn()    { echo -e "${YELLOW}[aviso]${NC}    $*"; }
error()   { echo -e "${RED}[erro]${NC}     $*" >&2; }
section() { echo -e "\n${CYAN}━━━ $* ━━━${NC}\n"; }

# -----------------------------------------------------------------------------
# Sudo keepalive
# -----------------------------------------------------------------------------
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# -----------------------------------------------------------------------------
# Detecção do gestor de pacotes
# -----------------------------------------------------------------------------
detect_pkg_manager() {
  if command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "unsupported"
  fi
}

# -----------------------------------------------------------------------------
# Instalação dos pacotes do ambiente desktop
# -----------------------------------------------------------------------------
install_hyprland_dnf() {
  log "Adicionando COPR solopasha/hyprland..."
  sudo dnf copr enable -y solopasha/hyprland

  log "Instalando Hyprland e dependências (Fedora)..."
  sudo dnf install -y \
    hyprland \
    hyprlock \
    hypridle \
    hyprshot \
    waybar \
    kitty \
    wofi \
    wlogout \
    swaync \
    gnome-keyring \
    xdg-desktop-portal-hyprland \
    pavucontrol \
    unzip
}

install_hyprland_pacman() {
  log "Instalando Hyprland e dependências (Arch)..."
  sudo pacman -S --needed --noconfirm \
    grim \
    slurp \
    wl-clipboard \
    hyprland \
    hyprlock \
    hypridle \
    waybar \
    kitty \
    wofi \
    swaync \
    gnome-keyring \
    xdg-desktop-portal-hyprland \
    pavucontrol \
    unzip
}

# -----------------------------------------------------------------------------
# Auto-start do Hyprland na tty1
# -----------------------------------------------------------------------------
configure_autostart() {
  log "Configurando auto-start do Hyprland na tty1..."

  if grep -q "exec start-hyprland" "$HOME/.bash_profile" 2>/dev/null; then
    log "Auto-start já presente no ~/.bash_profile, pulando..."
  else
    cat >> "$HOME/.bash_profile" << 'EOF'

# Auto-start Hyprland na tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec start-hyprland
fi
EOF
    log "Auto-start adicionado ao ~/.bash_profile"
  fi
}


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  section "Instalação do Hyprland"

  local pkg_manager
  pkg_manager=$(detect_pkg_manager)

  if [[ "$pkg_manager" == "unsupported" ]]; then
    error "Gestor de pacotes não identificado."
    error "Este script suporta: dnf (Fedora/RHEL), pacman (Arch)."
    exit 1
  fi

  log "Gestor de pacotes detectado: ${CYAN}${pkg_manager}${NC}"

  case "$pkg_manager" in
    dnf)    install_hyprland_dnf ;;
    pacman) install_hyprland_pacman ;;
  esac

  configure_autostart

  section "Hyprland instalado com sucesso"
  log "Execute a próxima etapa: bootstrap/dotfiles.sh"
}

main "$@"
