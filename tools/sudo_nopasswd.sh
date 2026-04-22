#!/usr/bin/env bash
# sudo_nopasswd.sh
# Configura acesso sudo sem senha para o usuário atual.
# Cria /etc/sudoers.d/<usuario>_nopasswd com permissão 0440.
#
# Uso: curl -fsSL -H 'Cache-Control: no-cache' \
#        https://raw.githubusercontent.com/jbrunojardim/dotfile-bootstrap/refs/heads/joseph/tools/sudo_nopasswd.sh \
#        | sudo bash
#
# ATENÇÃO: Concede NOPASSWD:ALL ao usuário. Execute apenas em ambientes controlados.
set -euo pipefail

log() {
  local GREEN="\e[32m"
  local RESET="\e[0m"
  printf "\n${GREEN}==> %s${RESET}\n" "$*"
}

error() {
  printf "\n\e[31mERRO: %s\e[0m\n" "$*" >&2
  exit 1
}

if [ "$(id -u)" -ne 0 ]; then
  error "Este script deve ser executado com sudo."
fi

TARGET_USER="${SUDO_USER:-$USER}"

if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  error "Usuário inválido: '$TARGET_USER'. Execute com sudo a partir do usuário desejado."
fi

SUDOERS_FILE="/etc/sudoers.d/${TARGET_USER}_nopasswd"
SUDOERS_CONTENT="${TARGET_USER} ALL=(ALL:ALL) NOPASSWD:ALL"

log "Configurando sudo sem senha para: $TARGET_USER"

printf '%s\n' "$SUDOERS_CONTENT" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"

if ! visudo -cf "$SUDOERS_FILE" >/dev/null 2>&1; then
  rm -f "$SUDOERS_FILE"
  error "Arquivo sudoers inválido. Configuração revertida."
fi

log "Arquivo criado: $SUDOERS_FILE"
log "Sudo sem senha configurado com sucesso para '$TARGET_USER'"
