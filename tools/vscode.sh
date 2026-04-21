#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

if command -v code &>/dev/null; then
  log "VS Code já instalado: $(code --version | head -1)"
  exit 0
fi

log "Adicionando repositório oficial do VS Code"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
  sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
else
  log "Repositório vscode.repo já existe, pulando"
fi

log "Instalando VS Code"
sudo dnf install -y code

log "VS Code instalado: $(code --version | head -1)"
