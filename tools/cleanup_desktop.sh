#!/bin/bash
# cleanup_desktop.sh
# Remove ambientes desktop desnecessários (i3, LightDM, XFCE, drivers Xorg não utilizados)
# e configura o systemd para iniciar sem display manager.
#
# Uso: bash cleanup_desktop.sh
#
# ATENÇÃO: Execute este script apenas em máquinas onde o Hyprland já esteja
# configurado e funcional via ~/.bash_profile (etapa bootstrap_desktop.sh concluída).

set -e

echo "==> [cleanup_desktop] Iniciando expurgo de ambientes desktop desnecessários..."

# ─── i3 ───────────────────────────────────────────────────────────────────────
echo "==> Removendo i3 e seus componentes..."
sudo dnf remove -y \
  i3 \
  i3status \
  i3status-config \
  i3lock \
  i3-config-fedora \
  python3-i3ipc \
  fedora-release-i3 \
  fedora-release-identity-i3 \
  2>/dev/null || echo "    [aviso] Alguns pacotes i3 não encontrados, continuando..."

# ─── LightDM ──────────────────────────────────────────────────────────────────
echo "==> Removendo LightDM..."
sudo dnf remove -y \
  lightdm \
  lightdm-gtk \
  lightdm-gobject \
  lightdm-gtk-greeter-settings \
  2>/dev/null || echo "    [aviso] Alguns pacotes LightDM não encontrados, continuando..."

# ─── XFCE ─────────────────────────────────────────────────────────────────────
echo "==> Removendo XFCE e seus componentes..."
sudo dnf remove -y \
  xfce4-terminal \
  xfce4-panel \
  xfce-polkit \
  im-chooser-xfce \
  libxfce4ui \
  libxfce4util \
  libxfce4windowing \
  2>/dev/null || echo "    [aviso] Alguns pacotes XFCE não encontrados, continuando..."

# ─── Drivers Xorg desnecessários ──────────────────────────────────────────────
echo "==> Removendo drivers Xorg não utilizados (AMD, NVIDIA, VM)..."
sudo dnf remove -y \
  xorg-x11-drv-amdgpu \
  xorg-x11-drv-ati \
  xorg-x11-drv-nouveau \
  xorg-x11-drv-vmware \
  xorg-x11-drv-qxl \
  2>/dev/null || echo "    [aviso] Alguns drivers Xorg não encontrados, continuando..."

# ─── GNOME (componentes dispensáveis) ─────────────────────────────────────────
echo "==> Removendo componentes GNOME desnecessários..."
sudo dnf remove -y \
  gnome-abrt \
  gnome-themes-extra \
  2>/dev/null || echo "    [aviso] Alguns pacotes GNOME não encontrados, continuando..."

# ─── Órfãos ───────────────────────────────────────────────────────────────────
echo "==> Removendo pacotes órfãos..."
sudo dnf autoremove -y

# ─── systemd target ───────────────────────────────────────────────────────────
echo "==> Configurando systemd para multi-user.target (sem display manager no boot)..."
sudo systemctl set-default multi-user.target

echo ""
echo "==> [cleanup_desktop] Expurgo concluído com sucesso!"
echo "    O sistema irá iniciar no modo multi-user (TTY) a partir do próximo boot."
echo "    O Hyprland continuará sendo iniciado automaticamente via ~/.bash_profile na tty1."
