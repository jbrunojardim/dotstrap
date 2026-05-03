#!/usr/bin/env bash
# =============================================================================
# fonts.sh
# Instalação de fontes do sistema
# Fedora/RHEL: JetBrainsMono Nerd Font via curl
# Arch Linux:  JetBrainsMono Nerd Font + noto-fonts + noto-fonts-emoji +
#              ttf-liberation via pacman
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
# Detecção do gestor de pacotes
# -----------------------------------------------------------------------------
detect_pkg_manager() {
  if command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  elif command -v apt &>/dev/null; then
    echo "apt"
  else
    echo "unsupported"
  fi
}

# -----------------------------------------------------------------------------
# JetBrainsMono Nerd Font via curl (Fedora / apt)
# -----------------------------------------------------------------------------
install_jetbrains_curl() {
  if ls "$HOME/.local/share/fonts/JetBrainsMono"*.ttf &>/dev/null; then
    log "JetBrainsMono Nerd Font já instalada, pulando..."
    return
  fi

  log "Instalando JetBrainsMono Nerd Font via curl..."
  mkdir -p "$HOME/.local/share/fonts"

  curl -fsSL -o "/tmp/JetBrainsMono.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip

  unzip -o /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts"
  rm -f /tmp/JetBrainsMono.zip
  fc-cache -fv

  log "JetBrainsMono Nerd Font instalada."
}

# -----------------------------------------------------------------------------
# Fontes via pacman (Arch)
# -----------------------------------------------------------------------------
install_fonts_pacman() {
  log "Instalando fontes via pacman (Arch)..."
  sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji \
    ttf-liberation

  fc-cache -fv
  log "Fontes instaladas."
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  section "Instalação de fontes"

  local pkg_manager
  pkg_manager=$(detect_pkg_manager)

  if [[ "$pkg_manager" == "unsupported" ]]; then
    error "Gestor de pacotes não identificado."
    error "Este script suporta: dnf (Fedora/RHEL), pacman (Arch), apt (Debian/Ubuntu)."
    exit 1
  fi

  log "Gestor de pacotes detectado: ${CYAN}${pkg_manager}${NC}"

  case "$pkg_manager" in
    dnf)    install_jetbrains_curl ;;
    pacman) install_fonts_pacman ;;
    apt)    install_jetbrains_curl ;;
  esac

  section "Fontes instaladas com sucesso"
}

main "$@"
