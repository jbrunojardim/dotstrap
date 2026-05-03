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
# Zen Browser (distro-agnóstico — instalação em user space via GitHub Releases)
# -----------------------------------------------------------------------------
install_zen() {
  if [[ -f "$HOME/.local/lib/zen-browser/zen-bin" ]]; then
    log "Zen Browser já instalado, pulando..."
    return
  fi

  log "Instalando Zen Browser..."

  local zen_url
  zen_url=$(curl -fsSL https://api.github.com/repos/zen-browser/desktop/releases/latest \
    | grep -o '"browser_download_url": *"[^"]*zen\.linux-x86_64\.tar\.xz"' \
    | grep -o 'https://[^"]*')

  if [[ -z "$zen_url" ]]; then
    error "Não foi possível obter a URL de download do Zen Browser."
    error "Verifique sua conexão ou acesse: https://github.com/zen-browser/desktop/releases"
    return 1
  fi

  mkdir -p "$HOME/.local/lib/zen-browser" \
           "$HOME/.local/bin" \
           "$HOME/.local/share/applications"

  curl -fsSL "$zen_url" | tar -xJ -C "$HOME/.local/lib/zen-browser" --strip-components=1

  cat > "$HOME/.local/bin/zen" << 'EOF'
#!/usr/bin/env bash
exec "$HOME/.local/lib/zen-browser/zen-bin" "$@"
EOF
  sed -i "s|\$HOME|$HOME|g" "$HOME/.local/bin/zen"
  chmod +x "$HOME/.local/bin/zen"

  cat > "$HOME/.local/share/applications/zen-browser.desktop" << EOF
[Desktop Entry]
Name=Zen Browser
Exec=$HOME/.local/bin/zen %u
Icon=$HOME/.local/lib/zen-browser/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOF

  log "Zen Browser instalado em ~/.local/lib/zen-browser"
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
  install_zen

  section "Etapa 1 concluída"
  log "Sistema pronto. Execute o próximo passo: bootstrap_ssh.sh"
}

main "$@"
