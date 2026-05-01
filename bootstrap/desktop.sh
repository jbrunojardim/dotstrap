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
  alacritty \
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

log "Instalando Zen Browser"
ZEN_URL=$(curl -fsSL https://api.github.com/repos/zen-browser/desktop/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*linux-x86_64\.tar\.bz2"' \
  | grep -o 'https://[^"]*')
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
curl -fsSL "$ZEN_URL" | tar -xj -C "$HOME/.local/bin" --strip-components=1 zen/zen
chmod +x "$HOME/.local/bin/zen"
cat > "$HOME/.local/share/applications/zen-browser.desktop" << 'EOF'
[Desktop Entry]
Name=Zen Browser
Exec=/home/joseph/.local/bin/zen %u
Icon=zen-browser
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOF
sed -i "s|/home/joseph|$HOME|g" "$HOME/.local/share/applications/zen-browser.desktop"
log "Zen Browser instalado em ~/.local/bin/zen"

log "Ambiente desktop instalado com sucesso"
