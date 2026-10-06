#!/bin/bash
# Installs the Glacier boot splash and rebuilds the initramfs. Run with sudo.
# Undo: sudo update-alternatives --set default.plymouth \
#         /usr/share/plymouth/themes/kubuntu-logo/kubuntu-logo.plymouth && sudo update-initramfs -u
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo."; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)/plymouth"
DEST=/usr/share/plymouth/themes/glacier

for f in glacier.plymouth glacier.script glacier.grub logo.png track.png runner.png; do
    [ -f "$SRC/$f" ] || { echo "missing $SRC/$f (run plymouth/gen-images.py)"; exit 1; }
done

install -d -m 755 "$DEST"
install -m 644 "$SRC"/glacier.plymouth "$SRC"/glacier.script "$SRC"/glacier.grub "$SRC"/*.png "$DEST"/

update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
    "$DEST/glacier.plymouth" 200 \
    --slave /usr/share/plymouth/themes/default.grub default.plymouth.grub "$DEST/glacier.grub"
update-alternatives --set default.plymouth "$DEST/glacier.plymouth"
update-initramfs -u

echo "Glacier boot splash installed; you will see it on the next boot."
