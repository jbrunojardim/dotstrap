#!/usr/bin/env bash
# =============================================================================
# vscode-update.sh
# Atualização do Visual Studio Code via makepkg (AUR)
# Exclusivo para Arch Linux
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
# Validações
# -----------------------------------------------------------------------------
if ! command -v pacman &>/dev/null; then
  error "Este script é exclusivo para Arch Linux."
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  error "makepkg não pode ser executado como root. Execute o script como usuário normal."
  exit 1
fi

if ! command -v code &>/dev/null; then
  error "VS Code não está instalado. Execute o vscode.sh primeiro."
  exit 1
fi

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  section "Atualização do VS Code (Arch)"

  local versao_atual
  versao_atual=$(code --version | head -1)
  log "Versão atual: $versao_atual"

  local build_dir
  build_dir=$(mktemp -d)

  log "Clonando PKGBUILD em diretório temporário: $build_dir"
  git clone https://aur.archlinux.org/visual-studio-code-bin.git "$build_dir/visual-studio-code-bin"

  cd "$build_dir/visual-studio-code-bin"
  makepkg -si --noconfirm

  log "Limpando diretório temporário..."
  cd "$HOME"
  rm -rf "$build_dir"

  local versao_nova
  versao_nova=$(code --version | head -1)

  if [[ "$versao_atual" == "$versao_nova" ]]; then
    log "VS Code já estava na versão mais recente: $versao_nova"
  else
    log "VS Code atualizado: $versao_atual → $versao_nova"
  fi

  section "Atualização concluída"
}

main "$@"
