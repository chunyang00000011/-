"""归途 — 食物资产重绘
Native dimensions are preserved exactly (code relies on visual_scale tuned to them).
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter
import common as K
from common import SS, s, c, mix, soft_blob, shade_sphere, radial_glow, add_noise, tapered_leaf

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "food")
OUT = os.path.normpath(OUT)


def save(im, w, h, name):
    out = K.finish(im, w, h)
    path = os.path.join(OUT, name)
    out.save(path)
    print("  ok", name, out.size)


# ---------------------------------------------------------------------------
def ground_insect(w=96, h=64):
    """A small realistic ground beetle/cricket."""
    im, d = K.canvas(w, h)
    cx, cy = s(w * 0.52), s(h * 0.56)
    body = c("insect_brown")
    # contact shadow
    soft_blob(im, cx, s(h * 0.82), s(w * 0.34), s(h * 0.08), (0, 0, 0, 70), blur=s(4))
    # abdomen
    shade_sphere(im, cx, cy, s(h * 0.30), K.PAL["insect_brown"], light_dir=(-0.4, -0.6))
    # thorax
    shade_sphere(im, cx - s(w * 0.16), cy - s(h * 0.04), s(h * 0.19), K.PAL["earth_dark"], light_dir=(-0.4, -0.6))
    # head
    shade_sphere(im, cx - s(w * 0.27), cy - s(h * 0.08), s(h * 0.12), K.PAL["earth_dark"])
    # legs
    leg = mix(K.PAL["earth_dark"], (0, 0, 0), 0.2) + (255,)
    for i, (ax, ay) in enumerate([(-0.10, 0.18), (0.02, 0.20), (0.14, 0.18)]):
        bx = cx + s(w * ax)
        d.line([(bx, cy + s(h * 0.05)), (bx - s(w * 0.06), cy + s(h * (ay + 0.14)))], fill=leg, width=s(2))
        d.line([(bx, cy + s(h * 0.05)), (bx + s(w * 0.06), cy + s(h * (ay + 0.14)))], fill=leg, width=s(2))
    # antennae
    hx = cx - s(w * 0.27)
    d.line([(hx, cy - s(h * 0.1)), (hx - s(w * 0.14), cy - s(h * 0.28))], fill=leg, width=s(1.4))
    d.line([(hx, cy - s(h * 0.1)), (hx - s(w * 0.18), cy - s(h * 0.16))], fill=leg, width=s(1.4))
    # wing-case sheen
    soft_blob(im, cx - s(w * 0.02), cy - s(h * 0.10), s(h * 0.12), s(h * 0.06),
              mix(K.PAL["insect_brown"], (255, 240, 200), 0.5) + (150,), blur=s(2))
    add_noise(im, 8, seed=11)
    save(im, w, h, "food_ground_insect_001.png")


def seed_cluster(w=96, h=64):
    """A tuft of grass seeds / grain heads."""
    im, d = K.canvas(w, h)
    rnd = random.Random(3)
    base_x, base_y = s(w * 0.5), s(h * 0.92)
    soft_blob(im, base_x, base_y, s(w * 0.28), s(h * 0.06), (0, 0, 0, 60), blur=s(4))
    stems = 5
    for i in range(stems):
        ang = math.radians(-90 + (i - stems // 2) * 17 + rnd.uniform(-5, 5))
        length = s(h * (0.62 + rnd.uniform(-0.08, 0.08)))
        tipx = base_x + math.cos(ang) * length
        tipy = base_y + math.sin(ang) * length
        # stem
        d.line([(base_x, base_y), (tipx, tipy)], fill=mix(K.PAL["grass_deep"], (0, 0, 0), 0.1) + (255,), width=s(2))
        # grain head — stacked golden kernels
        n = 7
        for k in range(n):
            t = k / (n - 1)
            gx = base_x + math.cos(ang) * length * (0.55 + 0.45 * t)
            gy = base_y + math.sin(ang) * length * (0.55 + 0.45 * t)
            col = mix(K.PAL["seed_gold"], K.PAL["larva_cream"], t * 0.5)
            shade_sphere(im, gx, gy, s(w * 0.035), col)
    add_noise(im, 9, seed=4)
    save(im, w, h, "food_seed_cluster_001.png")


def bush_berries(w=132, h=96):
    """A cluster of red berries with leaves."""
    im, d = K.canvas(w, h)
    rnd = random.Random(7)
    cx, cy = s(w * 0.5), s(h * 0.52)
    # leaves behind
    for ang_deg, ln in [(-150, 0.5), (-30, 0.46), (210, 0.4)]:
        tapered_leaf(im, cx, cy, s(w * ln), s(h * 0.30), math.radians(ang_deg),
                     mix(K.PAL["leaf_mid"], K.PAL["leaf_dark"], rnd.uniform(0.0, 0.4)) + (255,))
    # berries
    spots = [(-0.16, -0.05), (0.06, -0.12), (0.18, 0.06), (-0.05, 0.12), (0.0, -0.02), (-0.22, 0.12), (0.22, -0.04)]
    for bx, by in spots:
        r = s(h * (0.16 + rnd.uniform(-0.02, 0.03)))
        col = mix(K.PAL["berry_red"], K.PAL["berry_dark"], rnd.uniform(0.0, 0.4))
        shade_sphere(im, cx + s(w * bx), cy + s(h * by), r, col, light_dir=(-0.45, -0.55))
        # calyx dot
        soft_blob(im, cx + s(w * bx), cy + s(h * by) - r * 0.5, r * 0.12, r * 0.12, K.PAL["berry_dark"] + (200,))
    add_noise(im, 7, seed=8)
    save(im, w, h, "food_bush_berries_001.png")


def canopy_larva(w=360, h=337):
    """A plump caterpillar/larva on a leaf — big canopy food."""
    im, d = K.canvas(w, h)
    rnd = random.Random(13)
    # big supporting leaf
    tapered_leaf(im, s(w * 0.22), s(h * 0.66), s(w * 0.7), s(h * 0.5), math.radians(-18),
                 mix(K.PAL["leaf_mid"], K.PAL["leaf_dark"], 0.25) + (255,))
    # larva body — segmented along a gentle arc
    segs = 9
    base_col = K.PAL["larva_cream"]
    pts = []
    for i in range(segs):
        t = i / (segs - 1)
        x = s(w * (0.28 + 0.46 * t))
        y = s(h * (0.5 - 0.12 * math.sin(t * math.pi)))
        pts.append((x, y))
    for i, (x, y) in enumerate(pts):
        t = i / (segs - 1)
        r = s(h * (0.085 * math.sin(t * math.pi) + 0.05))
        col = mix(base_col, K.PAL["fruit_orange"], 0.12 + 0.1 * math.sin(t * math.pi))
        shade_sphere(im, x, y, r, col, light_dir=(-0.3, -0.6))
    # head
    hx, hy = pts[-1]
    shade_sphere(im, hx, hy, s(h * 0.075), mix(base_col, K.PAL["insect_brown"], 0.3), light_dir=(-0.3, -0.6))
    # tiny legs
    for (x, y) in pts[2:7]:
        d.line([(x, y + s(h * 0.06)), (x - s(w * 0.01), y + s(h * 0.11))], fill=K.PAL["insect_brown"] + (255,), width=s(3))
        d.line([(x, y + s(h * 0.06)), (x + s(w * 0.01), y + s(h * 0.11))], fill=K.PAL["insect_brown"] + (255,), width=s(3))
    add_noise(im, 8, seed=14)
    save(im, w, h, "food_canopy_larva_001.png")


def canopy_fruit(w=343, h=360):
    """A hanging cluster of orange canopy fruit."""
    im, d = K.canvas(w, h)
    rnd = random.Random(21)
    topx, topy = s(w * 0.5), s(h * 0.08)
    # branch + leaves at top
    d.line([(s(w * 0.2), s(h * 0.05)), (s(w * 0.8), s(h * 0.1))],
           fill=K.PAL["bark_dark"] + (255,), width=s(7))
    for ang, ln in [(-120, 0.3), (-60, 0.28), (-150, 0.24)]:
        tapered_leaf(im, s(w * 0.5), s(h * 0.1), s(w * ln), s(h * 0.2), math.radians(ang),
                     mix(K.PAL["leaf_mid"], K.PAL["leaf_light"], rnd.uniform(0, 0.4)) + (255,))
    # fruits hanging
    spots = [(0.34, 0.34), (0.58, 0.3), (0.46, 0.52), (0.66, 0.56), (0.3, 0.6), (0.52, 0.74)]
    for fx, fy in spots:
        r = s(w * (0.11 + rnd.uniform(-0.01, 0.02)))
        col = mix(K.PAL["fruit_orange"], K.PAL["berry_red"], rnd.uniform(0.0, 0.25))
        # stem
        d.line([(s(w * fx), s(h * 0.1)), (s(w * fx), s(h * fy) - r * 0.8)],
               fill=K.PAL["bark_brown"] + (200,), width=s(3))
        shade_sphere(im, s(w * fx), s(h * fy), r, col, light_dir=(-0.4, -0.5))
    add_noise(im, 7, seed=22)
    save(im, w, h, "food_canopy_fruit_cluster_001.png")


def warm_light_insects(w=180, h=130):
    """Night warm-light bugs: glowing amber swarm (positive food)."""
    im, d = K.canvas(w, h)
    rnd = random.Random(31)
    W, H = w * SS, h * SS
    # big warm glow halo
    im.alpha_composite(radial_glow(W, H, s(w * 0.5), s(h * 0.5), s(min(w, h) * 0.55),
                                   c("warm_glow", 150)))
    im.alpha_composite(radial_glow(W, H, s(w * 0.5), s(h * 0.5), s(min(w, h) * 0.30),
                                   c("warm_core", 210)))
    # individual glowing bugs
    for _ in range(7):
        bx = s(w * rnd.uniform(0.2, 0.8))
        by = s(h * rnd.uniform(0.25, 0.75))
        r = s(min(w, h) * rnd.uniform(0.05, 0.09))
        im.alpha_composite(radial_glow(W, H, bx, by, r * 2.4, c("warm_glow", 180)))
        soft_blob(im, bx, by, r, r, c("warm_core", 255), blur=s(1))
    save(im, w, h, "food_night_warm_light_insects_001.png")


def cold_false_light(w=144, h=144):
    """Night cold false-light lure (negative food): eerie blue-white glow."""
    im, d = K.canvas(w, h)
    rnd = random.Random(41)
    W, H = w * SS, h * SS
    cx, cy = s(w * 0.5), s(h * 0.5)
    im.alpha_composite(radial_glow(W, H, cx, cy, s(min(w, h) * 0.5), c("cold_glow", 140)))
    im.alpha_composite(radial_glow(W, H, cx, cy, s(min(w, h) * 0.26), c("cold_core", 220)))
    # cold core with faint cross-flare (artificial, unnatural)
    soft_blob(im, cx, cy, s(w * 0.08), s(h * 0.08), c("cold_core", 255), blur=s(2))
    for ang in (0, 90, 45, 135):
        a = math.radians(ang)
        d.line([(cx - math.cos(a) * s(w * 0.34), cy - math.sin(a) * s(h * 0.34)),
                (cx + math.cos(a) * s(w * 0.34), cy + math.sin(a) * s(h * 0.34))],
               fill=c("cold_glow", 70), width=s(2))
    save(im, w, h, "food_cold_false_light_001.png")


if __name__ == "__main__":
    print("FOOD →", OUT)
    ground_insect()
    seed_cluster()
    bush_berries()
    canopy_larva()
    canopy_fruit()
    warm_light_insects()
    cold_false_light()
