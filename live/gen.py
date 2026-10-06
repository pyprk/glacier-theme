#!/usr/bin/env python3
"""Generates the height-field texture and fragment shader for the Glacier
live wallpaper. The shader is compiled separately with qsb (build.sh)."""
import math
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
PLUGIN = Path.home() / ".local/share/plasma/wallpapers/com.ryan.glacier.live/contents"
ROWS = 72
SIZE = 512
SEED = 7

rng = np.random.default_rng(SEED)


def lowpass(sx, sy):
    n = rng.standard_normal((SIZE, SIZE))
    F = np.fft.rfft2(n)
    fy = np.fft.fftfreq(SIZE)[:, None] * SIZE
    fx = np.fft.rfftfreq(SIZE)[None, :] * SIZE
    F *= np.exp(-((fy / sy) ** 2 + (fx / sx) ** 2) / 2)
    f = np.fft.irfft2(F, s=(SIZE, SIZE))
    return f / np.abs(f).max()


# rows span half the texture period vertically, so the vertical feature
# scale is doubled to keep the same look as the static wallpaper
field = lowpass(3.0, 6.0) + 0.38 * lowpass(8.0, 16.0) + 0.07 * lowpass(22.0, 44.0)
# soft-clip the highest values: as the field scrolls under the envelope, an
# unclipped maximum would make one spike far taller than the rest
KNEE, RANGE = 0.30, 0.20
field = np.where(field > KNEE, KNEE + (field - KNEE) / (1 + (field - KNEE) / RANGE), field)
fmin, fmax = float(field.min()), float(field.max())
norm = np.rint((field - fmin) / (fmax - fmin) * 65535).astype(np.uint32)
tex = np.zeros((SIZE, SIZE, 4), np.uint8)
tex[..., 0] = norm >> 8
tex[..., 1] = norm & 255
tex[..., 3] = 255
(PLUGIN / "images").mkdir(parents=True, exist_ok=True)
Image.fromarray(tex, "RGBA").save(PLUGIN / "images/field.png")

# per-row constants, baked into the shader
base, amp, envr, lw, alpha = [], [], [], [], []
for i in range(ROWS):
    t = i / (ROWS - 1)
    base.append(0.60 + 0.46 * t ** 1.7)
    amp.append(0.44 * (0.55 + 0.75 * t))
    envr.append(0.25 + math.exp(-((t - 0.42) / 0.30) ** 2))
    lw.append(2.2 * (0.7 + 0.6 * t))
    depth = max(0.0, math.sin(math.pi * min(1.0, t * 1.08))) ** 0.8
    alpha.append(0.18 + 0.82 * depth)


def arr(name, vals):
    return f"const float {name}[ROWS] = float[ROWS]({', '.join(f'{v:.5f}' for v in vals)});"


shader = f"""#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {{
    mat4 qt_Matrix;
    float qt_Opacity;
    float phase;
    vec2 res;
    vec4 skyTop;
    vec4 skyMid;
    vec4 skyBot;
    vec4 glowCol;
    vec4 horizonCol;
    vec4 lineFar;
    vec4 lineNear;
    vec4 linePeak;
    vec4 dotCol;
    float glitchRow;
    float glitchShift;
}};
layout(binding = 1) uniform sampler2D field;

const int ROWS = {ROWS};
const float PEAK_X = 0.60;
const float SPAN = 0.5;
const float FMIN = {fmin:.6f};
const float FMAX = {fmax:.6f};
{arr('BASE', base)}
{arr('AMP', amp)}
{arr('ENVR', envr)}
{arr('LW', lw)}
{arr('ALPHA', alpha)}

float sampleField(float u, float r) {{
    vec4 t = texture(field, vec2(u, fract(r)));
    float v = (t.r * 65280.0 + t.g * 255.0) / 65535.0;
    return FMIN + v * (FMAX - FMIN);
}}

float envU(float u) {{
    float d = (u - PEAK_X) / 0.21;
    return 0.10 + exp(-d * d);
}}

float heightAt(float u, float fr, float env) {{
    return pow(max(sampleField(u, fr) + 0.22, 0.0), 1.35) * env;
}}

vec3 skyAt(float py) {{
    return py < 0.55 ? mix(skyTop.rgb, skyMid.rgb, py / 0.55)
                     : mix(skyMid.rgb, skyBot.rgb, (py - 0.55) / 0.45);
}}

float lineProfile(float g) {{
    if (g <= 0.0 || g >= 1.0) return 0.0;
    if (g < 0.28) return 0.55 * g / 0.28;
    if (g < 0.5) return mix(0.55, 1.0, (g - 0.28) / 0.22);
    if (g < 0.72) return mix(1.0, 0.55, (g - 0.5) / 0.22);
    return 0.55 * (1.0 - g) / 0.28;
}}

float hash(vec2 p) {{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}}

void main() {{
    vec2 uv = qt_TexCoord0;
    float px = uv.x;
    float py = uv.y;
    vec2 fc = uv * res;
    float S = res.x / 3840.0;
    float HF = pow(FMAX + 0.22, 1.35);

    // sky, glow and horizon band
    vec3 sky = skyAt(py);
    vec3 bg = sky;
    vec2 gd = vec2((px - PEAK_X) * res.x, (py - 0.52) * res.y) / (0.46 * res.x);
    float gl = length(gd);
    float ga = gl < 0.5 ? mix(1.0, 0.3, gl / 0.5) : mix(0.3, 0.0, min(1.0, (gl - 0.5) / 0.5));
    bg = mix(bg, glowCol.rgb, ga * glowCol.a);
    float hy = (py - 0.60) / 0.10;
    float hx = (px - PEAK_X) / 0.5;
    bg = mix(bg, horizonCol.rgb, exp(-hy * hy) * exp(-hx * hx) * horizonCol.a);

    // dot grid with crosshair marks, fading toward the horizon
    if (py < 0.62) {{
        float step = res.x / 64.0;
        vec2 g = fc / step;
        vec2 cell = floor(g);
        vec2 local = (fract(g) - 0.5) * step;
        float fade = pow(1.0 - py / 0.62, 1.2);
        float cm = mod(cell.y, 8.0);
        if (mod(cell.x, 8.0) == 0.0 && (cm == 0.0 || cm == 7.0)) {{
            float arm = 7.0 * S;
            float w = 0.7 * S;
            float h = (1.0 - smoothstep(w, w + 1.0, abs(local.y))) * (1.0 - smoothstep(arm, arm + 1.0, abs(local.x)));
            float v = (1.0 - smoothstep(w, w + 1.0, abs(local.x))) * (1.0 - smoothstep(arm, arm + 1.0, abs(local.y)));
            bg = mix(bg, linePeak.rgb, max(h, v) * 0.32 * fade);
        }} else {{
            float r = 1.7 * S;
            float a = 1.0 - smoothstep(r - 0.7, r + 0.7, length(local));
            bg = mix(bg, dotCol.rgb, a * 0.085 * fade);
        }}
    }}

    // ridge lines, nearest first
    vec3 acc = vec3(0.0);
    float accA = 0.0;
    bool covered = false;
    float g = (px - PEAK_X) / 1.24 + 0.5;
    float prof = lineProfile(g);
    float peakMix = 1.0 - min(1.0, abs(g - 0.5) / 0.22);

    for (int i = ROWS - 1; i >= 0; --i) {{
        float t = float(i) / float(ROWS - 1);
        float base = BASE[i];
        float amp = AMP[i];
        float lwpx = LW[i] * S;
        float gate = lwpx * 12.0 / res.y;
        if (py > base + gate) {{ covered = true; break; }}
        float spread = 1.05 + 0.95 * t;
        float u = PEAK_X + (px - PEAK_X) / spread;
        if (abs(float(i) - glitchRow) < 0.5) u += glitchShift;   // one ridge skips sideways for a frame or two
        float env = envU(u) * ENVR[i];
        if (py < base - amp * HF * env - gate) continue;
        float fr = t * SPAN - phase;
        float yc = base - heightAt(u, fr, env) * amp;
        float d = py - yc;
        if (d > gate) {{ covered = true; break; }}
        if (d > -gate) {{
            float du = 1.0 / 400.0;
            float y2 = base - heightAt(u + du, fr, envU(u + du) * ENVR[i]) * amp;
            float slope = ((y2 - yc) * res.y) / (du * spread * res.x);
            float dist = abs(d) * res.y / sqrt(1.0 + slope * slope);
            vec3 col = mix(mix(lineFar.rgb, lineNear.rgb, t), linePeak.rgb, peakMix);
            float a = ALPHA[i] * prof;
            float aLine = (1.0 - smoothstep(lwpx * 0.5 - 0.7, lwpx * 0.5 + 0.7, dist)) * a;
            float aGlow = (1.0 - smoothstep(0.0, lwpx * 1.8, dist)) * a * 0.12;
            float al = aLine + aGlow * (1.0 - aLine);
            acc += (1.0 - accA) * al * col;
            accA += (1.0 - accA) * al;
            if (d > 0.0) {{ covered = true; break; }}
        }}
    }}

    vec3 col = acc + (1.0 - accA) * (covered ? sky : bg);
    col += (hash(fc) - 0.5) * (2.4 / 255.0);
    fragColor = vec4(col, 1.0) * qt_Opacity;
}}
"""
(HERE / "terrain.frag").write_text(shader)
print("field range", fmin, fmax)
print("wrote", PLUGIN / "images/field.png", "and", HERE / "terrain.frag")
