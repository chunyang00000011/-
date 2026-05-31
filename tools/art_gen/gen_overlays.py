"""归途 — 环境覆盖层重绘（全屏 1280x720 色调层）
These are shown at full modulate over the DAY background, so alpha is baked in.
Generated at native resolution (no supersample) using fast gradient ops.
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter
import common as K
from common import mix

W, H = 1280, 720
OUT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "environment", "overlays"))


def save(im, name):
    im.save(os.path.join(OUT, name))
    print("  ok", name, im.size)


def vgrad(stops):
    """Vertical gradient RGBA from stops [(pos0..1, (r,g,b,a)), ...]. Fast via 1px column."""
    col = Image.new("RGBA", (1, H))
    px = col.load()
    stops = sorted(stops, key=lambda s: s[0])
    for y in range(H):
        t = y / (H - 1)
        # find segment
        c0 = stops[0]; c1 = stops[-1]
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                c0, c1 = stops[i], stops[i + 1]
                break
        span = max(1e-6, c1[0] - c0[0])
        lt = (t - c0[0]) / span
        col_rgba = tuple(int(round(c0[1][k] + (c1[1][k] - c0[1][k]) * lt)) for k in range(4))
        px[0, y] = col_rgba
    return col.resize((W, H))


def dusk_tint():
    """Warm mauve→salmon dusk wash; mild, keeps scene readable."""
    g = vgrad([
        (0.0, K.PAL["dusk_mauve"] + (95,)),
        (0.45, K.PAL["dusk_salmon"] + (80,)),
        (0.8, (140, 96, 78, 90)),
        (1.0, (60, 44, 40, 120)),
    ])
    save(g, "overlay_dusk_tint_001.png")


def night_tint():
    """Deep blue night darkening — strong but not opaque."""
    g = vgrad([
        (0.0, K.PAL["night_deep"] + (180,)),
        (0.5, K.PAL["night_blue"] + (165,)),
        (1.0, K.PAL["night_shadow"] + (200,)),
    ])
    save(g, "overlay_night_tint_001.png")


def dawn_transition():
    """Soft brightening warm haze for the dawn phase."""
    g = vgrad([
        (0.0, (255, 226, 180, 70)),
        (0.4, (255, 210, 170, 55)),
        (0.7, (230, 200, 180, 40)),
        (1.0, (200, 190, 170, 60)),
    ])
    # warm glow near horizon (lower third) where sun returns
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([W * 0.2, H * 0.55, W * 0.8, H * 1.15], fill=(255, 224, 170, 90))
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    g = Image.alpha_composite(g, glow)
    save(g, "overlay_dawn_transition_001.png")


def stars_distant_lights():
    """Transparent layer: stars + faint distant warm lights. Shown only at night."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rnd = random.Random(777)
    # stars mostly in upper sky
    for _ in range(150):
        x = rnd.randint(0, W)
        y = int(rnd.triangular(0, H * 0.62, 0))  # denser near top
        r = rnd.uniform(0.6, 2.2)
        b = rnd.randint(170, 255)
        a = rnd.randint(120, 235)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(b, b, min(255, b + 20), a))
    # a few brighter stars with tiny glow
    for _ in range(14):
        x = rnd.randint(0, W); y = rnd.randint(0, int(H * 0.5))
        glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(220, 230, 255, 120))
        glow = glow.filter(ImageFilter.GaussianBlur(4))
        im.alpha_composite(glow)
        d.ellipse([x - 1.4, y - 1.4, x + 1.4, y + 1.4], fill=(255, 255, 255, 255))
    # distant warm lights on horizon line
    for _ in range(22):
        x = rnd.randint(0, W); y = rnd.randint(int(H * 0.7), int(H * 0.82))
        d.ellipse([x - 1.5, y - 1.5, x + 1.5, y + 1.5], fill=(255, 200, 130, rnd.randint(90, 180)))
    save(im, "overlay_stars_distant_lights_001.png")


def grey_cloud_warning():
    """Grey storm-cloud shadow creeping from top — rain pre-warning."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # downward grey gradient, heavier at top
    g = vgrad([
        (0.0, K.PAL["rain_grey"] + (150,)),
        (0.35, K.PAL["rain_grey"] + (90,)),
        (0.7, K.PAL["rain_pale"] + (30,)),
        (1.0, (200, 205, 208, 0)),
    ])
    im = Image.alpha_composite(im, g)
    # billowing cloud lumps along the top
    clouds = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(clouds)
    rnd = random.Random(909)
    for _ in range(40):
        x = rnd.randint(-50, W + 50)
        y = rnd.randint(-40, int(H * 0.28))
        rx = rnd.randint(80, 220); ry = rnd.randint(40, 100)
        shade = rnd.randint(120, 175)
        cd.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(shade, shade + 4, shade + 8, 90))
    clouds = clouds.filter(ImageFilter.GaussianBlur(28))
    im = Image.alpha_composite(im, clouds)
    save(im, "weather_grey_cloud_warning_overlay_001.png")


if __name__ == "__main__":
    print("OVERLAYS →", OUT)
    dusk_tint()
    night_tint()
    dawn_transition()
    stars_distant_lights()
    grey_cloud_warning()
