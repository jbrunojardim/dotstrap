#!/usr/bin/env bash
set -euo pipefail

if ! command -v edid-decode &>/dev/null; then
    echo "edid-decode not found. Installing..."
    sudo dnf install -y edid-decode
fi

# Find first connected external connector (non-eDP)
CONNECTOR=""
for status_file in /sys/class/drm/card?-*/status; do
    connector_path="${status_file%/status}"
    connector_name="${connector_path##*/card?-}"
    if [[ "$connector_name" == eDP* ]]; then
        continue
    fi
    if [[ "$(cat "$status_file")" == "connected" ]]; then
        CONNECTOR="$connector_path"
        CONNECTOR_NAME="$connector_name"
        break
    fi
done

if [[ -z "$CONNECTOR" ]]; then
    echo "No external monitor connected. Aborting."
    exit 1
fi

echo "Found connected monitor: $CONNECTOR_NAME"

EDID_FILE="$CONNECTOR/edid"
if [[ ! -r "$EDID_FILE" ]] || [[ "$(wc -c < "$EDID_FILE")" -eq 0 ]]; then
    echo "EDID not readable at $EDID_FILE. Aborting."
    exit 1
fi

# Extract preferred resolution from DTD 1
RESOLUTION=$(edid-decode "$EDID_FILE" 2>/dev/null | grep "DTD 1:" | grep -oP '\d+x\d+' | head -1)

if [[ -z "$RESOLUTION" ]]; then
    echo "Could not extract resolution from EDID. Aborting."
    exit 1
fi

echo "Preferred resolution: $RESOLUTION"

GRUB_FILE="/etc/default/grub"

# Remove existing video= parameters to avoid duplicates
sudo sed -i 's/ video=[^ "]*//g' "$GRUB_FILE"

# Inject video= into GRUB_CMDLINE_LINUX
sudo sed -i "s|^GRUB_CMDLINE_LINUX=\"\(.*\)\"|GRUB_CMDLINE_LINUX=\"\1 video=${CONNECTOR_NAME}:${RESOLUTION}\"|" "$GRUB_FILE"

# Set GRUB framebuffer resolution
if grep -q "^GRUB_GFXMODE=" "$GRUB_FILE"; then
    sudo sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE=${RESOLUTION}|" "$GRUB_FILE"
else
    echo "GRUB_GFXMODE=${RESOLUTION}" | sudo tee -a "$GRUB_FILE" >/dev/null
fi

if grep -q "^GRUB_GFXPAYLOAD_LINUX=" "$GRUB_FILE"; then
    sudo sed -i "s|^GRUB_GFXPAYLOAD_LINUX=.*|GRUB_GFXPAYLOAD_LINUX=keep|" "$GRUB_FILE"
else
    echo "GRUB_GFXPAYLOAD_LINUX=keep" | sudo tee -a "$GRUB_FILE" >/dev/null
fi

echo "Updated $GRUB_FILE:"
grep -E "GRUB_CMDLINE_LINUX|GRUB_GFXMODE|GRUB_GFXPAYLOAD" "$GRUB_FILE"

echo ""
echo "Regenerating GRUB config..."
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

echo ""
echo "Done. Reboot to apply the new TTY resolution."
