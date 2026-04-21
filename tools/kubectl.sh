#!/usr/bin/env bash
set -euo pipefail

log() {
  local GREEN="\e[32m"
  local RESET="\e[0m"
  printf "\n${GREEN}==> %s${RESET}\n" "$*"
}

if command -v kubectl >/dev/null 2>&1; then
  log "kubectl já instalado: $(kubectl version --client)"
  exit 0
fi

log "Instalando kubectl"
KUBECTL_VERSION="$(curl -Ls https://dl.k8s.io/release/stable.txt)"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
log "kubectl instalado: $(kubectl version --client)"
