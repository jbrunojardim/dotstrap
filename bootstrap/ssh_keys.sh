#!/usr/bin/env bash
# =============================================================================
# ssh_keys.sh
# Etapa 2 — Geração de chaves SSH para GitHub e GitLab
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()     { echo -e "${GREEN}[bootstrap]${NC} $*"; }
error()   { echo -e "${RED}[erro]${NC}     $*" >&2; }
section() { echo -e "\n${CYAN}━━━ $* ━━━${NC}\n"; }

# -----------------------------------------------------------------------------
# Configuração das chaves
# -----------------------------------------------------------------------------
KEY_GITHUB="${HOME}/.ssh/github-dotfiles"
KEY_GITLAB="${HOME}/.ssh/gitlab"

# -----------------------------------------------------------------------------
# Função de geração
# -----------------------------------------------------------------------------
generate_key() {
  local key_path="$1"
  local comment="$2"

  if [[ -f "$key_path" ]]; then
    log "Chave já existe: $key_path"
  else
    ssh-keygen -t ed25519 -f "$key_path" -C "$comment" -N ""
    chmod 600 "$key_path"
    chmod 644 "$key_path.pub"
    log "Chave gerada: $key_path"
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  section "Etapa 2 — Chaves SSH"

  log "Garantindo pasta ~/.ssh e permissões..."
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"

  generate_key "$KEY_GITHUB" "github-dotfiles"
  generate_key "$KEY_GITLAB" "gitlab"

  section "Chaves públicas"

  echo -e "${CYAN}GitHub${NC} — adicione em: Settings → SSH Keys → New SSH Key"
  cat "${KEY_GITHUB}.pub"

  echo ""
  echo -e "${CYAN}GitLab${NC} — adicione em: Preferences → SSH Keys → Add new key"
  cat "${KEY_GITLAB}.pub"

  section "Próximos passos"

  log "1. Adicione as chaves públicas acima nos respectivos serviços"
  log "2. Aplique os dotfiles core para configurar o ~/.ssh/config:"
  echo "     ./linkr core"
  log "3. Teste as conexões:"
  echo "     ssh -T git@github.com"
  echo "     ssh -T git@gitlab.com"
}

main "$@"
