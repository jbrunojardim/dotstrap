#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

HOST_ALIAS="github.com"
DOTFILES_REPO="git@${HOST_ALIAS}:jbrunojardim/dotfile.git"
DOTFILES_DIR="$HOME/.dotfiles"

log "Verificando dependências"
if ! command -v git &>/dev/null; then
  printf "\n[ERRO] git não encontrado. Execute bootstrap_system.sh antes de continuar.\n" >&2
  exit 1
fi
log "git encontrado: $(command -v git) ($(git --version))"

log "Clonando/atualizando dotfiles privados"
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  log "Repo já existe: fazendo pull"
  git -C "$DOTFILES_DIR" pull --ff-only
else
  log "Repo não existe: fazendo clone"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

if [[ "${1:-}" != "issue" ]] && [[ "${1:-}" != "vscodium" ]] && [[ "${1:-}" != "vscode" ]]; then
  log "Executando linkr core"
  bash "$DOTFILES_DIR/linkr" core
fi

if [[ "${1:-}" == "desk_hypr" ]]; then
  if command -v hyprland &>/dev/null; then
    log "Hyprland detectado — aplicando dotfiles desk_hypr"
    bash "$DOTFILES_DIR/linkr" desk_hypr
  else
    printf "\n[AVISO] desk_hypr solicitado mas Hyprland não encontrado. Execute bootstrap_desktop.sh primeiro.\n" >&2
  fi
fi

if [[ "${1:-}" == "issue" ]]; then
  log "Aplicando banner de login TTY"
  bash "$DOTFILES_DIR/linkr" issue
fi

if [[ "${1:-}" == "vscodium" ]]; then
  if command -v codium &>/dev/null; then
    log "VSCodium detectado — instalando extensões"
    bash "$DOTFILES_DIR/scripts/vscodium.sh"
    log "Aplicando dotfiles vscodium"
    bash "$DOTFILES_DIR/linkr" vscodium
  else
    printf "\n[AVISO] vscodium solicitado mas VSCodium não encontrado.\n" >&2
  fi
fi

if [[ "${1:-}" == "vscode" ]]; then
  if command -v code &>/dev/null; then
    log "VS Code detectado — instalando extensões"
    bash "$DOTFILES_DIR/scripts/vscode.sh"
    log "Aplicando dotfiles vscode"
    bash "$DOTFILES_DIR/linkr" vscode
  else
    printf "\n[AVISO] vscode solicitado mas VS Code não encontrado.\n" >&2
  fi
fi

log "Dotfiles aplicados com sucesso"
