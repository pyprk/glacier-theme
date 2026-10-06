#!/bin/bash
# Applies the Glacier theme to the running Plasma session.
set -u
FONT_UI="IBM Plex Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
FONT_SMALL="IBM Plex Sans,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
FONT_TITLE="IBM Plex Sans,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1"
FONT_MONO="IBM Plex Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
WALL="$HOME/.local/share/wallpapers/Glacier"
LAYOUT="$HOME/.local/share/plasma/look-and-feel/com.ryan.glacier/contents/layouts/org.kde.plasma.desktop-layout.js"

kbuildsycoca6 >/dev/null 2>&1

plasma-apply-colorscheme Glacier
plasma-apply-desktoptheme Glacier
/usr/lib/x86_64-linux-gnu/libexec/plasma-changeicons breeze-dark
plasma-apply-cursortheme breeze_cursors

for key in font menuFont toolBarFont; do
    kwriteconfig6 --file kdeglobals --group General --key $key "$FONT_UI"
done
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "$FONT_SMALL"
kwriteconfig6 --file kdeglobals --group General --key fixed "$FONT_MONO"
kwriteconfig6 --file kdeglobals --group WM --key activeFont "$FONT_TITLE"
dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:1 int32:0

# window decoration: Breeze, borderless, centred title, soft outline
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSize None
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file breezerc --group Common --key OutlineIntensity OutlineLow
kwriteconfig6 --file breezerc --group Common --key ShadowSize ShadowLarge
kwriteconfig6 --file breezerc --group Windeco --key TitleAlignment AlignCenterFullWidth
kwriteconfig6 --file breezerc --group Windeco --key DrawBackgroundGradient false
qdbus6 org.kde.KWin /KWin reconfigure

kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Glacier.profile
kwriteconfig6 --file ksplashrc --group KSplash --key Theme com.ryan.glacier
kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALL"
kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image

if [ "${1:-}" != "--no-layout" ]; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$LAYOUT")"
fi
