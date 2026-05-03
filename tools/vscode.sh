#!/usr/bin/env bash
# =============================================================================
# vscode.sh
# Instalação do Visual Studio Code (Microsoft)
# Suporte: Fedora/RHEL (dnf) | Arch Linux (pacman + makepkg) | Debian/Ubuntu (apt)
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
# Verificação — já instalado?
# -----------------------------------------------------------------------------
if command -v code &>/dev/null; then
  log "VS Code já instalado: $(code --version | head -1)"
  exit 0
fi

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
# Instalação por distro
# -----------------------------------------------------------------------------
install_vscode_dnf() {
  log "Adicionando repositório oficial do VS Code (Fedora/RHEL)..."
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

  if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  else
    log "Repositório vscode.repo já existe, pulando..."
  fi

  log "Instalando VS Code via dnf..."
  sudo dnf install -y code
}

install_vscode_pacman() {
  log "Instalando VS Code via makepkg (Arch)..."

  if [[ $EUID -eq 0 ]]; then
    error "makepkg não pode ser executado como root. Execute o script como usuário normal."
    exit 1
  fi

  sudo pacman -S --needed --noconfirm base-devel git

  local build_dir
  build_dir=$(mktemp -d)

  log "Clonando PKGBUILD em diretório temporário: $build_dir"
  git clone https://aur.archlinux.org/visual-studio-code-bin.git "$build_dir/visual-studio-code-bin"

  cd "$build_dir/visual-studio-code-bin"
  makepkg -si --noconfirm

  log "Limpando diretório temporário..."
  cd "$HOME"
  rm -rf "$build_dir"

  log "Diretório temporário removido."
}

install_vscode_apt() {
  log "Adicionando repositório oficial do VS Code (Debian/Ubuntu)..."
  sudo apt install -y wget gpg

  wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null

  echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

  log "Instalando VS Code via apt..."
  sudo apt update
  sudo apt install -y code
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  section "Instalação do VS Code"

  local pkg_manager
  pkg_manager=$(detect_pkg_manager)

  if [[ "$pkg_manager" == "unsupported" ]]; then
    error "Gestor de pacotes não identificado."
    error "Este script suporta: dnf (Fedora/RHEL), pacman (Arch), apt (Debian/Ubuntu)."
    exit 1
  fi

  log "Gestor de pacotes detectado: ${CYAN}${pkg_manager}${NC}"

  case "$pkg_manager" in
    dnf)    install_vscode_dnf ;;
    pacman) install_vscode_pacman ;;
    apt)    install_vscode_apt ;;
  esac

  log "VS Code instalado: $(code --version | head -1)"
}

main "$@"
