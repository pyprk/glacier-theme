#!/bin/bash
# Installs the Glacier boot splash (Plymouth theme). Run with sudo.
# Undo: sudo update-alternatives --set default.plymouth \
#         /usr/share/plymouth/themes/kubuntu-logo/kubuntu-logo.plymouth && sudo update-initramfs -u
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo."; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)/plymouth"
DEST=/usr/share/plymouth/themes/glacier
PLUGINS=/usr/lib/x86_64-linux-gnu/plymouth

for f in glacier.plymouth glacier.script glacier.grub logo.png track.png bar.png entry.png bullet.png; do
    [ -f "$SRC/$f" ] || { echo "missing $SRC/$f (run plymouth/render.py)"; exit 1; }
done
command -v plymouth >/dev/null || { echo "plymouth is not installed."; exit 1; }

# script.so ships with plymouth; text (fsck messages, disk password prompts)
# needs the label plugin from plymouth-label.
[ -f "$PLUGINS/script.so" ] || { echo "plymouth script module missing at $PLUGINS/script.so"; exit 1; }
if ! ls "$PLUGINS"/label*.so >/dev/null 2>&1; then
    echo "Installing plymouth-label (text rendering in the splash)..."
    apt-get install -y plymouth-label
fi

rm -rf "$DEST"
install -d -m 755 "$DEST"
install -m 644 "$SRC"/glacier.plymouth "$SRC"/glacier.script "$SRC"/glacier.grub "$SRC"/*.png "$DEST"/

# Ubuntu's initramfs hook picks the theme from the default.plymouth alternative;
# the .grub slave gives GRUB the same background colour.
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
    "$DEST/glacier.plymouth" 200 \
    --slave /usr/share/plymouth/themes/default.grub default.plymouth.grub "$DEST/glacier.grub"
update-alternatives --set default.plymouth "$DEST/glacier.plymouth"

if ! grep -qsE '^\s*GRUB_CMDLINE_LINUX_DEFAULT=.*\bsplash\b' /etc/default/grub; then
    echo "Note: 'splash' is not in GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub;"
    echo "      Plymouth will not show at boot until it is added (then: sudo update-grub)."
fi

echo "Rebuilding initramfs..."
update-initramfs -u
update-grub

echo "Glacier boot splash installed. It appears on the next reboot."
echo "Preview without rebooting (shows the splash for 8 s):"
echo "  sudo plymouthd; sudo plymouth --show-splash; sleep 8; sudo plymouth quit"
