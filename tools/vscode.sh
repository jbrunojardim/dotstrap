#!/usr/bin/env bash
# =============================================================================
# vscode.sh
# Instalação do Visual Studio Code (Microsoft) via tarball oficial
# Distro-agnóstico — instalação em user space (~/.local)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()     { echo -e "${GREEN}[bootstrap]${NC} $*"; }
warn()    { echo -e "${YELLOW}[aviso]${NC}    $*"; }
error()   { echo -e "${RED}[erro]${NC}     $*" >&2; }
section() { echo -e "\n${CYAN}━━━ $* ━━━${NC}\n"; }

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  section "Instalação do VS Code"

  if [[ -f "$HOME/.local/lib/vscode/code" ]]; then
    log "VS Code já instalado, pulando..."
    exit 0
  fi

  log "Instalando VS Code..."

  mkdir -p "$HOME/.local/lib/vscode" \
           "$HOME/.local/bin" \
           "$HOME/.local/share/applications"

  curl -fsSL "https://update.code.visualstudio.com/latest/linux-x64/stable" \
    | tar -xz -C "$HOME/.local/lib/vscode" --strip-components=1

  cat > "$HOME/.local/bin/code" << 'EOF'
#!/usr/bin/env bash
exec "$HOME/.local/lib/vscode/code" "$@"
EOF
  sed -i "s|\$HOME|$HOME|g" "$HOME/.local/bin/code"
  chmod +x "$HOME/.local/bin/code"

  cat > "$HOME/.local/share/applications/vscode.desktop" << EOF
[Desktop Entry]
Name=Visual Studio Code
Exec=$HOME/.local/bin/code %F
Icon=$HOME/.local/lib/vscode/resources/app/resources/linux/code.png
Type=Application
Categories=Development;TextEditor;
MimeType=text/plain;application/x-shellscript;
StartupNotify=true
EOF

  log "VS Code instalado em ~/.local/lib/vscode"
  log "Versão: $("$HOME/.local/lib/vscode/code" --version | head -1)"
}

main "$@"
