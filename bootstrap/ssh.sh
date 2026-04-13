#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

KEY_GITHUB="${HOME}/.ssh/github-dotfiles"
KEY_GITLAB="${HOME}/.ssh/gitlab"
SSH_CONFIG="${HOME}/.ssh/config"

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

touch "${SSH_CONFIG}"
chmod 600 "${SSH_CONFIG}"

log "Criando configuração SSH para github.com"
if ! grep -q "Host github.com" "${SSH_CONFIG}"; then
cat >> "${SSH_CONFIG}" <<EOF

Host github.com
  HostName github.com
  User git
  IdentityFile ${KEY_GITHUB}
  IdentitiesOnly yes
EOF
  log "Bloco github.com adicionado"
else
  log "Bloco github.com já existe — não alterado"
fi

log "Criando configuração SSH para gitlab.com"
if ! grep -q "Host gitlab.com" "${SSH_CONFIG}"; then
cat >> "${SSH_CONFIG}" <<EOF

Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ${KEY_GITLAB}
  IdentitiesOnly yes
EOF
  log "Bloco gitlab.com adicionado"
else
  log "Bloco gitlab.com já existe — não alterado"
fi

log "=== CHAVE PUBLICA — GitHub ==="
cat "${KEY_GITHUB}.pub"
log "Adicione no GitHub: Settings → SSH Keys → New SSH Key"

log "=== CHAVE PUBLICA — GitLab ==="
cat "${KEY_GITLAB}.pub"
log "Adicione no GitLab: Preferences → SSH Keys → Add new key"

log "Depois teste:"
echo "ssh -T github.com"
echo "ssh -T gitlab.com"
