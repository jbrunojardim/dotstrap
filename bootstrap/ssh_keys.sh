#!/usr/bin/env bash
# =============================================================================
# ssh_keys.sh
# Etapa 2 — Geração de chaves SSH para GitHub e GitLab 
#   e configuração do ~/.ssh/config
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
KEY_GITHUB="${HOME}/.ssh/github"
KEY_GITLAB="${HOME}/.ssh/gitlab"
SSH_CONFIG="${HOME}/.ssh/config"

# -----------------------------------------------------------------------------
# Geração de chaves
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
# Configuração do ~/.ssh/config
# -----------------------------------------------------------------------------
configure_ssh_config() {
  log "Verificando ~/.ssh/config..."

  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"

  # GitHub
  if grep -q "^Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    log "Host github.com já existe em ~/.ssh/config, pulando..."
  else
    log "Adicionando Host github.com em ~/.ssh/config..."
    cat >> "$SSH_CONFIG" << EOF

Host github.com
  HostName github.com
  User git
  IdentityFile ${KEY_GITHUB}
  AddKeysToAgent yes
EOF
  fi

  # GitLab
  if grep -q "^Host gitlab.com" "$SSH_CONFIG" 2>/dev/null; then
    log "Host gitlab.com já existe em ~/.ssh/config, pulando..."
  else
    log "Adicionando Host gitlab.com em ~/.ssh/config..."
    cat >> "$SSH_CONFIG" << EOF

Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ${KEY_GITLAB}
  AddKeysToAgent yes
EOF
  fi

  log "~/.ssh/config atualizado."
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  section "Etapa 2 — Chaves SSH"

  log "Garantindo pasta ~/.ssh e permissões..."
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"

  generate_key "$KEY_GITHUB" "github"
  generate_key "$KEY_GITLAB" "gitlab"

  configure_ssh_config

  section "Chaves públicas"

  echo -e "${CYAN}GitHub${NC} — adicione em: Settings → SSH Keys → New SSH Key"
  cat "${KEY_GITHUB}.pub"

  echo ""
  echo -e "${CYAN}GitLab${NC} — adicione em: Preferences → SSH Keys → Add new key"
  cat "${KEY_GITLAB}.pub"

  section "Próximos passos"

  log "1. Adicione as chaves públicas acima nos respectivos serviços"
  log "2. Teste as conexões:"
  echo "     ssh -T git@github.com"
  echo "     ssh -T git@gitlab.com"
  log "3. Execute o linkr para aplicar os dotfiles core:"
  echo "     ./linkr core"
}

main "$@"
