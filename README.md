# dotstrap
Automação de configuração inicial de ambientes Linux em quatro etapas independentes, cada uma com responsabilidade única.

---

## Fluxo
```
1. bootstrap/system.sh    →   update do sistema e instalação de pacotes essenciais
2. bootstrap/ssh_keys.sh  →   gera chaves SSH para o GitHub e GitLab
3. bootstrap/desktop.sh   →   instala Hyprland e dependências do ambiente gráfico
4. bootstrap/dotfiles.sh  →   clone dos dotfiles privados e execução do linkr

Opcional:
   bootstrap/dotfiles.sh vscodium  →   instala extensões e aplica dotfiles do VSCodium
   bootstrap/dotfiles.sh vscode    →   instala extensões e aplica dotfiles do VS Code
   bootstrap/headless.sh           →   configura o sistema para uso headless/servidor (k3d/Kubernetes)
   tools/luks_keyfile.sh           →   unlock automático do LUKS2 via keyfile no initramfs
   tools/cleanup_desktop.sh        →   remove ambientes desktop desnecessários (i3, XFCE, LightDM)
   tools/kubectl.sh                →   instala kubectl (versão stable oficial)
   tools/vscode.sh                 →   instala VS Code no Fedora
   tools/sudo_nopasswd.sh          →   configura sudo sem senha para o usuário atual
   tools/docker.sh                 →   instala Docker CE (repositório oficial, sem sudo pós-instalação)
   tools/grub_resolution.sh        →   detecta o monitor externo e força a resolução no TTY/GRUB
```

---

## Etapa 1 - Preparar o sistema
```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/system.sh | bash
```
O script:
- Atualiza o sistema via `dnf update`
- Instala os pacotes essenciais

| Pacote | Uso |
|--------|-----|
| `vim` | Editor de texto |
| `neovim` | Editor de texto extensível via Lua |
| `tmux` | Multiplexador de terminal |
| `curl` | Transferência de dados via URL |
| `git` | Controle de versão |
| `awk` | Processamento de texto |
| `iproute` | Ferramentas de rede (`ip`, `ss`) |
| `ncurses` | Suporte a interfaces de terminal |
| `openssh` | Cliente SSH |
| `openssh-server` | Servidor SSH |

---

## Etapa 2 - Gerar chaves SSH para GitHub e GitLab
```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/ssh_keys.sh | bash
```
O script:
- Cria `~/.ssh/` com as permissões corretas
- Gera uma chave `ed25519` em `~/.ssh/github-dotfiles` para o GitHub (se não existir)
- Gera uma chave `ed25519` em `~/.ssh/gitlab-ms` para o GitLab (conta MS, se não existir)
- Gera uma chave `ed25519` em `~/.ssh/gitlab-google` para o GitLab (conta Google, se não existir)
- Exibe as chaves públicas no terminal

> A configuração do `~/.ssh/config` (blocos `Host gitlab-ms` e `Host gitlab-google`) é aplicada pelo `linkr core` na etapa 4, via repositório privado de dotfiles. Os remotes dos repositórios GitLab devem usar os aliases — ex: `git@gitlab-ms:org/repo.git`.

**Após executar**, adicione cada chave pública no serviço correspondente:

| Serviço | Caminho |
|---------|---------|
| GitHub | **Settings → SSH and GPG Keys → New SSH Key** |
| GitLab (conta MS) | **Preferences → SSH Keys → Add new key** |
| GitLab (conta Google) | **Preferences → SSH Keys → Add new key** |

Em seguida, valide as conexões:
```bash
ssh -T git@github.com
ssh -T git@gitlab-ms
ssh -T git@gitlab-google
```

---

## Etapa 3 - Instalar o ambiente desktop (opcional)
```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/desktop.sh | bash
```
O script:
- Habilita o COPR `solopasha/hyprland`
- Instala o Hyprland e todas as dependências do ambiente gráfico
- Instala a JetBrainsMono Nerd Font em `~/.local/share/fonts`
- Configura o **auto-start do Hyprland** via `~/.bash_profile` na tty1 (idempotente)

| Pacote | Uso |
|--------|-----|
| `hyprland` | Compositor Wayland |
| `hyprlock` | Tela de bloqueio |
| `hypridle` | Daemon de bloqueio automático por inatividade |
| `hyprshot` | Capturas de tela |
| `waybar` | Barra de status |
| `kitty` | Emulador de terminal |
| `wofi` | Launcher de aplicações |
| `wlogout` | Menu de energia |
| `swaync` | Daemon de notificações |
| `unzip` | Extração de arquivos zip |

> A JetBrainsMono Nerd Font é instalada via download direto do repositório oficial do [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) (v3.2.1).

---

## Etapa 4 - Aplicar dotfiles

### 4.1 - Core
```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash
```
O script:
- Valida que o `git` está disponível
- Clona o repositório privado de dotfiles em `~/.dotfiles` (ou faz `pull` se já existir)
- Executa `linkr core`, aplicando os dotfiles essenciais: `vim`, `git`, `nvim`, `ssh`

> Os dotfiles estão em um repositório privado separado (`jbrunojardim/dotfile`), acessível via SSH configurado na etapa 2. As configurações globais do git (`user.name`, `user.email`, `core.editor`) são aplicadas automaticamente pelo `linkr`, mantendo esses dados fora do repositório público.

### 4.2 - Desktop Hyprland (opcional)
```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash -s desk_hypr
```
Além do `core`, executa `linkr desk_hypr` se o Hyprland estiver instalado, aplicando os dotfiles de `hypr`, `waybar` e `kitty`.

> Requer a etapa 3 executada previamente. Se o Hyprland não for detectado, o script exibe um aviso e encerra sem aplicar os dotfiles de desktop.

### 4.3 - VSCodium (opcional)
```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash -s vscodium
```
Se o VSCodium estiver instalado, o script:
- Instala as extensões via `scripts/vscodium.sh`
- Aplica os dotfiles via `linkr vscodium`, criando o symlink de `settings.json` e `tasks.json`

| Extensão | Uso |
|----------|-----|
| `vscodevim.vim` | Emulação de Vim no editor |
| `catppuccin.catppuccin-vsc` | Tema de cores |
| `alexdauenhauer.catppuccin-noctis-icons` | Tema de ícones |
| `catppuccin.catppuccin-vsc-icons` | Ícones alternativos Catppuccin |
| `anthropic.claude-code` | Claude Code integrado ao editor |

> Se o VSCodium não for detectado, o script exibe um aviso e encerra sem aplicar nada.

---

## Opcional - Configurar o sistema para uso headless/servidor

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/headless.sh | bash
```

Execute este script em máquinas que serão usadas como servidores headless — especialmente para rodar **k3d/Kubernetes** em laboratório.

> **Recomendado:** reiniciar o sistema após a execução para garantir que todas as configurações entrem em vigor (especialmente GRUB e logind).

O script aplica:

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

---

## Opcional - Unlock automático do LUKS2 via keyfile

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/luks_keyfile.sh | sudo bash
```

Execute este script em máquinas com disco criptografado (LUKS2) para eliminar a necessidade de digitar a senha a cada boot.

O script:
- Detecta a partição LUKS automaticamente via `lsblk`
- Obtém o UUID da partição para nomear o keyfile
- Solicita a senha LUKS interativamente — nunca em argumento ou arquivo
- Valida a senha antes de prosseguir
- Gera um keyfile aleatório (512 bytes) em `/etc/cryptsetup-keys.d/luks-UUID.key` com permissão `0400`
- Configura o dracut para incluir o keyfile no initramfs
- Adiciona o keyfile ao slot LUKS via `cryptsetup luksAddKey`
- Regenera o initramfs com `dracut -fv`

> **Idempotente:** se o keyfile já existir, o script encerra sem fazer alterações.

> **IMPORTANTE:** a senha LUKS original continua válida como recovery. Guarde-a em local seguro — sem ela não há como recuperar o acesso caso o initramfs seja corrompido ou o keyfile removido.

---

## Opcional - Limpar ambientes desktop desnecessários

```bash
bash <(curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/cleanup_desktop.sh)
```

Execute este script em máquinas que vieram com i3, XFCE ou LightDM pré-instalados (ex: Fedora i3 spin).

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

---

## Opcional - Forçar resolução do TTY/GRUB pelo monitor conectado

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/grub_resolution.sh | sudo bash
```

Execute este script após trocar de monitor para ajustar a resolução da tela de login do TTY.

O script:
- Detecta automaticamente o monitor externo conectado (ignora o `eDP` interno)
- Lê o EDID do monitor via `/sys/class/drm/` e extrai a resolução preferida (DTD 1)
- Instala `edid-decode` via `dnf` se não estiver presente
- Atualiza `/etc/default/grub` com `video=`, `GRUB_GFXMODE` e `GRUB_GFXPAYLOAD_LINUX=keep`
- Regenera o GRUB via `grub2-mkconfig`

> Requer reboot para aplicar. Execute uma vez por monitor — não precisa rodar a cada boot.

---

## Opcional - VS Code

### 1. Instalar
```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/vscode.sh | bash
```

O script:
- Verifica se o `code` já está instalado (idempotente)
- Importa a chave GPG da Microsoft
- Adiciona o repositório oficial em `/etc/yum.repos.d/vscode.repo`
- Instala via `dnf install code`

### 2. Aplicar dotfiles
```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash -s vscode
```

O script:
- Instala as extensões via `scripts/vscode.sh`
- Aplica os dotfiles via `linkr vscode`, criando o symlink de `settings.json` e `tasks.json`

| Extensão | Uso |
|----------|-----|
| `vscodevim.vim` | Emulação de Vim no editor |
| `catppuccin.catppuccin-vsc` | Tema de cores |
| `alexdauenhauer.catppuccin-noctis-icons` | Tema de ícones |
| `catppuccin.catppuccin-vsc-icons` | Ícones alternativos Catppuccin |
| `anthropic.claude-code` | Claude Code integrado ao editor |

> Se o VS Code não for detectado, o script exibe um aviso e encerra sem aplicar nada.

---

## Opcional - Instalar kubectl

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/kubectl.sh | bash
```

Execute este script em máquinas que precisam interagir com clusters Kubernetes.

O script:
- Verifica se o `kubectl` já está instalado (idempotente)
- Baixa a versão stable oficial via `dl.k8s.io`
- Instala em `/usr/local/bin/kubectl`

---

## Opcional - Autorizar acesso SSH ao servidor

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/ssh_authorize.sh | bash
```

Execute este script em qualquer máquina que precise de acesso transparente aos servidores do homelab. A senha de cada servidor será solicitada uma única vez.

O script itera sobre a lista de servidores (`srvfed01`, `srvlnx002`) e para cada um:
- Gera a chave `~/.ssh/<host>` (se não existir)
- Copia a chave pública para o servidor via `ssh-copy-id`
- Valida a conexão sem senha ao final

> O `~/.ssh/config` com os blocos de cada servidor já é aplicado pelo `linkr core` via dotfiles privados. Este script apenas gera e registra as chaves nos servidores.

---

## Opcional - Sudo sem senha para o usuário atual

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/sudo_nopasswd.sh | sudo bash
```

Execute este script para configurar acesso `sudo` sem senha para o usuário atual.

O script:
- Detecta o usuário real via `$SUDO_USER`
- Cria `/etc/sudoers.d/<usuario>_nopasswd` com a regra `NOPASSWD:ALL` e permissão `0440`
- Valida o arquivo com `visudo -cf` antes de manter — reverte automaticamente se inválido

> **Atenção:** concede privilégio amplo ao usuário. Execute apenas em ambientes controlados.

---

## Opcional - Instalar Docker CE

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/docker.sh | bash
```

Execute este script em máquinas que precisam do Docker — especialmente servidores de laboratório CI/CD.

O script:
- Remove pacotes conflitantes (versões antigas ou do sistema)
- Adiciona o repositório oficial do Docker para Fedora
- Instala `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` e `docker-compose-plugin`
- Inicia e habilita o serviço via `systemctl`
- Adiciona o usuário atual ao grupo `docker` para uso sem sudo

> Após a execução, rode `newgrp docker` ou abra uma nova sessão para aplicar o grupo.

---

## Opcional - Configurar banner de login no TTY

Após aplicar os dotfiles (etapa 4), execute:

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/bootstrap/dotfiles.sh | bash -s issue
```

Configura o `/etc/issue` com um banner ASCII art exibido na tela de login do TTY, com cores Catppuccin Mocha.

> O banner aparece **apenas na tela de login do TTY** — não interfere com terminais abertos após o login.

O comando aplica:
- ASCII art **GARDEN** em mauve (`#cba6f7`)
- Linha com distro, hardware e compositor em blue (`#89b4fa`)
- Separadores em overlay (`#45475a`)

---

## linkr

O `linkr` é o script de aplicação de dotfiles do repositório privado. Ele percorre automaticamente cada app na estrutura do repo e cria symlinks espelhando os caminhos relativos em `$HOME`, sem precisar listar arquivos manualmente.

**Uso:**
```bash
./linkr                   # exibe ajuda e apps disponíveis
./linkr core              # aplica dotfiles essenciais: vim, git, nvim
./linkr desk_hypr         # aplica dotfiles do ambiente Hyprland: hypr, waybar, kitty
./linkr vscodium          # aplica dotfiles do VSCodium: settings.json, tasks.json
./linkr core desk_hypr    # aplica ambos os grupos
./linkr all               # aplica todos os apps disponíveis
./linkr waybar            # aplica um app individual
./linkr issue             # configura o banner de login no TTY (/etc/issue)
```

**Filosofia:** cada app ocupa uma pasta no repo que espelha a estrutura do `$HOME`. O `linkr` percorre os arquivos com `find` recursivo e cria o symlink correspondente para cada um.

```
dotfile/waybar/.config/waybar/config.jsonc  →  ~/.config/waybar/config.jsonc
dotfile/hypr/.config/hypr/hyprland.conf     →  ~/.config/hypr/hyprland.conf
dotfile/vim/.vim/vimrc                      →  ~/.vim/vimrc
```

Se um symlink já existir e apontar para o caminho correto, ele é ignorado. Se existir um arquivo ou link diferente no destino, ele é removido antes de criar o novo.

**Grupos disponíveis:**

| Grupo | Apps |
|-------|------|
| `core` | `vim`, `git`, `nvim`, `ssh` |
| `desk_hypr` | `hypr`, `waybar`, `kitty` |
| `vscodium` | `.config/VSCodium/User/settings.json`, `.config/VSCodium/User/tasks.json` |
| `vscode` | `.config/Code/User/settings.json`, `.config/Code/User/tasks.json` |

> O comando `issue` é desacoplado de todos os grupos — inclusive do `all` — e deve ser executado explicitamente. Ele escreve em `/etc/issue` e requer `sudo`.

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

## Estrutura do repositório
```
dotstrap/              # repositório público
├── bootstrap/
│   ├── system.sh               # Etapa 1: update do sistema e instalação de pacotes
│   ├── ssh_keys.sh             # Etapa 2: gera chaves SSH para GitHub e GitLab
│   ├── desktop.sh              # Etapa 3: instala Hyprland e ambiente gráfico
│   ├── dotfiles.sh             # Etapa 4: clone dos dotfiles e execução do linkr
│   └── headless.sh             # Opcional: configura sistema para uso headless/servidor
└── tools/
    ├── luks_keyfile.sh         # Opcional: unlock automático do LUKS2 via keyfile no initramfs
    ├── luks_tpm.sh             # Referência: unlock via TPM2
    ├── cleanup_desktop.sh      # Opcional: remove i3, XFCE, LightDM e configura multi-user.target
    ├── docker.sh               # Opcional: instala Docker CE no Fedora 43
    ├── grub_resolution.sh      # Opcional: detecta monitor externo e força resolução no TTY/GRUB
    ├── kubectl.sh              # Opcional: instala kubectl (versão stable oficial)
    ├── vscode.sh               # Opcional: instala VS Code no Fedora (repositório oficial Microsoft)
    ├── ssh_authorize.sh        # Opcional: gera chave e autoriza acesso SSH aos servidores do homelab
    └── sudo_nopasswd.sh        # Opcional: configura sudo sem senha para o usuário atual

dotfile/                        # repositório privado
├── linkr                       # gerenciador de dotfiles (core, desk_hypr, vscodium, vscode, all, issue)
├── scripts/
│   ├── setup_issue.sh          # banner ASCII art Catppuccin Mocha no TTY login
│   ├── vscodium.sh             # instalação de extensões do VSCodium
│   ├── vscode.sh               # instalação de extensões do VS Code
│   └── sync_git.sh             # auto commit e push dos repositórios pessoais
├── vscodium/
│   └── .config/
│       └── VSCodium/
│           └── User/
│               ├── settings.json   # configurações, tema e keybindings vim
│               └── tasks.json      # task sync git (<leader>gs)
├── vscode/
│   └── .config/
│       └── Code/
│           └── User/
│               ├── settings.json   # configurações, tema e keybindings vim
│               └── tasks.json      # task sync git (<leader>gs)
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
│   └── .config/
│       └── nvim/
│           ├── init.lua
│           └── lua/
│               ├── config/
│               │   ├── keymaps.lua
│               │   ├── lazy.lua
│               │   └── options.lua
│               └── plugins/
│                   ├── catppuccin.lua
│                   ├── devicons.lua
│                   ├── gitsigns.lua
│                   ├── lualine.lua
│                   ├── nvim-tree.lua
│                   ├── plenary.lua
│                   ├── telescope.lua
│                   ├── toggleterm.lua
│                   ├── tokyonight.lua
│                   └── treesitter.lua
├── waybar/
│   └── .config/
│       └── waybar/
│           ├── config.jsonc
│           └── style.css
├── hypr/
│   └── .config/
│       └── hypr/
│           ├── hyprland.conf
│           ├── hyprlock.conf
│           ├── hypridle.conf
│           └── mocha.conf
└── kitty/
    └── .config/
        └── kitty/
            └── kitty.conf
```

---

## Requisitos
- Sistema baseado em **RHEL/Fedora** (usa `dnf`)
- Acesso `sudo`
- `curl` e `bash` disponíveis no sistema base

---

## Licença
MIT
