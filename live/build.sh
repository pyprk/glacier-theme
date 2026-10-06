#!/bin/bash
# Regenerates the live wallpaper's texture and shader, then compiles the shader with qsb.
set -euo pipefail
cd "$(dirname "$0")"
export PATH="$PATH:/usr/lib/qt6/bin"
command -v qsb >/dev/null || { echo "qsb not found: sudo apt install qt6-shader-baker"; exit 1; }
python3 gen.py
OUT=~/.local/share/plasma/wallpapers/com.ryan.glacier.live/contents/shaders
mkdir -p "$OUT"
qsb --glsl "300 es,150" -o "$OUT/terrain.frag.qsb" terrain.frag
echo "compiled $OUT/terrain.frag.qsb"
