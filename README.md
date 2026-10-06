# Glacier

A from-scratch dark Plasma 6 theme: blue-slate colour scheme, wireframe
terrain wallpaper (static and live/animated), HUD and server widgets,
login screen, splash, Konsole profile, bash prompt and fastfetch banner.

    ./install.sh                 # link into ~/.local/share and apply
    sudo ./install-login.sh      # SDDM login screen
    sudo ./install-lockscreen.sh # lock screen (replaces Plasma's, via dpkg-divert)
    sudo ./install-plymouth.sh   # boot splash (rebuilds the initramfs)

| Path | What |
|---|---|
| `build.py` | palette → colour scheme, Plasma style, Konsole profile |
| `wallpaper.py` | renders the static wallpaper |
| `live/` | animated wallpaper plugin: `gen.py` makes the field texture + shader, `build.sh` compiles it |
| `plasma/` | widgets (`hud`, `servers`), live wallpaper plugin, global theme package |
| `sddm/` | login screen theme |
| `lockscreen/` | lock screen, same layout as the login screen |
| `plymouth/` | boot splash: `render.py` draws the images, `glacier.script` animates them |
| `shell/` | bash prompt, fastfetch config, example server list |
| `apply.sh` | re-applies everything to the running session |

The DEADFRAME mark (mono text in a frame with its bottom-right corner
missing) sits on the login, lock and boot screens, the wallpaper corner and
the fastfetch banner. The chaos budget is small and rare on purpose: the big
clocks tear for 80 ms every half minute or so, one ridge of the live
wallpaper skips sideways for two frames (`Chaos` in the wallpaper settings),
the splash logo twitches, and one prompt in twenty wears the frame's corner.

After changing the live wallpaper shader: `live/build.sh` then
`systemctl --user restart plasma-plasmashell.service` (Plasma caches shaders).
