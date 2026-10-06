#!/usr/bin/env python3
"""Glacier theme: generates the colour scheme, Plasma style and Konsole
profile from one palette, and installs them under ~/.local/share."""
import json
from pathlib import Path

DATA = Path.home() / ".local/share"

# ---- palette ---------------------------------------------------------------
P = dict(
    deep=(11, 15, 22),        # deepest surface: complementary / lock / OSD
    view=(14, 19, 27),        # text views, terminal
    header=(16, 21, 30),      # titlebars, toolbars, panels
    window=(19, 25, 35),      # window background
    alt=(23, 30, 42),         # alternating rows
    button=(28, 36, 50),      # buttons, tooltips
    text=(216, 225, 238),
    dim=(124, 139, 163),
    accent=(86, 164, 245),    # focus, active
    ice=(111, 205, 245),      # hover, links
    select=(53, 119, 212),    # selection background
    red=(232, 105, 122),
    amber=(230, 182, 115),
    green=(127, 207, 154),
    violet=(155, 140, 240),
)


def c(name):
    return ",".join(map(str, P[name]))


def group(name, bg, alt, fg="text", inactive="dim"):
    return f"""[Colors:{name}]
BackgroundAlternate={c(alt)}
BackgroundNormal={c(bg)}
DecorationFocus={c('accent')}
DecorationHover={c('ice')}
ForegroundActive={c('accent')}
ForegroundInactive={c(inactive)}
ForegroundLink={c('ice')}
ForegroundNegative={c('red')}
ForegroundNeutral={c('amber')}
ForegroundNormal={c(fg)}
ForegroundPositive={c('green')}
ForegroundVisited={c('violet')}
"""


def color_scheme():
    return "\n".join([
        """[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2
""",
        """[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0
""",
        group("Button", "button", "alt"),
        group("Complementary", "deep", "header"),
        group("Header", "header", "window"),
        group("Header][Inactive", "window", "alt"),
        f"""[Colors:Selection]
BackgroundAlternate=38,84,150
BackgroundNormal={c('select')}
DecorationFocus={c('accent')}
DecorationHover={c('ice')}
ForegroundActive=255,255,255
ForegroundInactive=190,210,240
ForegroundLink=205,236,255
ForegroundNegative=255,190,198
ForegroundNeutral=255,226,180
ForegroundNormal=255,255,255
ForegroundPositive=190,245,210
ForegroundVisited=215,205,255
""",
        group("Tooltip", "button", "alt"),
        group("View", "view", "header"),
        group("Window", "window", "alt"),
        f"""[General]
ColorScheme=Glacier
Name=Glacier
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground={c('header')}
activeBlend={c('text')}
activeForeground={c('text')}
inactiveBackground={c('window')}
inactiveBlend={c('dim')}
inactiveForeground={c('dim')}
""",
    ])


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    print("wrote", path)


def plasma_style(colors):
    d = DATA / "plasma/desktoptheme/Glacier"
    write(d / "colors", colors)
    write(d / "metadata.json", json.dumps({
        "KPlugin": {
            "Authors": [{"Name": "ryan"}],
            "Description": "Clean dark slate with ice-blue accents",
            "Id": "Glacier",
            "License": "MIT",
            "Name": "Glacier",
            "Version": "1.0",
        },
        "X-Plasma-API": "5.0",
    }, indent=4) + "\n")
    write(d / "plasmarc", """[ContrastEffect]
enabled=true
contrast=0.17
intensity=0.25
saturation=1.7

[AdaptiveTransparency]
enabled=true
""")


def konsole():
    def pair(i, normal, intense):
        return (f"[Color{i}]\nColor={normal}\n\n[Color{i}Faint]\nColor={normal}\n\n"
                f"[Color{i}Intense]\nColor={intense}\n\n")
    ansi = [
        (c("button"), "74,88,112"),
        (c("red"), "245,140,154"),
        (c("green"), "160,226,182"),
        (c("amber"), "242,205,150"),
        (c("accent"), "130,190,250"),
        (c("violet"), "185,172,247"),
        (c("ice"), "155,224,250"),
        ("190,201,218", "236,241,248"),
    ]
    body = (f"[Background]\nColor={c('view')}\n\n[BackgroundFaint]\nColor={c('view')}\n\n"
            f"[BackgroundIntense]\nColor={c('view')}\n\n"
            f"[Foreground]\nColor={c('text')}\n\n[ForegroundFaint]\nColor={c('dim')}\n\n"
            f"[ForegroundIntense]\nColor=255,255,255\n\n")
    body += "".join(pair(i, n, b) for i, (n, b) in enumerate(ansi))
    body += "[General]\nBlur=true\nColorRandomization=false\nDescription=Glacier\nOpacity=0.93\nWallpaper=\n"
    write(DATA / "konsole/Glacier.colorscheme", body)
    write(DATA / "konsole/Glacier.profile", """[Appearance]
ColorScheme=Glacier
Font=IBM Plex Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
LineSpacing=1

[General]
Name=Glacier
Parent=FALLBACK/
TerminalMargin=10

[Scrolling]
HistoryMode=2
ScrollBarPosition=2
""")


if __name__ == "__main__":
    colors = color_scheme()
    write(DATA / "color-schemes/Glacier.colors", colors)
    plasma_style(colors)
    konsole()
