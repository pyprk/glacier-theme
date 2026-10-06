# Glacier

A from-scratch dark Plasma 6 theme: blue-slate colour scheme, wireframe
terrain wallpaper (static and live/animated), HUD and server widgets,
login screen, splash, Konsole profile, bash prompt and fastfetch banner.

    ./install.sh                 # link into ~/.local/share and apply
    sudo ./install-login.sh      # SDDM login screen

| Path | What |
|---|---|
| `build.py` | palette → colour scheme, Plasma style, Konsole profile |
| `wallpaper.py` | renders the static wallpaper |
| `live/` | animated wallpaper plugin: `gen.py` makes the field texture + shader, `build.sh` compiles it |
| `plasma/` | widgets (`hud`, `servers`), live wallpaper plugin, global theme package |
| `sddm/` | login screen theme |
| `shell/` | bash prompt, fastfetch config, example server list |
| `apply.sh` | re-applies everything to the running session |

After changing the live wallpaper shader: `live/build.sh` then
`systemctl --user restart plasma-plasmashell.service` (Plasma caches shaders).
