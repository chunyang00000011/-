"""归途 — 美术生成共享库
Shared painting helpers for the Homeward art overhaul.

设计要点 / Design notes:
- 所有绘制在 SS 倍超采样画布上完成，最后缩小回原生分辨率 → 柔和边缘。
- 调色板严格采样自现有手绘背景，保证新资产融入。
- 提供软笔刷、有机噪点、渐变、椭圆体积等手绘半写实工具。
"""
from __future__ import annotations
import math, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SS = 4  # supersample factor

# ----------------------------------------------------------------------------
# Palette — sampled from existing backgrounds (see spec)
# ----------------------------------------------------------------------------
PAL = {
    # sky / day
    "sky_teal":      (84, 151, 164),
    "sky_pale":      (135, 174, 171),
    # grassland
    "grass_sage":    (158, 177, 156),
    "grass_olive":   (161, 164, 133),
    "grass_dark":    (112, 136, 121),
    "grass_deep":    (73, 90, 60),
    "earth_brown":   (96, 79, 52),
    "earth_dark":    (52, 44, 30),
    # night
    "night_blue":    (16, 50, 98),
    "night_deep":    (4, 33, 70),
    "night_shadow":  (2, 18, 38),
    # rain
    "rain_grey":     (166, 174, 179),
    "rain_pale":     (183, 188, 192),
    # dusk
    "dusk_mauve":    (159, 129, 138),
    "dusk_salmon":   (189, 123, 109),
    # foliage
    "leaf_mid":      (86, 120, 74),
    "leaf_dark":     (54, 84, 50),
    "leaf_light":    (138, 168, 104),
    "bark_brown":    (104, 80, 56),
    "bark_dark":     (66, 50, 36),
    # food accents
    "berry_red":     (176, 52, 48),
    "berry_dark":    (120, 30, 34),
    "fruit_orange":  (210, 140, 64),
    "seed_gold":     (196, 168, 96),
    "larva_cream":   (224, 206, 150),
    "insect_brown":  (110, 86, 58),
    # lights
    "warm_glow":     (255, 214, 130),
    "warm_core":     (255, 238, 196),
    "cold_glow":     (170, 210, 255),
    "cold_core":     (220, 238, 255),
    # ui — 自然手账
    "paper":         (226, 208, 170),
    "paper_dark":    (198, 176, 134),
    "paper_shadow":  (168, 146, 104),
    "ink":           (74, 58, 40),
    "wood":          (132, 96, 60),
    "wood_dark":     (96, 68, 42),
    "twine":         (180, 156, 110),
    "warn_red":      (208, 72, 54),
}


def c(name, a=255):
    r, g, b = PAL[name]
    return (r, g, b, a)


def mix(c1, c2, t):
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(len(c1)))


def canvas(w, h):
    """Supersampled RGBA canvas + draw."""
    im = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im, "RGBA")


def s(v):
    """scale a logical px value to supersampled space."""
    return int(round(v * SS))


def finish(im, w, h):
    """Downscale supersampled image back to native resolution."""
    return im.resize((w, h), Image.LANCZOS)


# ----------------------------------------------------------------------------
# Soft drawing primitives (operate in supersampled space)
# ----------------------------------------------------------------------------

def soft_blob(draw_target, cx, cy, rx, ry, color, blur=0):
    """Filled ellipse painted onto its own layer so it can be blurred & merged."""
    layer = Image.new("RGBA", draw_target.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=color)
    if blur > 0:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    draw_target.alpha_composite(layer)


def radial_glow(w_ss, h_ss, cx, cy, radius, inner, outer_a=0):
    """Smooth radial gradient glow as its own RGBA layer."""
    layer = Image.new("RGBA", (w_ss, h_ss), (0, 0, 0, 0))
    px = layer.load()
    r2 = radius * radius
    ir, ig, ib, ia = inner
    for y in range(max(0, int(cy - radius)), min(h_ss, int(cy + radius) + 1)):
        for x in range(max(0, int(cx - radius)), min(w_ss, int(cx + radius) + 1)):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 >= r2:
                continue
            t = 1.0 - math.sqrt(d2) / radius
            t = t * t  # ease
            a = int(ia * t + outer_a * (1 - t))
            px[x, y] = (ir, ig, ib, a)
    return layer


def add_noise(im, amount=12, seed=0):
    """Overlay subtle per-pixel luminance noise where alpha>0 (organic feel)."""
    rnd = random.Random(seed)
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            n = rnd.randint(-amount, amount)
            px[x, y] = (
                max(0, min(255, r + n)),
                max(0, min(255, g + n)),
                max(0, min(255, b + n)),
                a,
            )
    return im


def shade_sphere(draw_target, cx, cy, r, base, light=(255, 255, 255), light_dir=(-0.4, -0.5)):
    """Paint a shaded sphere/berry: base fill + highlight + rim shadow."""
    soft_blob(draw_target, cx, cy, r, r, base + (255,) if len(base) == 3 else base)
    # rim shadow
    sh = mix(base, (0, 0, 0), 0.45)
    soft_blob(draw_target, cx + r * 0.18, cy + r * 0.2, r * 0.95, r * 0.95, sh + (90,), blur=r * 0.3)
    # core fill again (so shadow stays at rim)
    soft_blob(draw_target, cx, cy, r * 0.82, r * 0.82, base + (255,), blur=r * 0.1)
    # highlight
    hx, hy = cx + light_dir[0] * r * 0.55, cy + light_dir[1] * r * 0.55
    hl = mix(base, light, 0.7)
    soft_blob(draw_target, hx, hy, r * 0.34, r * 0.34, hl + (220,), blur=r * 0.25)
    soft_blob(draw_target, hx, hy, r * 0.16, r * 0.16, light + (230,) if len(light) == 3 else light, blur=r * 0.12)


def stroke(draw, p0, p1, width, color):
    draw.line([p0, p1], fill=color, width=int(width))


def tapered_leaf(draw_target, cx, cy, length, width, angle, color, vein=True):
    """A single painted leaf, pointing along angle (radians)."""
    layer = Image.new("RGBA", draw_target.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    ca, sa = math.cos(angle), math.sin(angle)
    pts = []
    steps = 14
    for i in range(steps + 1):
        t = i / steps
        # leaf half-width profile (0 at base, max mid, 0 at tip)
        hw = math.sin(t * math.pi) * width * 0.5
        lx = t * length
        # one side
        pts.append((cx + ca * lx - sa * hw, cy + sa * lx + ca * hw))
    for i in range(steps, -1, -1):
        t = i / steps
        hw = math.sin(t * math.pi) * width * 0.5
        lx = t * length
        pts.append((cx + ca * lx + sa * hw, cy + sa * lx - ca * hw))
    d.polygon(pts, fill=color)
    if vein:
        vcol = mix(color[:3], (0, 0, 0), 0.3) + (160,)
        d.line([(cx, cy), (cx + ca * length, cy + sa * length)], fill=vcol, width=max(1, int(width * 0.06)))
    layer = layer.filter(ImageFilter.GaussianBlur(SS * 0.4))
    draw_target.alpha_composite(layer)


def paper_fill(w_ss, h_ss, base="paper", dark="paper_dark", seed=1):
    """Warm parchment fill with mottled tone for UI panels (fast single-layer)."""
    layer = Image.new("RGBA", (w_ss, h_ss), c(base))
    mottle = Image.new("RGBA", (w_ss, h_ss), (0, 0, 0, 0))
    md = ImageDraw.Draw(mottle)
    rnd = random.Random(seed)
    n = int(w_ss * h_ss / (SS * SS * 120))
    for _ in range(n):
        x = rnd.randint(0, w_ss); y = rnd.randint(0, h_ss)
        rr = rnd.randint(s(6), s(26))
        t = rnd.uniform(0.1, 0.35)
        md.ellipse([x - rr, y - rr, x + rr, y + rr],
                   fill=mix(c(base)[:3], c(dark)[:3], t) + (50,))
    mottle = mottle.filter(ImageFilter.GaussianBlur(s(8)))
    layer.alpha_composite(mottle)
    return layer


def rounded_panel(w_ss, h_ss, radius, fill_layer, border_col, border_w):
    """Composite a paper fill into a rounded-rect mask with a border."""
    out = Image.new("RGBA", (w_ss, h_ss), (0, 0, 0, 0))
    mask = Image.new("L", (w_ss, h_ss), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([border_w, border_w, w_ss - border_w, h_ss - border_w],
                         radius=radius, fill=255)
    out.paste(fill_layer, (0, 0), mask)
    # border
    bd = ImageDraw.Draw(out)
    bd.rounded_rectangle([border_w // 2, border_w // 2, w_ss - border_w // 2, h_ss - border_w // 2],
                         radius=radius, outline=border_col, width=border_w)
    return out


def drop_shadow(im, offset, blur, alpha=110):
    """Return new image with a soft drop shadow behind opaque pixels."""
    a = im.split()[3]
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    shadow_col = Image.new("RGBA", im.size, (0, 0, 0, alpha))
    sh.paste(shadow_col, offset, a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    out = Image.alpha_composite(sh, im)
    return out
