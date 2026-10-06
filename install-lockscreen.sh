#!/bin/bash
# Installs the Glacier lock screen. Run with sudo.
#
# Plasma 6 loads the lock screen from the desktop shell package
# (org.kde.plasma.desktop), not from the global theme, and the package name
# is shared with plasmashell itself. So the one file is replaced in place,
# with a dpkg diversion so plasma-desktop upgrades keep our copy.
#
# Undo: sudo rm "$TARGET" && sudo dpkg-divert --local --remove --rename "$TARGET"
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo."; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)/lockscreen/LockScreen.qml"
TARGET=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreen.qml

[ -f "$SRC" ] || { echo "Theme source not found at $SRC"; exit 1; }
[ -e "$TARGET" ] || [ -e "$TARGET.breeze" ] || { echo "Plasma lock screen not found at $TARGET"; exit 1; }

if ! dpkg-divert --list "$TARGET" | grep -q .; then
    dpkg-divert --local --add --rename --divert "$TARGET.breeze" "$TARGET"
fi
install -m 644 "$SRC" "$TARGET"

echo "Glacier lock screen installed (original kept at $TARGET.breeze)."
echo "Preview without locking:  kscreenlocker_greet --testing"
echo "Lock for real:            loginctl lock-session"
