#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

KEY_GITHUB="${HOME}/.ssh/github-dotfiles"
KEY_GITLAB="${HOME}/.ssh/gitlab"

log "Garantindo pasta ~/.ssh e permissões"
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

log "Gerando chave SSH para GitHub (se não existir)"
if [[ -f "${KEY_GITHUB}" ]]; then
  log "Chave já existe: ${KEY_GITHUB}"
else
  ssh-keygen -t ed25519 -f "${KEY_GITHUB}" -C "dotfiles" -N ""
  chmod 600 "${KEY_GITHUB}"
  chmod 644 "${KEY_GITHUB}.pub"
fi

log "Gerando chave SSH para GitLab (se não existir)"
if [[ -f "${KEY_GITLAB}" ]]; then
  log "Chave já existe: ${KEY_GITLAB}"
else
  ssh-keygen -t ed25519 -f "${KEY_GITLAB}" -C "gitlab" -N ""
  chmod 600 "${KEY_GITLAB}"
  chmod 644 "${KEY_GITLAB}.pub"
fi

log "=== CHAVE PUBLICA — GitHub ==="
cat "${KEY_GITHUB}.pub"
log "Adicione no GitHub: Settings → SSH Keys → New SSH Key"

log "=== CHAVE PUBLICA — GitLab ==="
cat "${KEY_GITLAB}.pub"
log "Adicione no GitLab: Preferences → SSH Keys → Add new key"

log "Depois de adicionar as chaves, execute o linkr para aplicar o ~/.ssh/config:"
echo "  ./linkr core"
echo ""
log "E teste as conexões:"
echo "  ssh -T git@github.com"
echo "  ssh -T git@gitlab.com"
