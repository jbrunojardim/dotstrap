#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

KEY_PATH="${HOME}/.ssh/github-dotfiles"
SSH_CONFIG="${HOME}/.ssh/config"
HOST_ALIAS="github.com"

log "Garantindo pasta ~/.ssh e permissões"
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

log "Gerando chave SSH (se não existir)"
if [[ -f "${KEY_PATH}" ]]; then
  log "Chave já existe: ${KEY_PATH}"
else
  ssh-keygen -t ed25519 -f "${KEY_PATH}" -C "dotfiles" -N ""
  chmod 600 "${KEY_PATH}"
  chmod 644 "${KEY_PATH}.pub"
fi

log "Criando configuração SSH para ${HOST_ALIAS}"

touch "${SSH_CONFIG}"
chmod 600 "${SSH_CONFIG}"

if ! grep -q "Host ${HOST_ALIAS}" "${SSH_CONFIG}"; then
cat >> "${SSH_CONFIG}" <<EOF

Host ${HOST_ALIAS}
  HostName github.com
  User git
  IdentityFile ${KEY_PATH}
  IdentitiesOnly yes
EOF
  log "Bloco SSH adicionado"
else
  log "Bloco já existe — não alterado"
fi

log "=== CHAVE PUBLICA ==="
cat "${KEY_PATH}.pub"

log "Adicione essa chave no GitHub:"
log "Settings → SSH Keys → New SSH Key"

log "Depois teste:"
echo "ssh -T ${HOST_ALIAS}"
