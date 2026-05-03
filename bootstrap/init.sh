#!/usr/bin/env bash
# =============================================================================
# pre_bootstrap_system.sh
# Etapa 1 — Atualização do sistema e instalação de pacotes essenciais
# Suporte: Fedora/RHEL (dnf) | Arch Linux (pacman) | Debian/Ubuntu (apt)
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
# Sudo keepalive — solicita senha antecipadamente e mantém cache ativo
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
  elif command -v apt &>/dev/null; then
    echo "apt"
  else
    echo "unsupported"
  fi
}

# -----------------------------------------------------------------------------
# Mapeamento de pacotes por distro
# -----------------------------------------------------------------------------
get_packages() {
  local pkg_manager="$1"

  case "$pkg_manager" in
    dnf)
      PACKAGES=(
        vim
        neovim
        tmux
        curl
        git
        awk
        iproute
        ncurses
        openssh
        openssh-server
        ffmpeg
      )
      ;;
    pacman)
      PACKAGES=(
        vim
        neovim
        tmux
        curl
        git
        gawk
        iproute2
        ncurses
        openssh
        # openssh já inclui cliente + servidor no Arch
        ffmpeg
      )
      ;;
    apt)
      PACKAGES=(
        vim
        neovim
        tmux
        curl
        git
        gawk
        iproute2
        libncurses-dev
        openssh-client
        openssh-server
        ffmpeg
      )
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Atualização do sistema
# -----------------------------------------------------------------------------
update_system() {
  local pkg_manager="$1"
  log "Atualizando o sistema..."

  case "$pkg_manager" in
    dnf)    sudo dnf update -y ;;
    pacman) sudo pacman -Syu --noconfirm ;;
    apt)    sudo apt update && sudo apt upgrade -y ;;
  esac

  log "Sistema atualizado."
}

# -----------------------------------------------------------------------------
# Instalação dos pacotes
# -----------------------------------------------------------------------------
install_packages() {
  local pkg_manager="$1"
  log "Instalando pacotes essenciais: ${PACKAGES[*]}"

  case "$pkg_manager" in
    dnf)    sudo dnf install -y "${PACKAGES[@]}" ;;
    pacman) sudo pacman -S --needed --noconfirm "${PACKAGES[@]}" ;;
    apt)    sudo apt install -y "${PACKAGES[@]}" ;;
  esac

  log "Pacotes instalados com sucesso."
}

# -----------------------------------------------------------------------------
# Habilitar serviço SSH
# -----------------------------------------------------------------------------
enable_ssh() {
  local pkg_manager="$1"

  case "$pkg_manager" in
    dnf)
      log "Habilitando sshd (Fedora)..."
      sudo systemctl enable --now sshd
      ;;
    pacman)
      log "Habilitando sshd (Arch)..."
      sudo systemctl enable --now sshd
      ;;
    apt)
      log "Habilitando ssh (Debian/Ubuntu)..."
      sudo systemctl enable --now ssh
      ;;
  esac

  log "Serviço SSH ativo."
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  section "Etapa 1 — Sistema base"

  local pkg_manager
  pkg_manager=$(detect_pkg_manager)

  if [[ "$pkg_manager" == "unsupported" ]]; then
    error "Gestor de pacotes não identificado."
    error "Este script suporta: dnf (Fedora/RHEL), pacman (Arch), apt (Debian/Ubuntu)."
    error "Certifique-se de que um desses gestores está disponível no PATH e tente novamente."
    exit 1
  fi

  log "Gestor de pacotes detectado: ${CYAN}${pkg_manager}${NC}"

  get_packages "$pkg_manager"
  update_system "$pkg_manager"
  install_packages "$pkg_manager"
  enable_ssh "$pkg_manager"
  section "Etapa 1 concluída"
  log "Sistema pronto. Execute o próximo passo: ssh_keys.sh"
}

main "$@"
