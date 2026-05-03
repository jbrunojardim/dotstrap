#!/usr/bin/env bash
# =============================================================================
# vscode.sh
# Instalação do Visual Studio Code
# Arch Linux: visual-studio-code-bin via makepkg (AUR)
# Fedora/RHEL: tarball oficial da Microsoft via curl
# Debian/Ubuntu: tarball oficial da Microsoft via curl
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
# Arch — visual-studio-code-bin via makepkg
# -----------------------------------------------------------------------------
install_vscode_pacman() {
  if command -v code &>/dev/null; then
    log "VS Code já instalado: $(code --version | head -1)"
    exit 0
  fi

  if [[ $EUID -eq 0 ]]; then
    error "makepkg não pode ser executado como root. Execute o script como usuário normal."
    exit 1
  fi

  log "Instalando dependências de build..."
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

# -----------------------------------------------------------------------------
# Fedora / apt — tarball oficial da Microsoft via curl
# -----------------------------------------------------------------------------
install_binaries_curl() {
  mkdir -p "$HOME/.local/lib/vscode"

  log "Baixando VS Code mais recente..."
  curl -fsSL "https://update.code.visualstudio.com/latest/linux-x64/stable" \
    | tar -xz -C "$HOME/.local/lib/vscode" --strip-components=1

  log "Versão instalada: $("$HOME/.local/lib/vscode/code" --version | head -1)"
}

install_launcher() {
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

  cat > "$HOME/.local/bin/code" << 'EOF'
#!/usr/bin/env bash
exec "$HOME/.local/lib/vscode/code" "$@"
EOF
  sed -i "s|\$HOME|$HOME|g" "$HOME/.local/bin/code"
  chmod +x "$HOME/.local/bin/code"

  cat > "$HOME/.local/share/applications/vscode.desktop" << EOF
[Desktop Entry]
Name=Visual Studio Code
Exec=$HOME/.local/bin/code %F
Icon=$HOME/.local/lib/vscode/resources/app/resources/linux/code.png
Type=Application
Categories=Development;TextEditor;
MimeType=text/plain;application/x-shellscript;
StartupNotify=true
EOF
}

install_flags() {
  local flags_file="$HOME/.config/code-flags.conf"
  mkdir -p "$HOME/.config"

  if [[ -f "$flags_file" ]]; then
    log "code-flags.conf já existe, pulando..."
    return
  fi

  cat > "$flags_file" << 'EOF'
--password-store=gnome-libsecret
EOF

  log "code-flags.conf criado em ~/.config/code-flags.conf"
}

install_vscode_curl() {
  if [[ -f "$HOME/.local/lib/vscode/code" ]]; then
    log "VS Code já instalado, pulando..."
    log "Para atualizar, execute: bash vscode.sh --update"
    exit 0
  fi

  install_binaries_curl
  install_launcher
  install_flags

  log "VS Code instalado em ~/.local/lib/vscode"
}

update_vscode_curl() {
  if [[ ! -f "$HOME/.local/lib/vscode/code" ]]; then
    error "VS Code não está instalado. Execute o script sem --update primeiro."
    exit 1
  fi

  local versao_atual
  versao_atual=$("$HOME/.local/lib/vscode/code" --version | head -1)
  log "Versão atual: $versao_atual"

  log "Removendo binários antigos..."
  rm -rf "$HOME/.local/lib/vscode"

  install_binaries_curl

  log "Atualização concluída."
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  local update=false
  [[ "${1:-}" == "--update" ]] && update=true

  section "VS Code"

  local pkg_manager
  pkg_manager=$(detect_pkg_manager)

  if [[ "$pkg_manager" == "unsupported" ]]; then
    error "Gestor de pacotes não identificado."
    error "Este script suporta: dnf (Fedora/RHEL), pacman (Arch), apt (Debian/Ubuntu)."
    exit 1
  fi

  log "Gestor de pacotes detectado: ${CYAN}${pkg_manager}${NC}"

  if [[ "$pkg_manager" == "pacman" ]]; then
    install_vscode_pacman
  else
    if $update; then
      section "Atualização do VS Code"
      update_vscode_curl
    else
      section "Instalação do VS Code"
      install_vscode_curl
    fi
  fi

  log "VS Code instalado: $(code --version 2>/dev/null | head -1 || echo 'verifique manualmente')"
}

main "$@"
