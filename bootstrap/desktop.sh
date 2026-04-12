#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

log "Adicionando COPR solopasha/hyprland"
sudo dnf copr enable -y solopasha/hyprland

log "Instalando Hyprland e dependências do ambiente desktop"
sudo dnf install -y \
  hyprland \
  hyprlock \
  hypridle \
  hyprshot \
  waybar \
  kitty \
  wofi \
  swaync \
  unzip

log "Instalando JetBrainsMono Nerd Font"
mkdir -p "$HOME/.local/share/fonts"
cd "$HOME/.local/share/fonts"
curl -fsSL -o JetBrainsMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
unzip -o JetBrainsMono.zip
fc-cache -fv
cd -

log "Configurando auto-start do Hyprland na tty1"
if ! grep -q "exec Hyprland" "$HOME/.bash_profile"; then
  cat >> "$HOME/.bash_profile" << 'EOF'

# Auto-start Hyprland na tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
EOF
  log "Auto-start adicionado ao ~/.bash_profile"
else
  log "Auto-start já presente no ~/.bash_profile, pulando..."
fi

log "Ambiente desktop instalado com sucesso"
