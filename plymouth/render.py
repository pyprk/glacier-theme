#!/usr/bin/env python3
"""Renders the Plymouth theme images (hex logo, progress track and bar)
from the Glacier palette. Pillow only; run once, output is committed."""
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).parent
SS = 8                                     # supersampling factor
ACCENT = (86, 164, 245)
TEXT = (216, 225, 238)
TRACK = (28, 36, 50)


def logo(size=112):
    s = size * SS
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = s / 64                            # SVG viewBox is 64x64
    w = 3.2 * k
    hexagon = [(32, 5), (55.4, 18.5), (55.4, 45.5), (32, 59), (8.6, 45.5), (8.6, 18.5)]
    ridge = [(18, 42), (27.5, 25), (33.5, 35), (38.5, 28), (46, 42)]
    pts = lambda p: [(x * k, y * k) for x, y in p]
    d.line(pts(hexagon + hexagon[:1]), fill=ACCENT, width=round(w), joint="curve")
    d.line(pts(ridge), fill=TEXT, width=round(w), joint="curve")
    for x, y in ridge[:1] + ridge[-1:]:    # round caps on the ridge ends
        d.ellipse([x * k - w / 2, y * k - w / 2, x * k + w / 2, y * k + w / 2], fill=TEXT)
    return im.resize((size, size), Image.LANCZOS)


def bar(width, height, colour, outline=None):
    s = (width * SS, height * SS)
    im = Image.new("RGBA", s, (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle([0, 0, s[0] - 1, s[1] - 1], radius=s[1] // 2,
                                         fill=colour, outline=outline, width=SS if outline else 0)
    return im.resize((width, height), Image.LANCZOS)


def dot(size, colour):
    s = size * SS
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse([0, 0, s - 1, s - 1], fill=colour)
    return im.resize((size, size), Image.LANCZOS)


if __name__ == "__main__":
    logo().save(HERE / "logo.png")
    bar(240, 2, TRACK).save(HERE / "track.png")
    bar(240, 2, ACCENT).save(HERE / "bar.png")
    bar(240, 36, (*TRACK, 235), outline=(42, 53, 71, 255)).save(HERE / "entry.png")
    dot(8, TEXT).save(HERE / "bullet.png")
    print("rendered logo.png track.png bar.png entry.png bullet.png")
