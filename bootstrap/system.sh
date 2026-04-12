#!/usr/bin/env bash
set -euo pipefail

log() {
  local GREEN="\e[32m"
  local RESET="\e[0m"
  printf "\n${GREEN}==> %s${RESET}\n" "$*"
}

# Verificação do gerenciador de pacotes
if ! command -v dnf >/dev/null 2>&1; then
  printf "\n\e[31mERRO: O gerenciador de pacotes 'dnf' não foi encontrado. Este script suporta apenas Fedora/RHEL.\e[0m\n" >&2
  exit 1
fi

# Solicita a senha do sudo antecipadamente
sudo -v

# Mantém o cache do sudo ativo em background durante a execução do script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

PACKAGES=(
  tmux
  curl
  vim
  neovim
  git
  ncurses
  iproute
  awk
  openssh
  openssh-server
)

log "Atualizando sistema (dnf update)"
sudo dnf -y update

log "Instalando pacotes essenciais"
sudo dnf -y install "${PACKAGES[@]}"

log "Sistema preparado com sucesso"
