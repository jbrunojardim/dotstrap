#!/usr/bin/env bash
set -euo pipefail

log()  { printf "\n==> %s\n" "$*"; }
warn() { printf "\n    [aviso] %s\n" "$*"; }
die()  { printf "\n[ERRO] %s\n" "$*" >&2; exit 1; }

DIR_LUKS="/etc/cryptsetup-keys.d"
DIR_DRAC="/etc/dracut.conf.d"
FILE_DRAC="luks-keys.conf"
PASSWORD_FILE="/tmp/luks_pass_tmp"

# ─── Verificação de root ───────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  die "Execute este script com sudo: curl ... | sudo bash"
fi

# ─── Detectar partição LUKS automaticamente ───────────────────────────────────
log "Detectando partição LUKS"
LUKS_DEVICE=$(lsblk --raw -o NAME,TYPE,FSTYPE | awk '/crypto_LUKS/ {print "/dev/" $1}')

if [[ -z "$LUKS_DEVICE" ]]; then
  die "Nenhuma partição LUKS encontrada. Verifique com: lsblk -o NAME,FSTYPE"
fi
log "Partição LUKS detectada: ${LUKS_DEVICE}"

# ─── Obter UUID da partição LUKS ──────────────────────────────────────────────
log "Obtendo UUID da partição LUKS"
LUKS_UUID=$(blkid | awk '/crypto_LUKS/ {gsub("UUID=|\"", ""); print $2}')

if [[ -z "$LUKS_UUID" ]]; then
  die "Não foi possível obter o UUID de ${LUKS_DEVICE}."
fi
log "UUID: ${LUKS_UUID}"

KEYFILE="${DIR_LUKS}/luks-${LUKS_UUID}.key"

# ─── Verificar se keyfile já existe ───────────────────────────────────────────
if [[ -f "$KEYFILE" ]]; then
  warn "Keyfile já existe: ${KEYFILE}"
  warn "Para re-criar, remova o arquivo e execute novamente."
  exit 0
fi

# ─── Solicitar senha LUKS ─────────────────────────────────────────────────────
log "Informe a senha atual do LUKS"
printf "Senha LUKS: "
read -rs LUKS_PASSWORD </dev/tty
printf "\n"

if [[ -z "$LUKS_PASSWORD" ]]; then
  die "Senha não pode ser vazia."
fi

# ─── Validar senha ────────────────────────────────────────────────────────────
log "Validando senha LUKS"
if ! echo "$LUKS_PASSWORD" | cryptsetup luksOpen --test-passphrase "$LUKS_DEVICE"; then
  die "Senha incorreta para ${LUKS_DEVICE}."
fi
log "Senha validada com sucesso"

# ─── Criar diretórios ─────────────────────────────────────────────────────────
log "Criando diretórios necessários"
mkdir -p "$DIR_LUKS" "$DIR_DRAC"

# ─── Criar keyfile com dados aleatórios ───────────────────────────────────────
log "Gerando keyfile: ${KEYFILE}"
dd if=/dev/urandom of="$KEYFILE" bs=512 count=1 status=none
chmod 0400 "$KEYFILE"
log "Keyfile gerado com permissão 0400"

# ─── Configurar dracut para incluir o keyfile no initramfs ────────────────────
log "Configurando dracut para incluir keyfile no initramfs"
echo 'install_items+=" /etc/cryptsetup-keys.d/* "' > "${DIR_DRAC}/${FILE_DRAC}"
log "Configuração dracut criada: ${DIR_DRAC}/${FILE_DRAC}"

# ─── Criar arquivo temporário com a senha ─────────────────────────────────────
log "Adicionando keyfile ao slot LUKS"
echo "$LUKS_PASSWORD" > "$PASSWORD_FILE"
chmod 0600 "$PASSWORD_FILE"
unset LUKS_PASSWORD

# ─── Adicionar keyfile ao LUKS ────────────────────────────────────────────────
cryptsetup luksAddKey \
  --key-file "$PASSWORD_FILE" \
  "$LUKS_DEVICE" \
  "$KEYFILE"

log "Keyfile adicionado ao LUKS com sucesso"

# ─── Atualizar /etc/crypttab ──────────────────────────────────────────────────
log "Atualizando /etc/crypttab"
CRYPTTAB_NAME="luks-${LUKS_UUID}"
if grep -q "^${CRYPTTAB_NAME}" /etc/crypttab; then
  sed -i "s|^${CRYPTTAB_NAME}.*|${CRYPTTAB_NAME} UUID=${LUKS_UUID} ${KEYFILE} discard|" /etc/crypttab
else
  echo "${CRYPTTAB_NAME} UUID=${LUKS_UUID} ${KEYFILE} discard" >> /etc/crypttab
fi
log "/etc/crypttab atualizado"

# ─── Remover arquivo temporário ───────────────────────────────────────────────
rm -f "$PASSWORD_FILE"
log "Arquivo temporário removido"

# ─── Regenerar initramfs ──────────────────────────────────────────────────────
log "Regenerando initramfs com dracut"
dracut -fv
log "initramfs regenerado"

# ─── Conclusão ────────────────────────────────────────────────────────────────
echo ""
log "[bootstrap_luks_keyfile] Configuração concluída com sucesso!"
echo ""
echo "    Resumo:"
echo "      - Partição LUKS:  ${LUKS_DEVICE}"
echo "      - UUID:           ${LUKS_UUID}"
echo "      - Keyfile:        ${KEYFILE}"
echo "      - dracut conf:    ${DIR_DRAC}/${FILE_DRAC}"
echo "      - initramfs:      regenerado"
echo ""
echo "    IMPORTANTE: a senha LUKS original continua válida como recovery."
echo "    Guarde-a em local seguro — sem ela não há como recuperar o acesso"
echo "    caso o initramfs seja corrompido ou o keyfile removido."
echo ""
echo "    Recomendado: reiniciar e validar que o boot ocorre sem pedir senha."
echo ""
