#!/usr/bin/env bash
# =============================================================================
# zen-browser.sh
# Instalação do Zen Browser via release oficial do GitHub
# Distro-agnóstico — instalação em user space (~/.local)
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
# Main
# -----------------------------------------------------------------------------
main() {
  section "Instalação do Zen Browser"

  if [[ -f "$HOME/.local/lib/zen-browser/zen-bin" ]]; then
    log "Zen Browser já instalado, pulando..."
    exit 0
  fi

  log "Obtendo URL do release mais recente..."
  local zen_url
  zen_url=$(curl -fsSL https://api.github.com/repos/zen-browser/desktop/releases/latest \
    | grep -o '"browser_download_url": *"[^"]*zen\.linux-x86_64\.tar\.xz"' \
    | grep -o 'https://[^"]*')

  if [[ -z "$zen_url" ]]; then
    error "Não foi possível obter a URL de download do Zen Browser."
    error "Verifique sua conexão ou acesse: https://github.com/zen-browser/desktop/releases"
    exit 1
  fi

  log "Instalando Zen Browser..."
  mkdir -p "$HOME/.local/lib/zen-browser" \
           "$HOME/.local/bin" \
           "$HOME/.local/share/applications"

  curl -fsSL "$zen_url" | tar -xJ -C "$HOME/.local/lib/zen-browser" --strip-components=1

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

  section "Zen Browser instalado com sucesso"
  log "Binário em: ~/.local/lib/zen-browser"
  log "Launcher em: ~/.local/bin/zen"
}

main "$@"
