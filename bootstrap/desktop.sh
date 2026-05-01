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

if ls "$HOME/.local/share/fonts/JetBrainsMono"*.ttf &>/dev/null; then
  log "JetBrainsMono Nerd Font já instalada, pulando..."
else
  log "Instalando JetBrainsMono Nerd Font"
  mkdir -p "$HOME/.local/share/fonts"
  cd "$HOME/.local/share/fonts"
  curl -fsSL -o JetBrainsMono.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
  unzip -o JetBrainsMono.zip
  rm -f JetBrainsMono.zip
  fc-cache -fv
  cd -
fi

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

if [[ -f "$HOME/.local/lib/zen-browser/zen-bin" ]]; then
  log "Zen Browser já instalado, pulando..."
else
  log "Instalando Zen Browser"
  ZEN_URL=$(curl -fsSL https://api.github.com/repos/zen-browser/desktop/releases/latest \
    | grep -o '"browser_download_url": *"[^"]*zen\.linux-x86_64\.tar\.xz"' \
    | grep -o 'https://[^"]*')
  mkdir -p "$HOME/.local/lib/zen-browser" "$HOME/.local/bin" "$HOME/.local/share/applications"
  curl -fsSL "$ZEN_URL" | tar -xJ -C "$HOME/.local/lib/zen-browser" --strip-components=1
  cat > "$HOME/.local/bin/zen" << 'EOF'
#!/usr/bin/env bash
exec "$HOME/.local/lib/zen-browser/zen-bin" "$@"
EOF
  sed -i "s|\$HOME|$HOME|g" "$HOME/.local/bin/zen"
  chmod +x "$HOME/.local/bin/zen"
  cat > "$HOME/.local/share/applications/zen-browser.desktop" << EOF
[Desktop Entry]
Name=Zen Browser
Exec=$HOME/.local/bin/zen %u
Icon=$HOME/.local/lib/zen-browser/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOF
  log "Zen Browser instalado em ~/.local/lib/zen-browser"
fi

log "Ambiente desktop instalado com sucesso"
