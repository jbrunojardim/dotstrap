# Unlock automático do LUKS2 via keyfile

Elimina a necessidade de digitar a senha a cada boot em máquinas com disco criptografado (LUKS2).

> **IMPORTANTE:** a senha LUKS original continua válida como recovery. Guarde-a em local seguro — sem ela não há como recuperar o acesso caso o initramfs seja corrompido ou o keyfile removido.

---

## Pré-requisitos

- Disco com partição LUKS2 (`cryptsetup`)
- `dracut` disponível (padrão em Fedora/RHEL/Rocky)
- Acesso root

---

## Passo a passo

### 1. Identificar a partição LUKS

```bash
lsblk -o NAME,FSTYPE | grep crypto_LUKS
```

Anote o device — ex: `/dev/nvme0n1p3` ou `/dev/sda3`.

### 2. Obter o UUID

```bash
sudo blkid -s UUID -o value /dev/<device>
```

### 3. Gerar o keyfile

```bash
sudo mkdir -p /etc/cryptsetup-keys.d
sudo dd if=/dev/urandom of=/etc/cryptsetup-keys.d/luks-<UUID>.key bs=512 count=1
sudo chmod 0400 /etc/cryptsetup-keys.d/luks-<UUID>.key
```

### 4. Adicionar o keyfile ao LUKS

```bash
sudo cryptsetup luksAddKey /dev/<device> /etc/cryptsetup-keys.d/luks-<UUID>.key
```

Vai pedir a senha atual do LUKS. Confirma que o slot foi criado:

```bash
sudo cryptsetup luksDump /dev/<device> | grep "^  [0-9]:"
```

Deve aparecer slot 0 (senha) e slot 1 (keyfile).

### 5. Configurar o dracut para incluir o keyfile no initramfs

```bash
echo 'install_items+=" /etc/cryptsetup-keys.d/* "' | sudo tee /etc/dracut.conf.d/luks-keys.conf
```

### 6. Atualizar o /etc/crypttab

Substitua `none` pelo caminho do keyfile na linha correspondente ao UUID:

```bash
sudo vi /etc/crypttab
```

A linha deve ficar assim:

```
luks-<UUID>  UUID=<UUID>  /etc/cryptsetup-keys.d/luks-<UUID>.key  discard
```

### 7. Regenerar o initramfs

```bash
sudo dracut -fv
```

### 8. Reiniciar e validar

```bash
sudo reboot
```

O boot deve ocorrer sem pedir senha.

---

## Troubleshooting

### Boot ainda pede senha

Verifique se o slot foi adicionado corretamente:

```bash
sudo cryptsetup luksDump /dev/<device> | grep "^  [0-9]:"
```

Se só aparecer o slot 0, o `luksAddKey` não foi executado — repita o passo 4.

Verifique o `crypttab`:

```bash
sudo cat /etc/crypttab
```

A terceira coluna deve ser o caminho do keyfile, não `none`.

Verifique os logs do boot:

```bash
sudo journalctl -b | grep -i "crypt\|luks\|keyfile"
```

### Remover o keyfile e voltar à senha

```bash
sudo cryptsetup luksKillSlot /dev/<device> 1
sudo rm /etc/cryptsetup-keys.d/luks-<UUID>.key
```

Reverta o `/etc/crypttab` para `none` e regenere o initramfs.

---

← [Voltar ao README](../README.md)
