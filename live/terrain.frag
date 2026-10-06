#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
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
};
layout(binding = 1) uniform sampler2D field;

const int ROWS = 72;
const float PEAK_X = 0.60;
const float SPAN = 0.5;
const float FMIN = -1.028266;
const float FMAX = 0.459677;
const float BASE[ROWS] = float[ROWS](0.60000, 0.60033, 0.60107, 0.60212, 0.60346, 0.60506, 0.60689, 0.60896, 0.61124, 0.61374, 0.61643, 0.61932, 0.62240, 0.62566, 0.62911, 0.63273, 0.63653, 0.64049, 0.64463, 0.64892, 0.65338, 0.65800, 0.66277, 0.66769, 0.67277, 0.67800, 0.68338, 0.68891, 0.69458, 0.70039, 0.70635, 0.71244, 0.71868, 0.72505, 0.73156, 0.73821, 0.74499, 0.75190, 0.75895, 0.76612, 0.77343, 0.78086, 0.78843, 0.79612, 0.80393, 0.81188, 0.81994, 0.82813, 0.83644, 0.84488, 0.85344, 0.86211, 0.87091, 0.87983, 0.88886, 0.89801, 0.90728, 0.91667, 0.92617, 0.93579, 0.94552, 0.95537, 0.96533, 0.97540, 0.98559, 0.99589, 1.00630, 1.01682, 1.02745, 1.03819, 1.04904, 1.06000);
const float AMP[ROWS] = float[ROWS](0.24200, 0.24665, 0.25130, 0.25594, 0.26059, 0.26524, 0.26989, 0.27454, 0.27918, 0.28383, 0.28848, 0.29313, 0.29777, 0.30242, 0.30707, 0.31172, 0.31637, 0.32101, 0.32566, 0.33031, 0.33496, 0.33961, 0.34425, 0.34890, 0.35355, 0.35820, 0.36285, 0.36749, 0.37214, 0.37679, 0.38144, 0.38608, 0.39073, 0.39538, 0.40003, 0.40468, 0.40932, 0.41397, 0.41862, 0.42327, 0.42792, 0.43256, 0.43721, 0.44186, 0.44651, 0.45115, 0.45580, 0.46045, 0.46510, 0.46975, 0.47439, 0.47904, 0.48369, 0.48834, 0.49299, 0.49763, 0.50228, 0.50693, 0.51158, 0.51623, 0.52087, 0.52552, 0.53017, 0.53482, 0.53946, 0.54411, 0.54876, 0.55341, 0.55806, 0.56270, 0.56735, 0.57200);
const float ENVR[ROWS] = float[ROWS](0.39086, 0.41029, 0.43161, 0.45485, 0.48005, 0.50722, 0.53633, 0.56733, 0.60014, 0.63464, 0.67069, 0.70809, 0.74662, 0.78602, 0.82601, 0.86625, 0.90641, 0.94610, 0.98495, 1.02256, 1.05852, 1.09243, 1.12390, 1.15256, 1.17806, 1.20008, 1.21835, 1.23262, 1.24273, 1.24852, 1.24993, 1.24694, 1.23958, 1.22796, 1.21222, 1.19257, 1.16926, 1.14259, 1.11288, 1.08048, 1.04579, 1.00919, 0.97109, 0.93189, 0.89198, 0.85175, 0.81156, 0.77175, 0.73263, 0.69448, 0.65755, 0.62204, 0.58813, 0.55596, 0.52563, 0.49721, 0.47075, 0.44626, 0.42371, 0.40308, 0.38431, 0.36732, 0.35203, 0.33834, 0.32615, 0.31535, 0.30584, 0.29751, 0.29024, 0.28393, 0.27848, 0.27381);
const float LW[ROWS] = float[ROWS](1.54000, 1.55859, 1.57718, 1.59577, 1.61437, 1.63296, 1.65155, 1.67014, 1.68873, 1.70732, 1.72592, 1.74451, 1.76310, 1.78169, 1.80028, 1.81887, 1.83746, 1.85606, 1.87465, 1.89324, 1.91183, 1.93042, 1.94901, 1.96761, 1.98620, 2.00479, 2.02338, 2.04197, 2.06056, 2.07915, 2.09775, 2.11634, 2.13493, 2.15352, 2.17211, 2.19070, 2.20930, 2.22789, 2.24648, 2.26507, 2.28366, 2.30225, 2.32085, 2.33944, 2.35803, 2.37662, 2.39521, 2.41380, 2.43239, 2.45099, 2.46958, 2.48817, 2.50676, 2.52535, 2.54394, 2.56254, 2.58113, 2.59972, 2.61831, 2.63690, 2.65549, 2.67408, 2.69268, 2.71127, 2.72986, 2.74845, 2.76704, 2.78563, 2.80423, 2.82282, 2.84141, 2.86000);
const float ALPHA[ROWS] = float[ROWS](0.18000, 0.25197, 0.30519, 0.35289, 0.39717, 0.43890, 0.47855, 0.51639, 0.55259, 0.58727, 0.62049, 0.65231, 0.68275, 0.71184, 0.73957, 0.76595, 0.79098, 0.81464, 0.83695, 0.85787, 0.87740, 0.89554, 0.91226, 0.92755, 0.94141, 0.95382, 0.96477, 0.97425, 0.98226, 0.98879, 0.99383, 0.99738, 0.99943, 0.99999, 0.99904, 0.99660, 0.99267, 0.98724, 0.98033, 0.97194, 0.96207, 0.95074, 0.93795, 0.92372, 0.90806, 0.89097, 0.87247, 0.85258, 0.83130, 0.80864, 0.78462, 0.75924, 0.73251, 0.70443, 0.67499, 0.64420, 0.61202, 0.57842, 0.54336, 0.50674, 0.46845, 0.42829, 0.38596, 0.34090, 0.29206, 0.23661, 0.18000, 0.18000, 0.18000, 0.18000, 0.18000, 0.18000);

float sampleField(float u, float r) {
    vec4 t = texture(field, vec2(u, fract(r)));
    float v = (t.r * 65280.0 + t.g * 255.0) / 65535.0;
    return FMIN + v * (FMAX - FMIN);
}

float envU(float u) {
    float d = (u - PEAK_X) / 0.21;
    return 0.10 + exp(-d * d);
}

float heightAt(float u, float fr, float env) {
    return pow(max(sampleField(u, fr) + 0.22, 0.0), 1.35) * env;
}

vec3 skyAt(float py) {
    return py < 0.55 ? mix(skyTop.rgb, skyMid.rgb, py / 0.55)
                     : mix(skyMid.rgb, skyBot.rgb, (py - 0.55) / 0.45);
}

float lineProfile(float g) {
    if (g <= 0.0 || g >= 1.0) return 0.0;
    if (g < 0.28) return 0.55 * g / 0.28;
    if (g < 0.5) return mix(0.55, 1.0, (g - 0.28) / 0.22);
    if (g < 0.72) return mix(1.0, 0.55, (g - 0.5) / 0.22);
    return 0.55 * (1.0 - g) / 0.28;
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
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
    if (py < 0.62) {
        float step = res.x / 64.0;
        vec2 g = fc / step;
        vec2 cell = floor(g);
        vec2 local = (fract(g) - 0.5) * step;
        float fade = pow(1.0 - py / 0.62, 1.2);
        float cm = mod(cell.y, 8.0);
        if (mod(cell.x, 8.0) == 0.0 && (cm == 0.0 || cm == 7.0)) {
            float arm = 7.0 * S;
            float w = 0.7 * S;
            float h = (1.0 - smoothstep(w, w + 1.0, abs(local.y))) * (1.0 - smoothstep(arm, arm + 1.0, abs(local.x)));
            float v = (1.0 - smoothstep(w, w + 1.0, abs(local.x))) * (1.0 - smoothstep(arm, arm + 1.0, abs(local.y)));
            bg = mix(bg, linePeak.rgb, max(h, v) * 0.32 * fade);
        } else {
            float r = 1.7 * S;
            float a = 1.0 - smoothstep(r - 0.7, r + 0.7, length(local));
            bg = mix(bg, dotCol.rgb, a * 0.085 * fade);
        }
    }

    // ridge lines, nearest first
    vec3 acc = vec3(0.0);
    float accA = 0.0;
    bool covered = false;
    float g = (px - PEAK_X) / 1.24 + 0.5;
    float prof = lineProfile(g);
    float peakMix = 1.0 - min(1.0, abs(g - 0.5) / 0.22);

    for (int i = ROWS - 1; i >= 0; --i) {
        float t = float(i) / float(ROWS - 1);
        float base = BASE[i];
        float amp = AMP[i];
        float lwpx = LW[i] * S;
        float gate = lwpx * 12.0 / res.y;
        if (py > base + gate) { covered = true; break; }
        float spread = 1.05 + 0.95 * t;
        float u = PEAK_X + (px - PEAK_X) / spread;
        if (abs(float(i) - glitchRow) < 0.5) u += glitchShift;   // one ridge skips sideways for a frame or two
        float env = envU(u) * ENVR[i];
        if (py < base - amp * HF * env - gate) continue;
        float fr = t * SPAN - phase;
        float yc = base - heightAt(u, fr, env) * amp;
        float d = py - yc;
        if (d > gate) { covered = true; break; }
        if (d > -gate) {
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
            if (d > 0.0) { covered = true; break; }
        }
    }

    vec3 col = acc + (1.0 - accA) * (covered ? sky : bg);
    col += (hash(fc) - 0.5) * (2.4 / 255.0);
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
