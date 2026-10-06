#!/usr/bin/env python3
"""Offline preview of the live wallpaper's terrain for a given gain/knee
and phase, using the same maths as the shader (no colours/dots)."""
import math
import sys

import cairo
import numpy as np
from PIL import Image

W, H = 960, 600
GAIN, CAP, PHASE = float(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3])
OUT = sys.argv[4]
SIZE, ROWS, PEAK_X, SPAN = 512, 72, 0.60, 0.5

rng = np.random.default_rng(7)


def lp(sx, sy):
    n = rng.standard_normal((SIZE, SIZE))
    F = np.fft.rfft2(n)
    fy = np.fft.fftfreq(SIZE)[:, None] * SIZE
    fx = np.fft.rfftfreq(SIZE)[None, :] * SIZE
    F *= np.exp(-((fy / sy) ** 2 + (fx / sx) ** 2) / 2)
    f = np.fft.irfft2(F, s=(SIZE, SIZE))
    return f / np.abs(f).max()


field = (lp(3, 6) + 0.38 * lp(8, 16) + 0.07 * lp(22, 44)) * GAIN
KNEE, RANGE = 0.30, 0.20
field = np.where(field > KNEE, KNEE + (field - KNEE) / (1 + (field - KNEE) / RANGE), field)
uu = np.linspace(0, 1, SIZE)

surf = cairo.ImageSurface(cairo.FORMAT_RGB24, W, H)
cr = cairo.Context(surf)
cr.set_source_rgb(0.05, 0.07, 0.11)
cr.paint()
for i in range(ROWS):
    t = i / (ROWS - 1)
    base = 0.60 + 0.46 * t ** 1.7
    amp = 0.44 * (0.55 + 0.75 * t)
    fr = (t * SPAN - PHASE) % 1
    row = field[int(fr * SIZE) % SIZE]
    env = (0.10 + np.exp(-((uu - PEAK_X) / 0.21) ** 2)) * (0.25 + math.exp(-((t - 0.42) / 0.30) ** 2))
    h = np.clip(row + 0.22, 0, None) ** 1.35 * env
    if CAP > 0:
        h = h / (1 + h / CAP)
    spread = 1.05 + 0.95 * t
    xs = W * (PEAK_X + (uu - PEAK_X) * spread)
    ys = H * (base - h * amp)
    cr.move_to(xs[0], ys[0])
    for x, y in zip(xs[1:], ys[1:]):
        cr.line_to(x, y)
    path = cr.copy_path()
    cr.line_to(xs[-1], H + 5)
    cr.line_to(xs[0], H + 5)
    cr.close_path()
    cr.set_source_rgb(0.05, 0.07, 0.11)
    cr.fill()
    cr.append_path(path)
    a = 0.18 + 0.82 * max(0.0, math.sin(math.pi * min(1.0, t * 1.08))) ** 0.8
    cr.set_source_rgba(0.45, 0.72, 0.98, a)
    cr.set_line_width(0.9)
    cr.stroke()
surf.write_to_png(OUT)
