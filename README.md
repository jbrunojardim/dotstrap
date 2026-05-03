# dotstrap

Automação de configuração inicial de ambientes Linux em etapas independentes, cada uma com responsabilidade única.

Suporte a **Fedora/RHEL** (`dnf`), **Arch Linux** (`pacman`) e **Debian/Ubuntu** (`apt`) — o gestor de pacotes é detectado automaticamente.

---

## Índice

- [Fluxo principal](#fluxo-principal)
- [Etapa 1 — Inicializar o sistema](#etapa-1--inicializar-o-sistema)
- [Etapa 2 — Gerar chaves SSH](#etapa-2--gerar-chaves-ssh)
- [Etapa 3 — Instalar o ambiente desktop](#etapa-3--instalar-o-ambiente-desktop)
- [Etapa 4 — Aplicar dotfiles](#etapa-4--aplicar-dotfiles)
  - [4.1 — Core](#41--core)
  - [4.2 — Desktop Hyprland](#42--desktop-hyprland)
  - [4.3 — VSCodium](#43--vscodium)
  - [4.4 — VS Code](#44--vs-code)
- [linkr](#linkr)
- [Neovim](#neovim)
- [VSCodium](#vscodium)
- [Ferramentas opcionais](#ferramentas-opcionais)
  - [Sistema headless/servidor](#sistema-headlessservidor)
  - [Banner de login no TTY](#banner-de-login-no-tty)
  - [Unlock LUKS2 via keyfile](#unlock-automático-do-luks2-via-keyfile)
  - [Limpar ambientes desktop](#limpar-ambientes-desktop-desnecessários)
  - [Forçar resolução TTY/GRUB](#forçar-resolução-do-ttygrub)
  - [Zen Browser — Instalar](#zen-browser--instalar)
  - [VS Code — Instalar](#vs-code--instalar)
  - [VS Code — Atualizar](#vs-code--atualizar)
  - [Fontes](#fontes)
  - [kubectl](#kubectl)
  - [Sudo sem senha](#sudo-sem-senha)
  - [Docker CE](#docker-ce)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Requisitos](#requisitos)

---

## Fluxo principal

| Etapa | Script | Responsabilidade |
|-------|--------|-----------------|
| 1 | `bootstrap/init.sh` | Detecção do gestor de pacotes, update do sistema e instalação de pacotes essenciais |
| 2 | `bootstrap/ssh_keys.sh` | Geração de chaves SSH e configuração do `~/.ssh/config` |
| 3 | `bootstrap/hyprland.sh` | Instalação do Hyprland e dependências do ambiente gráfico |
| 4 | `bootstrap/dotfiles.sh` | Clone dos dotfiles privados e execução do `linkr` |

---

## Etapa 1 — Inicializar o sistema

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/init.sh | bash
```

O script detecta automaticamente o gestor de pacotes disponível (`dnf`, `pacman` ou `apt`) e executa:
- Atualização completa do sistema
- Instalação dos pacotes essenciais
- Habilitação do serviço SSH

| Pacote | Uso |
|--------|-----|
| `vim` | Editor de texto |
| `neovim` | Editor de texto extensível via Lua |
| `tmux` | Multiplexador de terminal |
| `curl` | Transferência de dados via URL |
| `git` | Controle de versão |
| `awk` | Processamento de texto |
| `iproute` / `iproute2` | Ferramentas de rede (`ip`, `ss`) |
| `ncurses` | Suporte a interfaces de terminal |
| `openssh` | Cliente e servidor SSH |
| `ffmpeg` | Codecs de mídia — necessário para reprodução de vídeo no Zen Browser |

---

## Etapa 2 — Gerar chaves SSH

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/ssh_keys.sh | bash
```

O script:
- Cria `~/.ssh/` com as permissões corretas
- Gera uma chave `ed25519` em `~/.ssh/github` para o GitHub (se não existir)
- Gera uma chave `ed25519` em `~/.ssh/gitlab` para o GitLab (se não existir)
- Configura o `~/.ssh/config` com os blocos `Host github.com` e `Host gitlab.com` (idempotente — adiciona apenas o que estiver faltando)
- Exibe as chaves públicas no terminal

> O `~/.ssh/config` é configurado diretamente pelo script, sem depender do `linkr` ou do repositório privado de dotfiles.

**Após executar**, adicione cada chave pública no serviço correspondente:

| Serviço | Caminho |
|---------|---------|
| GitHub | **Settings → SSH and GPG Keys → New SSH Key** |
| GitLab | **Preferences → SSH Keys → Add new key** |

Em seguida, valide as conexões:
```bash
ssh -T git@github.com
ssh -T git@gitlab.com
```

---

## Etapa 3 — Instalar o ambiente desktop

> Execute em máquinas com monitor — **não executar em servidores headless**. Para servidores, pule para a Etapa 4 ou use `bootstrap/headless.sh`.

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/hyprland.sh | bash
```

O script detecta o gestor de pacotes e:
- Instala o Hyprland e todas as dependências do ambiente gráfico
- Instala `gnome-keyring` e `xdg-desktop-portal-hyprland` para autenticação OAuth e integração Wayland
- Configura o **auto-start do Hyprland** via `~/.bash_profile` na tty1 (idempotente)

| Pacote | Uso |
|--------|-----|
| `hyprland` | Compositor Wayland |
| `hyprlock` | Tela de bloqueio |
| `hypridle` | Daemon de bloqueio automático por inatividade |
| `hyprshot` | Capturas de tela (Fedora) |
| `waybar` | Barra de status |
| `kitty` | Emulador de terminal |
| `wofi` | Launcher de aplicações |
| `wlogout` | Menu de energia |
| `swaync` | Daemon de notificações |
| `gnome-keyring` | Armazenamento seguro de credenciais e tokens OAuth |
| `xdg-desktop-portal-hyprland` | Portal Wayland — redireciona browser para login OAuth e integra apps |

> O `gnome-keyring` e o `xdg-desktop-portal-hyprland` são necessários para que o login OAuth do VS Code e do Zen Browser funcione corretamente no Hyprland.

---

## Etapa 4 — Aplicar dotfiles

### 4.1 — Core

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash
```

O script:
- Valida que o `git` está disponível
- Clona o repositório privado de dotfiles em `~/.dotfiles` (ou faz `pull` se já existir)
- Executa `linkr core`, aplicando os dotfiles essenciais: `vim`, `git`, `nvim`, `ssh`

> Os dotfiles estão em um repositório privado separado (`jbrunojardim/dotfile`), acessível via SSH configurado na etapa 2. As configurações globais do git (`user.name`, `user.email`, `core.editor`) são aplicadas automaticamente pelo `linkr`, mantendo esses dados fora do repositório público.

### 4.2 — Desktop Hyprland

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash -s desk_hypr
```

Além do `core`, executa `linkr desk_hypr` se o Hyprland estiver instalado, aplicando os dotfiles de `hypr`, `waybar` e `kitty`.

> Requer a etapa 3 executada previamente. Se o Hyprland não for detectado, o script exibe um aviso e encerra sem aplicar os dotfiles de desktop.

### 4.3 — VSCodium

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash -s vscodium
```

Se o VSCodium estiver instalado, o script:
- Instala as extensões via `scripts/vscodium.sh`
- Aplica os dotfiles via `linkr vscodium`, criando o symlink de `settings.json` e `tasks.json`

> Se o VSCodium não for detectado, o script exibe um aviso e encerra sem aplicar nada.

### 4.4 — VS Code

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash -s vscode
```

Se o VS Code estiver instalado, o script:
- Instala as extensões via `scripts/vscode.sh`
- Aplica os dotfiles via `linkr vscode`, criando o symlink de `settings.json` e `tasks.json`

> Se o VS Code não for detectado, o script exibe um aviso e encerra sem aplicar nada. Para instalar o VS Code, veja [VS Code — Instalar](#vs-code--instalar).

---

## linkr

O `linkr` é o script de aplicação de dotfiles do repositório privado. Ele percorre automaticamente cada app na estrutura do repo e cria symlinks espelhando os caminhos relativos em `$HOME`, sem precisar listar arquivos manualmente.

**Uso:**
```bash
./linkr                   # exibe ajuda e apps disponíveis
./linkr core              # aplica dotfiles essenciais: vim, git, nvim, ssh
./linkr desk_hypr         # aplica dotfiles do ambiente Hyprland: hypr, waybar, kitty
./linkr vscodium          # aplica dotfiles do VSCodium: settings.json, tasks.json
./linkr vscode            # aplica dotfiles do VS Code: settings.json, tasks.json
./linkr core desk_hypr    # aplica ambos os grupos
./linkr all               # aplica todos os apps disponíveis
./linkr waybar            # aplica um app individual
./linkr issue             # configura o banner de login no TTY (/etc/issue.d/)
```

**Grupos disponíveis:**

| Grupo | Apps |
|-------|------|
| `core` | `vim`, `git`, `nvim`, `ssh` |
| `desk_hypr` | `hypr`, `waybar`, `kitty` |
| `vscodium` | `.config/VSCodium/User/settings.json`, `.config/VSCodium/User/tasks.json` |
| `vscode` | `.config/Code/User/settings.json`, `.config/Code/User/tasks.json` |

**Filosofia:** cada app ocupa uma pasta no repo que espelha a estrutura do `$HOME`. O `linkr` percorre os arquivos com `find` recursivo e cria o symlink correspondente para cada um.

```
dotfile/waybar/.config/waybar/config.jsonc  →  ~/.config/waybar/config.jsonc
dotfile/hypr/.config/hypr/hyprland.conf     →  ~/.config/hypr/hyprland.conf
dotfile/vim/.vim/vimrc                      →  ~/.vim/vimrc
```

Se um symlink já existir e apontar para o caminho correto, ele é ignorado. Se existir um arquivo ou link diferente no destino, ele é removido antes de criar o novo.

> O comando `issue` é desacoplado de todos os grupos — inclusive do `all` — e deve ser executado explicitamente. Ele escreve em `/etc/issue.d/garden.issue` e requer `sudo`.

---

## Neovim

A configuração do Neovim é minimal e focada em produtividade desde o primeiro uso:

| Plugin | Função |
|--------|--------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Gerenciador de plugins — bootstrap automático |
| [tokyonight](https://github.com/folke/tokyonight.nvim) | Tema de cores (inativo) |
| [catppuccin](https://github.com/catppuccin/nvim) | Tema de cores — variante `mocha` (ativo) |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | Ícones para plugins |
| [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) | File explorer em painel lateral |
| [telescope](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder para arquivos, buffers e grep |
| [treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting e parsing avançado |
| [gitsigns](https://github.com/lewis6991/gitsigns.nvim) | Indicadores de diff do git no gutter |
| [toggleterm](https://github.com/akinsho/toggleterm.nvim) | Terminal integrado com suporte a múltiplas instâncias |
| [lualine](https://github.com/nvim-lualine/lualine.nvim) | Barra de status |
| [plenary](https://github.com/nvim-lua/plenary.nvim) | Utilitários Lua (dependência do telescope) |

| Atalho | Ação |
|--------|------|
| `<leader>e` | Abre/fecha o painel do nvim-tree |
| `<C-\>` | Abre/fecha terminal horizontal |
| `<leader>tt` | Terminal horizontal |
| `<leader>tf` | Terminal flutuante |
| `<leader>t1-3` | Terminais numerados |
| `<leader>fg` | Telescope: live grep |
| `<leader>fb` | Telescope: buffers abertos |
| `<leader>fh` | Telescope: help tags |

Os plugins são instalados automaticamente na primeira abertura do `nvim`, sem nenhum passo extra.

---

## VSCodium

As configurações do VSCodium ficam no repositório privado em `vscodium/.config/VSCodium/User/` e são aplicadas via `linkr vscodium`.

**Keybindings vim (`<leader> = Space`):**

| Atalho | Ação |
|--------|------|
| `<leader>w` | Salvar arquivo |
| `<leader>e` | Toggle sidebar |
| `<leader>p` | Quick open (busca de arquivos) |
| `<leader>n` | Próxima aba |
| `<leader>[` | Aba anterior |
| `<leader>t` | Toggle terminal integrado |
| `<leader>a` | Toggle painel auxiliar (Secondary Sidebar) |
| `<leader>c` | Focar painel auxiliar |
| `<leader>gs` | Sync git — auto commit e push via `sync_git.sh` |
| `<leader>/` | Limpar highlight de busca |
| `;` | Abre o command mode (`:`) |
| `q` | Fechar aba (`:q`) |
| `<C-h/j/k/l>` | Navegar entre painéis |

**Task: sync git**

A task `sync git` é disparada pelo `<leader>gs` e executa `~/.dotfiles/scripts/sync_git.sh`, que itera pelos repositórios pessoais (`.dotfiles`, `dotfiles`, `dotstrap`), faz pull com rebase e push com mensagem automática de timestamp.

**Extensões instaladas:**

| Extensão | Uso |
|----------|-----|
| `vscodevim.vim` | Emulação de Vim no editor |
| `catppuccin.catppuccin-vsc` | Tema de cores |
| `alexdauenhauer.catppuccin-noctis-icons` | Tema de ícones |
| `catppuccin.catppuccin-vsc-icons` | Ícones alternativos Catppuccin |
| `anthropic.claude-code` | Claude Code integrado ao editor |

---

## Ferramentas opcionais

### Sistema headless/servidor

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/headless.sh | bash
```

Execute em máquinas que serão usadas como servidores headless — especialmente para rodar **k3d/Kubernetes** em laboratório.

> **Recomendado:** reiniciar o sistema após a execução para garantir que todas as configurações entrem em vigor (especialmente GRUB e logind).

| Configuração | Detalhe |
|---|---|
| Tampa fechada ignorada | `HandleLidSwitch=ignore` via `/etc/systemd/logind.conf.d/lid.conf` |
| SSH keepalive | `ClientAliveInterval=60` / `ClientAliveCountMax=3` — evita travamento de conexões SSH ociosas |
| Swap desabilitado | `swapoff -a` + remoção da entrada no `/etc/fstab` — requisito do k3s |
| Cockpit desabilitado | `systemctl disable --now cockpit.socket` |
| firewalld desabilitado | controle de rede delegado ao Kubernetes (Network Policies, kube-proxy) |
| GRUB timeout zerado | `GRUB_TIMEOUT=0` em `/etc/default/grub` + `grub2-mkconfig` |
| Plymouth removido | `dnf remove plymouth` — bootloader gráfico desnecessário em servidor |
| SELinux → `disabled` | compatibilidade com k3d/k3s — requer reboot para efeito completo |

> **SELinux `disabled`:** requer reboot para entrar em vigor completamente. Para reverter para `enforcing` no futuro, será necessário reboot + relabel do filesystem.

> **firewalld desabilitado:** em laboratório headless em rede local, o controle de rede fica a cargo do próprio Kubernetes. Para reativar: `systemctl enable --now firewalld`.

### Banner de login no TTY

Após aplicar os dotfiles (etapa 4), execute:

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash -s issue
```

Configura o `/etc/issue.d/garden.issue` com um banner ASCII art exibido na tela de login do TTY, com cores Catppuccin Mocha. O arquivo fica em `/etc/issue.d/` para sobreviver a atualizações do sistema.

> O banner aparece **apenas na tela de login do TTY** — não interfere com terminais abertos após o login.

O comando aplica:
- ASCII art **GARDEN** em mauve (`#cba6f7`)
- Linha com distro, hardware e compositor em blue (`#89b4fa`)
- Separadores em overlay (`#45475a`)

### Unlock automático do LUKS2 via keyfile

Consulte o guia completo: [tools/LUKS.md](tools/LUKS.md)

Elimina a necessidade de digitar a senha a cada boot em máquinas com disco criptografado (LUKS2). O processo envolve gerar um keyfile, adicioná-lo ao LUKS e configurar o dracut para incluí-lo no initramfs.

> **IMPORTANTE:** a senha LUKS original continua válida como recovery. Guarde-a em local seguro.

### Limpar ambientes desktop desnecessários

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/cleanup_desktop.sh | bash
```

Execute em máquinas que vieram com i3, XFCE ou LightDM pré-instalados (ex: Fedora i3 spin).

> **Atenção:** execute apenas após a etapa 3 concluída e com o Hyprland funcional.

O script remove:

| O que remove | Pacotes |
|---|---|
| i3 | `i3`, `i3status`, `i3lock`, `i3-config-fedora`, `python3-i3ipc`, `fedora-release-i3` |
| LightDM | `lightdm`, `lightdm-gtk`, `lightdm-gobject`, `lightdm-gtk-greeter-settings` |
| XFCE | `xfce4-terminal`, `xfce4-panel`, `xfce-polkit`, `libxfce4ui`, `libxfce4util`, `libxfce4windowing` |
| Drivers Xorg | AMD, NVIDIA, VMware, QXL |
| GNOME parcial | `gnome-abrt`, `gnome-themes-extra` |
| Órfãos | via `dnf autoremove` |

O script **mantém**:
- `xorg-x11-server-Xwayland` — necessário para apps XWayland
- `xorg-x11-drv-intel` — fallback para GPU Intel
- `xorg-x11-drv-evdev`, `xorg-x11-drv-wacom` — input devices
- `gnome-keyring` — gerenciamento de credenciais
- `gnome-disk-utility` — gerenciamento de discos

Também configura o systemd para iniciar sem display manager:
```bash
systemctl set-default multi-user.target
```
O Hyprland continua subindo automaticamente via `~/.bash_profile` na tty1.

### Forçar resolução do TTY/GRUB

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/grub_resolution.sh | sudo bash
```

Execute após trocar de monitor para ajustar a resolução da tela de login do TTY.

O script:
- Detecta automaticamente o monitor externo conectado (ignora o `eDP` interno)
- Lê o EDID do monitor via `/sys/class/drm/` e extrai a resolução preferida (DTD 1)
- Instala `edid-decode` via `dnf` se não estiver presente
- Atualiza `/etc/default/grub` com `video=`, `GRUB_GFXMODE` e `GRUB_GFXPAYLOAD_LINUX=keep`
- Regenera o GRUB via `grub2-mkconfig`

> Requer reboot para aplicar. Execute uma vez por monitor — não precisa rodar a cada boot.

### Zen Browser — Instalar

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/zen-browser.sh | bash
```

Instala o Zen Browser em `~/.local` via release oficial do GitHub — sem gestor de pacotes, sem `sudo`, compatível com qualquer distro.

O script:
- Verifica se já está instalado (idempotente)
- Obtém a URL do release mais recente via GitHub API
- Extrai em `~/.local/lib/zen-browser`
- Cria o wrapper `~/.local/bin/zen`
- Cria a entrada `~/.local/share/applications/zen-browser.desktop`

> Para reprodução de vídeo no YouTube e outros sites, o `ffmpeg` precisa estar instalado — provisionado automaticamente pela etapa 1.

### VS Code — Instalar

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/vscode.sh | bash
```

Instala o VS Code em `~/.local` via tarball oficial da Microsoft — sem gestor de pacotes, sem `sudo`, compatível com qualquer distro.

O script:
- Verifica se já está instalado (idempotente)
- Baixa o tarball mais recente de `update.code.visualstudio.com/latest/linux-x64/stable`
- Extrai em `~/.local/lib/vscode`
- Cria o wrapper `~/.local/bin/code`
- Cria a entrada `~/.local/share/applications/vscode.desktop`
- Cria `~/.config/code-flags.conf` com `--password-store=gnome-libsecret` para autenticação OAuth funcionar corretamente no Hyprland

> Para que o login OAuth redirecione corretamente para o browser, o `gnome-keyring` e o `xdg-desktop-portal-hyprland` precisam estar instalados — provisionados automaticamente pela etapa 3.

**Após instalar**, aplique os dotfiles: veja [4.4 — VS Code](#44--vs-code).

**Extensões instaladas:**

| Extensão | Uso |
|----------|-----|
| `vscodevim.vim` | Emulação de Vim no editor |
| `catppuccin.catppuccin-vsc` | Tema de cores |
| `alexdauenhauer.catppuccin-noctis-icons` | Tema de ícones |
| `catppuccin.catppuccin-vsc-icons` | Ícones alternativos Catppuccin |
| `anthropic.claude-code` | Claude Code integrado ao editor |

### VS Code — Atualizar

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/vscode.sh | bash -s -- --update
```

Remove os binários existentes e baixa a versão mais recente. O wrapper, o `.desktop` e o `code-flags.conf` são preservados.

### Fontes

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/fonts.sh | bash
```

Instala as fontes do sistema de acordo com a distro detectada.

| Distro | Fontes instaladas | Método |
|--------|------------------|--------|
| Fedora/RHEL | JetBrainsMono Nerd Font | `curl` + `unzip` via Nerd Fonts GitHub |
| Arch Linux | JetBrainsMono Nerd Font, Noto, Noto Emoji, Liberation | `pacman` |
| Debian/Ubuntu | JetBrainsMono Nerd Font | `curl` + `unzip` via Nerd Fonts GitHub |

> A JetBrainsMono Nerd Font é necessária para a correta exibição de ícones no Neovim, VS Code, VSCodium e no terminal Kitty.

### kubectl

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/kubectl.sh | bash
```

Execute em máquinas que precisam interagir com clusters Kubernetes.

O script:
- Verifica se o `kubectl` já está instalado (idempotente)
- Baixa a versão stable oficial via `dl.k8s.io`
- Instala em `/usr/local/bin/kubectl`

### Sudo sem senha

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/sudo_nopasswd.sh | sudo bash
```

O script:
- Detecta o usuário real via `$SUDO_USER`
- Cria `/etc/sudoers.d/<usuario>_nopasswd` com a regra `NOPASSWD:ALL` e permissão `0440`
- Valida o arquivo com `visudo -cf` antes de manter — reverte automaticamente se inválido

> **Atenção:** concede privilégio amplo ao usuário. Execute apenas em ambientes controlados.

### Docker CE

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/docker.sh | bash
```

Execute em máquinas que precisam do Docker — especialmente servidores de laboratório CI/CD.

O script:
- Remove pacotes conflitantes (versões antigas ou do sistema)
- Adiciona o repositório oficial do Docker para Fedora
- Instala `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` e `docker-compose-plugin`
- Inicia e habilita o serviço via `systemctl`
- Adiciona o usuário atual ao grupo `docker` para uso sem sudo

> Após a execução, rode `newgrp docker` ou abra uma nova sessão para aplicar o grupo.

---

## Estrutura do repositório

```
dotstrap/              # repositório público
├── bootstrap/
│   ├── init.sh                 # Etapa 1: detecção de distro, update e pacotes essenciais
│   ├── ssh_keys.sh             # Etapa 2: gera chaves SSH e configura ~/.ssh/config
│   ├── hyprland.sh             # Etapa 3: instala Hyprland e ambiente gráfico
│   ├── dotfiles.sh             # Etapa 4: clone dos dotfiles e execução do linkr
│   └── headless.sh             # Opcional: configura sistema para uso headless/servidor
└── tools/
    ├── LUKS.md                 # Guia: unlock automático do LUKS2 via keyfile no initramfs
    ├── luks_tpm.sh             # Referência: unlock via TPM2
    ├── zen-browser.sh          # Opcional: instala Zen Browser via release oficial (distro-agnóstico)
    ├── fonts.sh                # Opcional: instala fontes do sistema (JetBrainsMono + extras no Arch)
    ├── vscode.sh               # Opcional: instala/atualiza VS Code via tarball oficial (distro-agnóstico)
    ├── cleanup_desktop.sh      # Opcional: remove i3, XFCE, LightDM e configura multi-user.target
    ├── docker.sh               # Opcional: instala Docker CE no Fedora 43
    ├── grub_resolution.sh      # Opcional: detecta monitor externo e força resolução no TTY/GRUB
    ├── kubectl.sh              # Opcional: instala kubectl (versão stable oficial)
    └── sudo_nopasswd.sh        # Opcional: configura sudo sem senha para o usuário atual

dotfile/                        # repositório privado
├── linkr                       # gerenciador de dotfiles (core, desk_hypr, vscodium, vscode, all, issue)
├── scripts/
│   ├── setup_issue.sh          # banner ASCII art Catppuccin Mocha no TTY login
│   ├── vscodium.sh             # instalação de extensões do VSCodium
│   ├── vscode.sh               # instalação de extensões do VS Code
│   └── sync_git.sh             # auto commit e push dos repositórios pessoais
├── vscodium/
│   └── .config/VSCodium/User/
│       ├── settings.json       # configurações, tema e keybindings vim
│       └── tasks.json          # task sync git (<leader>gs)
├── vscode/
│   └── .config/Code/User/
│       ├── settings.json       # configurações, tema e keybindings vim
│       └── tasks.json          # task sync git (<leader>gs)
├── git/
│   └── .gitconfig
├── vim/
│   └── .vim/
│       ├── vimrc
│       ├── autocmds.vim
│       ├── copilot.vim
│       ├── git.vim
│       ├── keymaps.vim
│       ├── nerdtree.vim
│       ├── netrw.vim
│       ├── plugins.vim
│       ├── statusbar.vim
│       ├── templates.vim
│       ├── terminal.vim
│       └── theme.vim
├── nvim/
│   └── .config/nvim/
│       ├── init.lua
│       └── lua/
│           ├── config/
│           │   ├── keymaps.lua
│           │   ├── lazy.lua
│           │   └── options.lua
│           └── plugins/
│               ├── catppuccin.lua
│               ├── devicons.lua
│               ├── gitsigns.lua
│               ├── lualine.lua
│               ├── nvim-tree.lua
│               ├── plenary.lua
│               ├── telescope.lua
│               ├── toggleterm.lua
│               ├── tokyonight.lua
│               └── treesitter.lua
├── waybar/
│   └── .config/waybar/
│       ├── config.jsonc
│       └── style.css
├── hypr/
│   └── .config/hypr/
│       ├── hyprland.conf
│       ├── hyprlock.conf
│       ├── hypridle.conf
│       └── mocha.conf
└── kitty/
    └── .config/kitty/
        └── kitty.conf
```

---

## Requisitos

- Sistema baseado em **Fedora/RHEL** (`dnf`), **Arch Linux** (`pacman`) ou **Debian/Ubuntu** (`apt`)
- Acesso `sudo`
- `curl` e `bash` disponíveis no sistema base

---

## Licença

MIT
