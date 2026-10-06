#!/bin/bash
# Links the Glacier theme into this user's Plasma config and applies it.
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"
D=~/.local/share
link() { mkdir -p "$(dirname "$1")"; [ -L "$1" ] || [ ! -e "$1" ] || mv "$1" "$1.bak"; ln -sfn "$2" "$1"; }
link $D/plasma/plasmoids/com.ryan.glacier.hud      "$R/plasma/plasmoids/com.ryan.glacier.hud"
link $D/plasma/plasmoids/com.ryan.glacier.servers  "$R/plasma/plasmoids/com.ryan.glacier.servers"
link $D/plasma/wallpapers/com.ryan.glacier.live    "$R/plasma/wallpapers/com.ryan.glacier.live"
link $D/plasma/look-and-feel/com.ryan.glacier      "$R/plasma/look-and-feel/com.ryan.glacier"
link $D/wallpapers/Glacier                         "$R/wallpapers/Glacier"
link $D/icons/hicolor/scalable/apps/glacier-launcher.svg "$R/icons/glacier-launcher.svg"
link ~/.config/glacier/prompt.sh                   "$R/shell/prompt.sh"
link ~/.config/fastfetch                           "$R/shell/fastfetch"
grep -q "glacier/prompt.sh" ~/.bashrc || printf '\n# Glacier prompt and banner\n[ -f ~/.config/glacier/prompt.sh ] && . ~/.config/glacier/prompt.sh\n' >> ~/.bashrc
[ -f ~/.config/glacier/servers.json ] || cp "$R/shell/servers.example.json" ~/.config/glacier/servers.json
python3 "$R/build.py"            # colour scheme, Plasma style, Konsole profile
"$R/live/build.sh" || true       # live wallpaper shader (needs qt6-shader-baker)
"$R/apply.sh"
echo "Login screen: sudo $R/install-login.sh"
