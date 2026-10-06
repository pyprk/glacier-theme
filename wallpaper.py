#!/usr/bin/env python3
"""Glacier wallpaper: a wireframe ridge-line terrain over a dark slate sky.
Usage: wallpaper.py WIDTH HEIGHT OUT.png [seed]"""
import math
import sys

import cairo
import numpy as np
from PIL import Image

W, H = int(sys.argv[1]), int(sys.argv[2])
OUT = sys.argv[3]
SEED = int(sys.argv[4]) if len(sys.argv) > 4 else 7
S = W / 3840  # stroke scale

ROWS, COLS = 78, 700
PEAK_X = 0.60

rng = np.random.default_rng(SEED)


def lowpass(sigma):
    n = rng.standard_normal((ROWS, COLS))
    F = np.fft.rfft2(n)
    fy = np.fft.fftfreq(ROWS)[:, None] * ROWS
    fx = np.fft.rfftfreq(COLS)[None, :] * COLS
    F *= np.exp(-(fy ** 2 + fx ** 2) / (2 * sigma ** 2))
    f = np.fft.irfft2(F, s=(ROWS, COLS))
    return f / np.abs(f).max()


field = lowpass(3.0) + 0.38 * lowpass(8.0) + 0.07 * lowpass(22.0)
u = np.linspace(0, 1, COLS)[None, :]
r = np.linspace(0, 1, ROWS)[:, None]
env = (0.10 + np.exp(-((u - PEAK_X) / 0.21) ** 2)) * (0.25 + np.exp(-((r - 0.42) / 0.30) ** 2))
height = np.clip(field + 0.22, 0, None) ** 1.35 * env

surf = cairo.ImageSurface(cairo.FORMAT_RGB24, W, H)
cr = cairo.Context(surf)

# sky
sky = cairo.LinearGradient(0, 0, 0, H)
sky.add_color_stop_rgb(0.0, 9 / 255, 13 / 255, 20 / 255)
sky.add_color_stop_rgb(0.55, 13 / 255, 19 / 255, 29 / 255)
sky.add_color_stop_rgb(1.0, 15 / 255, 23 / 255, 36 / 255)
cr.set_source(sky)
cr.paint()

# glow behind the ridge
glow = cairo.RadialGradient(PEAK_X * W, 0.52 * H, 0, PEAK_X * W, 0.52 * H, 0.46 * W)
glow.add_color_stop_rgba(0, 86 / 255, 164 / 255, 245 / 255, 0.16)
glow.add_color_stop_rgba(0.5, 60 / 255, 120 / 255, 210 / 255, 0.05)
glow.add_color_stop_rgba(1, 0, 0, 0, 0)
cr.set_source(glow)
cr.paint()

# dot grid, fading out toward the horizon
step = W / 64
y = step / 2
while y < 0.62 * H:
    fade = max(0.0, 1 - y / (0.62 * H)) ** 1.2
    x = step / 2
    ix = 0
    while x < W:
        iy = round(y / step)
        if ix % 8 == 0 and iy % 8 == 0:
            cr.set_source_rgba(111 / 255, 205 / 255, 245 / 255, 0.32 * fade)
            cr.set_line_width(1.4 * S)
            a = 7 * S
            cr.move_to(x - a, y); cr.line_to(x + a, y)
            cr.move_to(x, y - a); cr.line_to(x, y + a)
            cr.stroke()
        else:
            cr.set_source_rgba(160 / 255, 190 / 255, 230 / 255, 0.085 * fade)
            cr.arc(x, y, 1.7 * S, 0, 2 * math.pi)
            cr.fill()
        x += step
        ix += 1
    y += step


def lerp(a, b, t):
    return a + (b - a) * t


# ridge lines, far to near
for i in range(ROWS):
    t = i / (ROWS - 1)
    base = H * (0.60 + 0.46 * t ** 1.7)
    amp = H * 0.44 * (0.55 + 0.75 * t)
    spread = 1.05 + 0.95 * t
    xs = W * (PEAK_X + (u[0] - PEAK_X) * spread)
    ys = base - height[i] * amp

    cr.new_path()
    cr.move_to(xs[0], ys[0])
    for x_, y_ in zip(xs[1:], ys[1:]):
        cr.line_to(x_, y_)
    path = cr.copy_path()

    # occlude what is behind
    cr.line_to(xs[-1], H + 10)
    cr.line_to(xs[0], H + 10)
    cr.close_path()
    cr.set_source(sky)
    cr.fill()

    # brightness peaks mid-depth, fades at the horizon and the bottom edge
    depth = math.sin(math.pi * min(1.0, t * 1.08)) ** 0.8
    alpha = 0.18 + 0.82 * depth
    col = [lerp(a, b, t) for a, b in zip((52, 96, 160), (96, 176, 248))]
    cx = PEAK_X * W
    for width, k in ((8.0, 0.12), (2.2, 1.0)):
        g = cairo.LinearGradient(cx - 0.62 * W, 0, cx + 0.62 * W, 0)
        g.add_color_stop_rgba(0.0, col[0] / 255, col[1] / 255, col[2] / 255, 0)
        g.add_color_stop_rgba(0.28, col[0] / 255, col[1] / 255, col[2] / 255, alpha * k * 0.55)
        g.add_color_stop_rgba(0.5, 140 / 255, 215 / 255, 250 / 255, alpha * k)
        g.add_color_stop_rgba(0.72, col[0] / 255, col[1] / 255, col[2] / 255, alpha * k * 0.55)
        g.add_color_stop_rgba(1.0, col[0] / 255, col[1] / 255, col[2] / 255, 0)
        cr.new_path()
        cr.append_path(path)
        cr.set_source(g)
        cr.set_line_width(width * S * (0.7 + 0.6 * t))
        cr.set_line_join(cairo.LINE_JOIN_ROUND)
        cr.stroke()

surf.flush()
arr = np.ndarray((H, W, 4), dtype=np.uint8, buffer=surf.get_data())[:, :, 2::-1].astype(np.float32)
# light dither so the gradients do not band
arr += np.random.default_rng(1).uniform(-1.2, 1.2, (H, W, 1))
Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).save(OUT)
print("wrote", OUT)
