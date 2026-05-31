"""归途 — 障碍资产重绘（树木 + 灌木）
Trees are height-anchored (sprite center). Bushes are ground-anchored
(bottom of texture sits on ground), so foliage is weighted to lower half.
Native dimensions preserved.
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter
import common as K
from common import SS, s, c, mix, soft_blob, shade_sphere, add_noise, tapered_leaf

OUT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "environment", "obstacles"))


def save(im, w, h, name):
    out = K.finish(im, w, h)
    out.save(os.path.join(OUT, name))
    print("  ok", name, out.size)


def _foliage_mass(im, cx, cy, rx, ry, seed, light=K.PAL["leaf_light"], dark=K.PAL["leaf_dark"]):
    """Painterly clumped tree-crown / bush foliage."""
    rnd = random.Random(seed)
    # base dark mass
    soft_blob(im, cx, cy, rx, ry, dark + (255,), blur=s(6))
    # mid clumps
    n = int((rx * ry) / (SS * SS * 280)) + 14
    for _ in range(n):
        a = rnd.uniform(0, math.tau)
        rr = rnd.uniform(0.0, 1.0)
        px = cx + math.cos(a) * rx * 0.85 * rr
        py = cy + math.sin(a) * ry * 0.85 * rr
        cr = rnd.uniform(s(12), s(34))
        t = rnd.uniform(0.0, 1.0)
        # lighter toward upper-left (light source)
        lt = 0.5 - (py - cy) / (ry * 2.2) - (px - cx) / (rx * 3.0)
        col = mix(dark, light, max(0.0, min(1.0, 0.3 + lt * 0.8)) * t)
        soft_blob(im, px, py, cr, cr * 0.9, col + (235,), blur=s(3))


def tree_tall(w=541, h=582):
    """Tall slim tree, vertically centered."""
    im, d = K.canvas(w, h)
    rnd = random.Random(101)
    cx = s(w * 0.5)
    # trunk — tapered column drawn as horizontal spans
    trunk_top = s(h * 0.40)
    trunk_bot = s(h * 0.96)
    tw = s(w * 0.07)
    for yy in range(trunk_top, trunk_bot, max(1, SS // 2)):
        t = (yy - trunk_top) / (trunk_bot - trunk_top)
        hw = tw * (0.6 + 0.6 * t) * 0.5
        col = mix(K.PAL["bark_brown"], K.PAL["bark_dark"], 0.3 + 0.2 * math.sin(t * 6))
        # subtle lean + bark shading left→right
        lean = math.sin(t * 2.2) * s(w * 0.01)
        d.line([(cx - hw + lean, yy), (cx + hw + lean, yy)], fill=col + (255,), width=SS)
        d.line([(cx - hw + lean, yy), (cx - hw * 0.3 + lean, yy)],
               fill=mix(col, (0, 0, 0), 0.3) + (255,), width=SS)
    # a couple branches
    for by, ang, ln in [(0.5, -50, 0.2), (0.58, -130, 0.18)]:
        a = math.radians(ang)
        d.line([(cx, s(h * by)), (cx + math.cos(a) * s(w * ln), s(h * by) + math.sin(a) * s(w * ln))],
               fill=K.PAL["bark_dark"] + (255,), width=s(6))
    # crown — layered
    _foliage_mass(im, cx, s(h * 0.27), s(w * 0.40), s(h * 0.30), 102)
    _foliage_mass(im, cx - s(w * 0.14), s(h * 0.20), s(w * 0.22), s(h * 0.18), 103)
    _foliage_mass(im, cx + s(w * 0.16), s(h * 0.34), s(w * 0.22), s(h * 0.18), 104)
    add_noise(im, 7, seed=105)
    save(im, w, h, "obstacle_tree_tall_001.png")


def tree_food_points(w=468, h=540):
    """Broader tree with visible fruit/larva food points in canopy."""
    im, d = K.canvas(w, h)
    rnd = random.Random(111)
    cx = s(w * 0.5)
    trunk_top, trunk_bot = s(h * 0.46), s(h * 0.97)
    tw = s(w * 0.09)
    for yy in range(trunk_top, trunk_bot, max(1, SS // 2)):
        t = (yy - trunk_top) / (trunk_bot - trunk_top)
        hw = tw * (0.6 + 0.7 * t) * 0.5
        col = mix(K.PAL["bark_brown"], K.PAL["bark_dark"], 0.3 + 0.2 * math.sin(t * 5))
        d.line([(cx - hw, yy), (cx + hw, yy)], fill=col + (255,), width=SS)
        d.line([(cx - hw, yy), (cx - hw * 0.3, yy)],
               fill=mix(col, (0, 0, 0), 0.3) + (255,), width=SS)
    for by, ang, ln in [(0.55, -45, 0.24), (0.62, -135, 0.22), (0.5, -90, 0.12)]:
        a = math.radians(ang)
        d.line([(cx, s(h * by)), (cx + math.cos(a) * s(w * ln), s(h * by) + math.sin(a) * s(w * ln))],
               fill=K.PAL["bark_dark"] + (255,), width=s(7))
    # wide crown
    _foliage_mass(im, cx, s(h * 0.30), s(w * 0.46), s(h * 0.32), 112)
    _foliage_mass(im, cx - s(w * 0.22), s(h * 0.30), s(w * 0.20), s(h * 0.18), 113)
    _foliage_mass(im, cx + s(w * 0.22), s(h * 0.30), s(w * 0.20), s(h * 0.18), 114)
    # food points — fruit dots nestled in canopy
    rnd2 = random.Random(115)
    for _ in range(7):
        fx = cx + s(w * rnd2.uniform(-0.30, 0.30))
        fy = s(h * rnd2.uniform(0.18, 0.42))
        r = s(w * 0.028)
        col = mix(K.PAL["fruit_orange"], K.PAL["berry_red"], rnd2.uniform(0, 0.3))
        shade_sphere(im, fx, fy, r, col, light_dir=(-0.4, -0.5))
    add_noise(im, 7, seed=116)
    save(im, w, h, "obstacle_tree_food_points_001.png")


def bush_dense(w=469, h=323):
    """Dense low bush — foliage fills toward bottom (ground-anchored)."""
    im, d = K.canvas(w, h)
    cx, cy = s(w * 0.5), s(h * 0.66)
    # contact shadow
    soft_blob(im, cx, s(h * 0.92), s(w * 0.42), s(h * 0.08), (0, 0, 0, 80), blur=s(8))
    _foliage_mass(im, cx, cy, s(w * 0.46), s(h * 0.40), 201,
                  light=K.PAL["leaf_light"], dark=K.PAL["leaf_dark"])
    _foliage_mass(im, cx - s(w * 0.26), s(h * 0.72), s(w * 0.20), s(h * 0.24), 202)
    _foliage_mass(im, cx + s(w * 0.27), s(h * 0.72), s(w * 0.20), s(h * 0.24), 203)
    # a few twigs poking at base
    for tx in (-0.2, 0.05, 0.25):
        d.line([(cx + s(w * tx), s(h * 0.9)), (cx + s(w * tx * 0.7), s(h * 0.55))],
               fill=K.PAL["bark_dark"] + (180,), width=s(3))
    add_noise(im, 8, seed=204)
    save(im, w, h, "obstacle_bush_dense_001.png")


def bush_sparse(w=457, h=318):
    """Sparser bush — more gaps, lighter mass."""
    im, d = K.canvas(w, h)
    rnd = random.Random(211)
    cx = s(w * 0.5)
    soft_blob(im, cx, s(h * 0.92), s(w * 0.36), s(h * 0.07), (0, 0, 0, 70), blur=s(8))
    # a few separate clumps with visible branch structure
    clumps = [(-0.22, 0.62, 0.16), (0.05, 0.55, 0.20), (0.26, 0.66, 0.15)]
    # branches first
    for bx, by, _ in clumps:
        d.line([(cx, s(h * 0.95)), (cx + s(w * bx), s(h * by))],
               fill=K.PAL["bark_dark"] + (220,), width=s(4))
    for bx, by, r in clumps:
        _foliage_mass(im, cx + s(w * bx), s(h * by), s(w * r), s(h * r * 1.3), int(bx * 1000) + 212,
                      light=K.PAL["leaf_light"], dark=K.PAL["leaf_mid"])
    add_noise(im, 8, seed=214)
    save(im, w, h, "obstacle_bush_sparse_001.png")


if __name__ == "__main__":
    print("OBSTACLES →", OUT)
    tree_tall()
    tree_food_points()
    bush_dense()
    bush_sparse()
