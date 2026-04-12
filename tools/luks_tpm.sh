#!/usr/bin/env bash
set -euo pipefail

log()  { printf "\n==> %s\n" "$*"; }
warn() { printf "\n    [aviso] %s\n" "$*"; }
die()  { printf "\n[ERRO] %s\n" "$*" >&2; exit 1; }

# ─── Verificação de root ───────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  die "Execute este script com sudo: sudo bash bootstrap_luks_tpm.sh"
fi

# ─── Detectar partição LUKS automaticamente ───────────────────────────────────
log "Detectando partição LUKS"
LUKS_DEVICE=$(lsblk --raw -o NAME,TYPE,FSTYPE | awk '/crypto_LUKS/ {print "/dev/" $1}')

if [[ -z "$LUKS_DEVICE" ]]; then
  die "Nenhuma partição LUKS encontrada. Verifique com: lsblk -o NAME,FSTYPE"
fi
log "Partição LUKS detectada: ${LUKS_DEVICE}"

# ─── Verificar se TPM2 já está enrollado ──────────────────────────────────────
log "Verificando enrollments existentes no LUKS"
if systemd-cryptenroll --tpm2-device=auto "$LUKS_DEVICE" 2>/dev/null | grep -q "tpm2"; then
  warn "TPM2 já está enrollado em ${LUKS_DEVICE}."
  warn "Para re-enrollar, remova primeiro: systemd-cryptenroll --wipe-slot=tpm2 ${LUKS_DEVICE}"
  exit 0
fi

# ─── Garantir módulo tpm_crb carregado ────────────────────────────────────────
log "Verificando módulo tpm_crb"
if ! lsmod | grep -q "^tpm_crb"; then
  warn "tpm_crb não carregado — carregando agora"
  modprobe tpm_crb
  log "tpm_crb carregado"
else
  log "tpm_crb já carregado"
fi

# Persistir módulo no boot
MODULES_FILE="/etc/modules-load.d/tpm_crb.conf"
if [[ ! -f "$MODULES_FILE" ]]; then
  echo "tpm_crb" > "$MODULES_FILE"
  log "tpm_crb persistido em ${MODULES_FILE}"
else
  log "tpm_crb já persistido em ${MODULES_FILE}"
fi

# ─── Verificar presença do dispositivo TPM2 ───────────────────────────────────
log "Verificando dispositivo TPM2"
if [[ ! -e /dev/tpm0 ]]; then
  die "TPM2 não disponível em /dev/tpm0. Verifique se o TPM está habilitado na BIOS."
fi
log "TPM2 disponível: /dev/tpm0"

# ─── Detectar Secure Boot e definir PCRs ──────────────────────────────────────
log "Detectando estado do Secure Boot"
if mokutil --sb-state 2>/dev/null | grep -q "enabled"; then
  PCRS="0+7"
  log "Secure Boot: enabled — usando PCRs ${PCRS} (firmware + Secure Boot state)"
else
  PCRS="0"
  log "Secure Boot: disabled — usando PCR ${PCRS} (firmware apenas)"
fi

# ─── Solicitar senha LUKS ─────────────────────────────────────────────────────
log "Informe a senha atual do LUKS para adicionar o slot TPM2"
printf "Senha LUKS: "
read -rs LUKS_PASSWORD </dev/tty
printf "\n"

if [[ -z "$LUKS_PASSWORD" ]]; then
  die "Senha não pode ser vazia."
fi

# Validar senha antes de prosseguir
log "Validando senha LUKS"
if ! echo "$LUKS_PASSWORD" | cryptsetup luksOpen --test-passphrase "$LUKS_DEVICE" 2>/dev/null; then
  die "Senha incorreta para ${LUKS_DEVICE}."
fi
log "Senha validada com sucesso"

# ─── Enrollar TPM2 no LUKS ────────────────────────────────────────────────────
log "Enrollando TPM2 em ${LUKS_DEVICE} com PCRs ${PCRS}"
echo "$LUKS_PASSWORD" | systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs="$PCRS" \
  --unlock-key-type=password \
  "$LUKS_DEVICE"

log "TPM2 enrollado com sucesso"

# Limpar senha da memória
unset LUKS_PASSWORD

# ─── Regenerar initramfs ──────────────────────────────────────────────────────
log "Regenerando initramfs com dracut"
dracut -fv
log "initramfs regenerado"

# ─── Conclusão ────────────────────────────────────────────────────────────────
echo ""
log "[bootstrap_luks_tpm] Configuração concluída com sucesso!"
echo ""
echo "    Resumo:"
echo "      - Partição LUKS:  ${LUKS_DEVICE}"
echo "      - TPM2:           enrollado"
echo "      - PCRs:           ${PCRS}"
echo "      - tpm_crb:        persistido em /etc/modules-load.d/tpm_crb.conf"
echo "      - initramfs:      regenerado"
echo ""
echo "    IMPORTANTE: a senha LUKS original continua válida como recovery."
echo "    Guarde-a em local seguro — sem ela não há como recuperar o acesso"
echo "    caso o TPM2 seja invalidado (ex: update de firmware, troca de placa)."
echo ""
echo "    Recomendado: reiniciar e validar que o boot ocorre sem pedir senha."
echo ""
