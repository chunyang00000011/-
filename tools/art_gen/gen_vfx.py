"""归途 — VFX 资产重绘
Most are small world-space bursts (tinted by vfx.gd modulate).
vfx_screen_darken_fade is full-screen 1280x720.
Native dimensions preserved.
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter
import common as K
from common import SS, s, c, mix, soft_blob, radial_glow, add_noise

OUTV = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "vfx"))


def savev(im, w, h, name, supersampled=True):
    out = K.finish(im, w, h) if supersampled else im
    out.save(os.path.join(OUTV, name))
    print("  ok", name, out.size)


def pickup_burst(w=385, h=420):
    """Golden pickup burst: radiating sparkles + soft core (tinted warm by code)."""
    im, d = K.canvas(w, h)
    W, H = w * SS, h * SS
    cx, cy = W // 2, H // 2
    im.alpha_composite(radial_glow(W, H, cx, cy, s(min(w, h) * 0.32), (255, 240, 200, 200)))
    im.alpha_composite(radial_glow(W, H, cx, cy, s(min(w, h) * 0.15), (255, 252, 235, 240)))
    rnd = random.Random(501)
    for i in range(14):
        a = (i / 14) * math.tau + rnd.uniform(-0.1, 0.1)
        r0 = s(min(w, h) * 0.12)
        r1 = s(min(w, h) * rnd.uniform(0.30, 0.46))
        x0, y0 = cx + math.cos(a) * r0, cy + math.sin(a) * r0
        x1, y1 = cx + math.cos(a) * r1, cy + math.sin(a) * r1
        d.line([(x0, y0), (x1, y1)], fill=(255, 246, 210, 220), width=s(3))
        # sparkle tip
        soft_blob(im, x1, y1, s(4), s(4), (255, 252, 235, 240), blur=s(2))
    savev(im, w, h, "vfx_food_pickup_burst_gold_001.png")


def collision_flash(w=144, h=144):
    """Sharp impact flash star (tinted by code)."""
    im, d = K.canvas(w, h)
    W, H = w * SS, h * SS
    cx, cy = W // 2, H // 2
    im.alpha_composite(radial_glow(W, H, cx, cy, s(w * 0.44), (255, 240, 220, 210)))
    # 4-point impact star
    for a in (0, math.pi / 2, math.pi, 3 * math.pi / 2):
        x1, y1 = cx + math.cos(a) * s(w * 0.46), cy + math.sin(a) * s(h * 0.46)
        d.line([(cx, cy), (x1, y1)], fill=(255, 250, 240, 235), width=s(5))
    for a in (math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4):
        x1, y1 = cx + math.cos(a) * s(w * 0.30), cy + math.sin(a) * s(h * 0.30)
        d.line([(cx, cy), (x1, y1)], fill=(255, 248, 230, 200), width=s(3))
    soft_blob(im, cx, cy, s(w * 0.10), s(h * 0.10), (255, 255, 250, 255), blur=s(2))
    savev(im, w, h, "vfx_collision_flash_001.png")


def feather_particles(w=256, h=128):
    """Scattered feathers flung on hit."""
    im, d = K.canvas(w, h)
    rnd = random.Random(511)
    for _ in range(7):
        fx = s(w * rnd.uniform(0.15, 0.85))
        fy = s(h * rnd.uniform(0.2, 0.8))
        ang = rnd.uniform(0, math.tau)
        ln = s(w * rnd.uniform(0.10, 0.18))
        wd = ln * 0.4
        ca, sa = math.cos(ang), math.sin(ang)
        # feather as tapered shape
        layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        pts = []
        steps = 10
        col = mix((255, 255, 255), K.PAL["paper_dark"], rnd.uniform(0, 0.3))
        for i in range(steps + 1):
            t = i / steps
            hw = math.sin(t * math.pi) * wd * 0.5
            px = fx + ca * (t - 0.5) * ln
            py = fy + sa * (t - 0.5) * ln
            pts.append((px - sa * hw, py + ca * hw))
        for i in range(steps, -1, -1):
            t = i / steps
            hw = math.sin(t * math.pi) * wd * 0.5
            px = fx + ca * (t - 0.5) * ln
            py = fy + sa * (t - 0.5) * ln
            pts.append((px + sa * hw, py - ca * hw))
        ld.polygon(pts, fill=col + (235,))
        # rachis
        ld.line([(fx - ca * ln * 0.5, fy - sa * ln * 0.5), (fx + ca * ln * 0.5, fy + sa * ln * 0.5)],
                fill=mix(col, (0, 0, 0), 0.3) + (200,), width=s(1.4))
        layer = layer.filter(ImageFilter.GaussianBlur(SS * 0.3))
        im.alpha_composite(layer)
    savev(im, w, h, "vfx_feather_particles_001.png")


def speed_lines(w=320, h=128):
    """Horizontal motion streaks for acceleration (white, code-tinted, fades by alpha)."""
    im, d = K.canvas(w, h)
    rnd = random.Random(521)
    for _ in range(16):
        y = s(h * rnd.uniform(0.05, 0.95))
        x0 = s(w * rnd.uniform(0.0, 0.5))
        ln = s(w * rnd.uniform(0.3, 0.55))
        a = rnd.randint(120, 220)
        d.line([(x0, y), (x0 + ln, y)], fill=(255, 255, 255, a), width=s(rnd.choice([1, 1, 2])))
    im = im.filter(ImageFilter.GaussianBlur(SS * 0.4))
    savev(im, w, h, "vfx_speed_lines_001.png")


def warm_light_glow(w=256, h=256):
    """Warm radial glow attached behind warm night food."""
    im, d = K.canvas(w, h)
    W, H = w * SS, h * SS
    cx, cy = W // 2, H // 2
    im.alpha_composite(radial_glow(W, H, cx, cy, s(w * 0.48), c("warm_glow", 170)))
    im.alpha_composite(radial_glow(W, H, cx, cy, s(w * 0.26), c("warm_core", 220)))
    savev(im, w, h, "vfx_warm_light_glow_001.png")


def cold_light_flicker(w=256, h=256):
    """Cold blue glow behind the false-light lure."""
    im, d = K.canvas(w, h)
    W, H = w * SS, h * SS
    cx, cy = W // 2, H // 2
    im.alpha_composite(radial_glow(W, H, cx, cy, s(w * 0.48), c("cold_glow", 160)))
    im.alpha_composite(radial_glow(W, H, cx, cy, s(w * 0.24), c("cold_core", 215)))
    savev(im, w, h, "vfx_cold_light_flicker_001.png")


def screen_darken_fade(w=1280, h=720):
    """Full-screen vignette darken used in storm phase (native res, no SS)."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # radial vignette: darker at edges
    px = im.load()
    cx, cy = w / 2, h / 2
    maxd = math.hypot(cx, cy)
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            d = math.hypot(x - cx, y - cy) / maxd
            a = int(150 * (d ** 1.6))
            col = (8, 14, 22, a)
            px[x, y] = col
            if x + 1 < w: px[x + 1, y] = col
            if y + 1 < h: px[x, y + 1] = col
            if x + 1 < w and y + 1 < h: px[x + 1, y + 1] = col
    im = im.filter(ImageFilter.GaussianBlur(6))
    savev(im, w, h, "vfx_screen_darken_fade_001.png", supersampled=False)


if __name__ == "__main__":
    print("VFX →", OUTV)
    pickup_burst()
    collision_flash()
    feather_particles()
    speed_lines()
    warm_light_glow()
    cold_light_flicker()
    screen_darken_fade()
