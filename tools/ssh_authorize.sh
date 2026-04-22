#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

HOSTS=(
  srvfed01
  srvlnx002
)

for HOST in "${HOSTS[@]}"; do
  KEY="${HOME}/.ssh/${HOST}"

  log "Gerando chave SSH para ${HOST} (se não existir)"
  if [[ -f "${KEY}" ]]; then
    log "Chave já existe: ${KEY}"
  else
    ssh-keygen -t ed25519 -f "${KEY}" -C "${HOST}" -N ""
    chmod 600 "${KEY}"
    chmod 644 "${KEY}.pub"
  fi

  log "Copiando chave pública para ${HOST} (senha será solicitada)"
  ssh-copy-id -i "${KEY}.pub" joseph@${HOST}

  log "Testando conexão com ${HOST}"
  ssh -o BatchMode=yes ${HOST} echo "Conexao OK"

  log "Pronto! Conexao transparente configurada para ${HOST}"
done
