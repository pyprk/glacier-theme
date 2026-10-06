#!/bin/bash
# Installs the Glacier login screen (SDDM theme). Run with sudo.
# Undo: sudo rm /etc/sddm.conf.d/30-glacier.conf
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo."; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)/sddm"
DEST=/usr/share/sddm/themes/glacier

[ -f "$SRC/Main.qml" ] || { echo "Theme source not found at $SRC"; exit 1; }

rm -rf "$DEST"
install -d -m 755 "$DEST"
install -m 644 "$SRC"/* "$DEST"/

cat > /etc/sddm.conf.d/30-glacier.conf <<'CONF'
[Theme]
Current=glacier
Font=IBM Plex Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
CONF

echo "Glacier login screen installed. It appears the next time you log out or reboot."
