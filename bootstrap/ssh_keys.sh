#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

KEY_GITHUB="${HOME}/.ssh/github-dotfiles"
KEY_GITLAB_MS="${HOME}/.ssh/gitlab-ms"
KEY_GITLAB_GOOGLE="${HOME}/.ssh/gitlab-google"

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

log "Gerando chave SSH para GitLab MS (se não existir)"
if [[ -f "${KEY_GITLAB_MS}" ]]; then
  log "Chave já existe: ${KEY_GITLAB_MS}"
else
  ssh-keygen -t ed25519 -f "${KEY_GITLAB_MS}" -C "gitlab-ms" -N ""
  chmod 600 "${KEY_GITLAB_MS}"
  chmod 644 "${KEY_GITLAB_MS}.pub"
fi

log "Gerando chave SSH para GitLab Google (se não existir)"
if [[ -f "${KEY_GITLAB_GOOGLE}" ]]; then
  log "Chave já existe: ${KEY_GITLAB_GOOGLE}"
else
  ssh-keygen -t ed25519 -f "${KEY_GITLAB_GOOGLE}" -C "gitlab-google" -N ""
  chmod 600 "${KEY_GITLAB_GOOGLE}"
  chmod 644 "${KEY_GITLAB_GOOGLE}.pub"
fi

log "=== CHAVE PUBLICA — GitHub ==="
cat "${KEY_GITHUB}.pub"
log "Adicione no GitHub: Settings → SSH Keys → New SSH Key"

log "=== CHAVE PUBLICA — GitLab MS ==="
cat "${KEY_GITLAB_MS}.pub"
log "Adicione no GitLab (conta MS): Preferences → SSH Keys → Add new key"

log "=== CHAVE PUBLICA — GitLab Google ==="
cat "${KEY_GITLAB_GOOGLE}.pub"
log "Adicione no GitLab (conta Google): Preferences → SSH Keys → Add new key"

log "Depois de adicionar as chaves, execute o linkr para aplicar o ~/.ssh/config:"
echo "  ./linkr core"
echo ""
log "E teste as conexões:"
echo "  ssh -T git@github.com"
echo "  ssh -T git@gitlab-ms"
echo "  ssh -T git@gitlab-google"
