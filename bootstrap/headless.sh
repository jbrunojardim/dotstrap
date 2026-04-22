#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

# ─── HandleLidSwitch ──────────────────────────────────────────────────────────
log "Configurando logind para ignorar tampa fechada (headless)"
sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/lid.conf > /dev/null <<EOF
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
log "Tampa: HandleLidSwitch=ignore aplicado"

# ─── SSH Keepalive ────────────────────────────────────────────────────────────
log "Configurando SSH keepalive (evita travamento de conexões ociosas)"
SSHD_CONFIG="/etc/ssh/sshd_config"
if [[ -f "$SSHD_CONFIG" ]]; then
  sudo sed -i 's/#\?ClientAliveInterval.*/ClientAliveInterval 60/' "$SSHD_CONFIG"
  sudo sed -i 's/#\?ClientAliveCountMax.*/ClientAliveCountMax 3/' "$SSHD_CONFIG"
  sudo systemctl restart sshd
  log "SSH keepalive aplicado: ClientAliveInterval=60, ClientAliveCountMax=3"
else
  log "$SSHD_CONFIG não encontrado — pulando"
fi

# ─── Swap ─────────────────────────────────────────────────────────────────────
log "Desabilitando swap (requisito do k3s/Kubernetes)"
sudo swapoff -a

# Remove entrada de swap do /etc/fstab (swap em partição ou arquivo)
if grep -qE '\sswap\s' /etc/fstab; then
  sudo sed -i '/\sswap\s/d' /etc/fstab
  log "Entrada de swap removida do /etc/fstab"
else
  log "Nenhuma entrada de swap no /etc/fstab — pulando"
fi

# Remove arquivo de swap se existir
if [[ -f /swap.img ]]; then
  sudo rm -f /swap.img
  log "/swap.img removido"
else
  log "/swap.img não encontrado — pulando"
fi

# Remove zram-generator-defaults (swap via zram — padrão Fedora moderno)
if rpm -q zram-generator-defaults &>/dev/null; then
  sudo dnf remove -y zram-generator-defaults
  log "zram-generator-defaults removido"
else
  log "zram-generator-defaults não instalado — pulando"
fi

# ─── Cockpit ──────────────────────────────────────────────────────────────────
log "Desabilitando e removendo cockpit"
if systemctl list-unit-files cockpit.socket &>/dev/null; then
  sudo systemctl disable --now cockpit.socket
  sudo systemctl disable --now cockpit 2>/dev/null || true
  log "cockpit e cockpit.socket desabilitados"
else
  log "cockpit não encontrado como serviço — pulando"
fi

if rpm -q cockpit &>/dev/null; then
  sudo dnf remove -y 'cockpit*'
  log "Pacotes cockpit removidos"
else
  log "cockpit não instalado — pulando"
fi

# ─── firewalld ────────────────────────────────────────────────────────────────
log "Desabilitando firewalld (controle de rede delegado ao Kubernetes)"
if systemctl list-unit-files firewalld.service &>/dev/null; then
  sudo systemctl disable --now firewalld
  log "firewalld desabilitado"
else
  log "firewalld não encontrado — pulando"
fi

# ─── GRUB timeout ─────────────────────────────────────────────────────────────
log "Configurando GRUB timeout=0"
GRUB_DEFAULT="/etc/default/grub"
if [[ -f "$GRUB_DEFAULT" ]]; then
  sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$GRUB_DEFAULT"
  if sudo test -f /boot/grub2/grub.cfg; then
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  elif sudo test -f /boot/efi/EFI/fedora/grub.cfg; then
    sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
  fi
  log "GRUB_TIMEOUT=0 aplicado"
else
  log "/etc/default/grub não encontrado — pulando"
fi

# ─── Plymouth ─────────────────────────────────────────────────────────────────
log "Desabilitando Plymouth (bootloader gráfico desnecessário em servidor)"
if rpm -q plymouth &>/dev/null; then
  sudo dnf remove -y plymouth plymouth-core-libs plymouth-scripts 2>/dev/null \
    || echo "    [aviso] Alguns pacotes plymouth não encontrados, continuando..."
  log "Plymouth removido"
else
  log "Plymouth não instalado — pulando"
fi

# ─── SELinux → permissive ─────────────────────────────────────────────────────
log "Configurando SELinux para modo permissive (compatibilidade com k3d/Kubernetes)"
SELINUX_CONFIG="/etc/selinux/config"
if [[ -f "$SELINUX_CONFIG" ]]; then
  sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' "$SELINUX_CONFIG"
  sudo setenforce 0 2>/dev/null || log "setenforce 0: SELinux já em permissive ou disabled"
  log "SELinux → permissive (ativo imediatamente, persistido no próximo boot)"
else
  log "/etc/selinux/config não encontrado — pulando"
fi

# ─── Conclusão ────────────────────────────────────────────────────────────────
echo ""
log "[bootstrap_server] Configurações de servidor aplicadas com sucesso!"
echo ""
echo "    Resumo:"
echo "      - Tampa fechada:  ignorada (HandleLidSwitch=ignore)"
echo "      - Swap:           desabilitado (requisito k3s)"
echo "      - Cockpit:        desabilitado"
echo "      - firewalld:      desabilitado (controle de rede via Kubernetes)"
echo "      - GRUB timeout:   0s"
echo "      - Plymouth:       removido"
echo "      - SELinux:        permissive
      - SSH keepalive:  ClientAliveInterval=60 / ClientAliveCountMax=3"
echo ""
echo "    Recomendado: reiniciar o sistema para garantir que todas as"
echo "    configurações entrem em vigor (especialmente GRUB e tampa)."
echo ""
