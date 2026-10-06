#!/usr/bin/env python3
"""Renders the Plymouth theme's images: the hex logo, the progress track
and the runner. Run from the plymouth/ directory."""
import math
from pathlib import Path

import cairo

HERE = Path(__file__).resolve().parent


def logo(size=192):
    s = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    cr = cairo.Context(s)
    cr.scale(size / 64, size / 64)
    cr.set_line_join(cairo.LINE_JOIN_ROUND)
    cr.set_line_cap(cairo.LINE_CAP_ROUND)
    cr.set_line_width(3.2)
    # hexagon
    pts = [(32, 5), (55.4, 18.5), (55.4, 45.5), (32, 59), (8.6, 45.5), (8.6, 18.5)]
    cr.move_to(*pts[0])
    for p in pts[1:]:
        cr.line_to(*p)
    cr.close_path()
    cr.set_source_rgb(86 / 255, 164 / 255, 245 / 255)
    cr.stroke()
    # peaks
    cr.move_to(18, 42)
    for p in [(27.5, 25), (33.5, 35), (38.5, 28), (46, 42)]:
        cr.line_to(*p)
    cr.set_source_rgb(216 / 255, 225 / 255, 238 / 255)
    cr.stroke()
    s.write_to_png(str(HERE / "logo.png"))


def bar(name, w, h, rgb):
    s = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    cr = cairo.Context(s)
    cr.set_source_rgb(*[c / 255 for c in rgb])
    cr.rectangle(0, 0, w, h)
    cr.fill()
    s.write_to_png(str(HERE / name))


logo()
bar("track.png", 180, 2, (28, 36, 50))
bar("runner.png", 60, 2, (86, 164, 245))
print("wrote logo.png, track.png, runner.png")
