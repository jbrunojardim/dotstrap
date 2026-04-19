#!/bin/bash
set -e

echo "=== Instalando Docker CE ==="

# Remover pacotes conflitantes
sudo dnf remove -y docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine 2>/dev/null || true

# Dependência para gerenciar repositórios
sudo dnf install -y dnf-plugins-core

# Adicionar repositório oficial do Docker (idempotente)
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
  sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
else
  echo "Repositorio docker-ce.repo ja existe, pulando."
fi

# Instalar Docker CE
sudo dnf install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Iniciar e habilitar o serviço
sudo systemctl start docker
sudo systemctl enable docker

# Permitir uso sem sudo
sudo usermod -aG docker "$USER"

echo ""
echo "=== Docker instalado com sucesso ==="
echo "Execute 'newgrp docker' ou abra uma nova sessao para usar sem sudo."
