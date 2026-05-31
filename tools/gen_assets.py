# -*- coding: utf-8 -*-
"""《归途》非背景/非角色美术资产程序化生成器（治愈系手绘水彩风）。

色板取自实际背景与小鸟贴图采样：
  白天天空 #6ba9b2 / 暖沙 #d8c6a4 / 森林绿 #415b43 / 橄榄 #909152 / 暗边 #0b262b
  夜色 #092d5a~#15396a / 雨天灰 #8a969d~#c1c5c8
  小鸟 背部暖棕 #795540 / 腹部奶白 #d9cfc7

所有资产保持与原文件完全一致的像素尺寸，就地替换。
运行：python tools/gen_assets.py
"""
import os
import math
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ART = os.path.join(os.path.dirname(__file__), "..", "assets", "art")
ART = os.path.normpath(ART)

# ----------------------------------------------------------------------------
# 色板
# ----------------------------------------------------------------------------
SKY        = (107, 169, 178)
SAND       = (216, 198, 164)
FOREST     = (65, 91, 67)
FOREST_DK  = (38, 58, 42)
OLIVE      = (144, 145, 82)
EDGE_DK    = (11, 38, 43)
BIRD_BROWN = (121, 85, 64)
BIRD_CREAM = (217, 207, 199)

NIGHT_DEEP = (9, 33, 66)
NIGHT_MID  = (21, 57, 106)
RAIN_GREY  = (138, 150, 157)
RAIN_LITE  = (193, 197, 200)

BERRY_RED  = (196, 74, 72)
BERRY_PINK = (214, 120, 132)
FRUIT_ORNG = (224, 126, 70)
SEED_BEIGE = (206, 178, 130)
LARVA_PALE = (232, 222, 176)
WARM_LIGHT = (250, 214, 130)
COLD_LIGHT = (208, 226, 240)
DANGER_RED = (192, 88, 79)
GOLD       = (244, 206, 120)
PANEL_CREAM = (226, 208, 170)
WOOD       = (150, 110, 72)
WOOD_DK    = (104, 74, 48)


def newimg(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def lowfreq_noise(w, h, cells=8, seed=0):
    """低频平滑噪声场 [0,1]，用于水彩颜色/透明度起伏。"""
    rs = np.random.RandomState(seed & 0x7fffffff)
    c = max(2, cells)
    small = (rs.rand(c, c) * 255).astype("uint8")
    img = Image.fromarray(small).resize((w, h), Image.BICUBIC)
    return np.asarray(img).astype(float) / 255.0


def paint_blob(size, cx, cy, rx, ry, color, *, wobble=0.12, blur=6,
               grain=0.20, alpha=255, seed=0, jitter=14, points=40):
    """一团手绘水彩色块：抖动边缘 + 柔边 + 颗粒 + 颜色起伏。"""
    w, h = size
    rnd = random.Random(seed)
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    pts = []
    for i in range(points):
        a = 2 * math.pi * i / points
        rr = 1.0 + rnd.uniform(-wobble, wobble)
        pts.append((cx + math.cos(a) * rx * rr, cy + math.sin(a) * ry * rr))
    d.polygon(pts, fill=int(alpha))
    if blur:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    m = np.asarray(mask).astype(float) / 255.0
    if grain > 0:
        n = lowfreq_noise(w, h, cells=max(6, int(min(w, h) / 18)), seed=seed + 7)
        m = m * (1.0 - grain + grain * n)
    cj = lowfreq_noise(w, h, cells=6, seed=seed + 31) * 2.0 - 1.0
    col = np.zeros((h, w, 3))
    for k in range(3):
        col[:, :, k] = np.clip(color[k] + cj * jitter, 0, 255)
    out = np.dstack([col, np.clip(m, 0, 1) * 255.0]).astype("uint8")
    return Image.fromarray(out, "RGBA")


def comp(base, layer):
    base.alpha_composite(layer)


def dry_strokes(size, region, color, n, length, seed=0, alpha=70, width=2):
    """短促干刷笔触，用于草叶/水波/雨纹质感。"""
    w, h = size
    img = newimg(w, h)
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    x0, y0, x1, y1 = region
    for _ in range(n):
        sx = rnd.uniform(x0, x1)
        sy = rnd.uniform(y0, y1)
        ang = rnd.uniform(-0.5, 0.5) - math.pi / 2
        ln = length * rnd.uniform(0.6, 1.2)
        ex = sx + math.cos(ang) * ln
        ey = sy + math.sin(ang) * ln
        a = int(alpha * rnd.uniform(0.5, 1.0))
        d.line([(sx, sy), (ex, ey)], fill=color + (a,), width=width)
    return img.filter(ImageFilter.GaussianBlur(0.6))


def radial_glow(size, cx, cy, r, color, *, inner=255, gamma=1.8):
    """柔和径向辉光。"""
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r
    a = np.clip(1.0 - dist, 0, 1) ** gamma * inner
    col = np.zeros((h, w, 4))
    col[:, :, 0] = color[0]
    col[:, :, 1] = color[1]
    col[:, :, 2] = color[2]
    col[:, :, 3] = a
    return Image.fromarray(col.astype("uint8"), "RGBA")


def save(img, rel, expect=None):
    path = os.path.join(ART, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if expect and img.size != expect:
        img = img.resize(expect, Image.LANCZOS)
    img.save(path)
    return path, img.size


# ----------------------------------------------------------------------------
# 障碍物
# ----------------------------------------------------------------------------
def gen_obstacle_tree_tall():
    W, H = 541, 582
    img = newimg(W, H)
    # 树干
    trunk = newimg(W, H)
    d = ImageDraw.Draw(trunk)
    cx = W * 0.5
    pts = [(cx - 34, H), (cx - 22, H * 0.52), (cx - 10, H * 0.42),
           (cx + 12, H * 0.42), (cx + 24, H * 0.52), (cx + 36, H)]
    d.polygon(pts, fill=WOOD_DK + (255,))
    comp(img, trunk.filter(ImageFilter.GaussianBlur(1.5)))
    comp(img, paint_blob((W, H), cx + 14, H * 0.7, 12, 120, WOOD,
                         wobble=0.25, blur=4, alpha=150, seed=2))
    # 树冠：多团叠加
    crown = [(cx, H * 0.30, 190, 150, FOREST, 11),
             (cx - 120, H * 0.34, 120, 100, FOREST_DK, 12),
             (cx + 120, H * 0.33, 125, 105, OLIVE, 13),
             (cx - 40, H * 0.18, 140, 110, OLIVE, 14),
             (cx + 50, H * 0.20, 130, 105, FOREST, 15),
             (cx, H * 0.40, 200, 120, FOREST_DK, 16)]
    for x, y, rx, ry, col, s in crown:
        comp(img, paint_blob((W, H), x, y, rx, ry, col,
                             wobble=0.18, blur=10, grain=0.24, seed=s))
    # 底部暗边强化轮廓
    comp(img, paint_blob((W, H), cx, H * 0.46, 195, 70, EDGE_DK,
                         wobble=0.2, blur=14, alpha=120, seed=17))
    # 顶部高光小色块
    comp(img, paint_blob((W, H), cx - 30, H * 0.16, 70, 50, (170, 178, 110),
                         wobble=0.3, blur=8, alpha=130, seed=18))
    return save(img, "environment/obstacles/obstacle_tree_tall_001.png", (W, H))


def gen_obstacle_tree_food():
    W, H = 468, 540
    img = newimg(W, H)
    cx = W * 0.5
    trunk = newimg(W, H)
    d = ImageDraw.Draw(trunk)
    d.polygon([(cx - 30, H), (cx - 18, H * 0.55), (cx + 14, H * 0.55), (cx + 30, H)],
              fill=WOOD_DK + (255,))
    comp(img, trunk.filter(ImageFilter.GaussianBlur(1.5)))
    crown = [(cx, H * 0.32, 175, 140, FOREST, 21),
             (cx - 110, H * 0.36, 110, 95, FOREST_DK, 22),
             (cx + 110, H * 0.35, 115, 98, OLIVE, 23),
             (cx, H * 0.20, 140, 105, OLIVE, 24),
             (cx, H * 0.42, 185, 110, FOREST_DK, 25)]
    for x, y, rx, ry, col, s in crown:
        comp(img, paint_blob((W, H), x, y, rx, ry, col,
                             wobble=0.18, blur=10, grain=0.24, seed=s))
    # 树上果实/虫蛹意象（暖红 + 淡黄悬挂）
    for fx, fy, col in [(cx - 80, H * 0.40, FRUIT_ORNG), (cx + 70, H * 0.30, BERRY_RED),
                        (cx + 20, H * 0.46, FRUIT_ORNG), (cx - 30, H * 0.26, FRUIT_ORNG)]:
        comp(img, paint_blob((W, H), fx, fy, 16, 18, col, wobble=0.12, blur=3, seed=int(fx)))
        comp(img, paint_blob((W, H), fx - 4, fy - 5, 5, 6, (255, 240, 210),
                             wobble=0.2, blur=2, alpha=180, seed=int(fx) + 1))
    for lx, ly in [(cx - 40, H * 0.50), (cx + 95, H * 0.48)]:
        d2 = ImageDraw.Draw(img)
        d2.line([(lx, ly - 26), (lx, ly)], fill=(70, 78, 50, 150), width=2)
        comp(img, paint_blob((W, H), lx, ly + 6, 11, 16, LARVA_PALE,
                             wobble=0.12, blur=2, seed=int(lx)))
    comp(img, paint_blob((W, H), cx, H * 0.46, 180, 60, EDGE_DK,
                         wobble=0.2, blur=14, alpha=110, seed=29))
    return save(img, "environment/obstacles/obstacle_tree_food_points_001.png", (W, H))


def gen_bush_dense():
    W, H = 469, 323
    img = newimg(W, H)
    blobs = [(W * 0.5, H * 0.62, 210, 150, FOREST_DK, 41),
             (W * 0.25, H * 0.66, 120, 110, FOREST_DK, 42),
             (W * 0.75, H * 0.66, 125, 112, FOREST, 43),
             (W * 0.42, H * 0.42, 130, 110, FOREST, 44),
             (W * 0.62, H * 0.46, 120, 100, FOREST_DK, 45),
             (W * 0.5, H * 0.78, 230, 110, EDGE_DK, 46)]
    for x, y, rx, ry, col, s in blobs:
        comp(img, paint_blob((W, H), x, y, rx, ry, col,
                             wobble=0.16, blur=9, grain=0.26, seed=s))
    # 少量叶片点缀（深绿，无明显通路）
    comp(img, dry_strokes((W, H), (W * 0.15, H * 0.25, W * 0.85, H * 0.7),
                          (52, 72, 50), 70, 22, seed=47, alpha=60, width=2))
    return save(img, "environment/obstacles/obstacle_bush_dense_001.png", (W, H))


def gen_bush_sparse():
    W, H = 457, 318
    img = newimg(W, H)
    blobs = [(W * 0.30, H * 0.64, 120, 100, OLIVE, 51),
             (W * 0.68, H * 0.62, 115, 98, FOREST, 52),
             (W * 0.50, H * 0.74, 150, 80, FOREST_DK, 53)]
    for x, y, rx, ry, col, s in blobs:
        comp(img, paint_blob((W, H), x, y, rx, ry, col,
                             wobble=0.22, blur=11, grain=0.28, alpha=235, seed=s))
    # 可见浆果（红/粉），暗示可穿透留空隙
    for bx, by in [(W * 0.30, H * 0.6), (W * 0.36, H * 0.66), (W * 0.66, H * 0.58),
                   (W * 0.7, H * 0.64), (W * 0.5, H * 0.7)]:
        comp(img, paint_blob((W, H), bx, by, 11, 12, BERRY_RED, wobble=0.12, blur=2, seed=int(bx)))
        comp(img, paint_blob((W, H), bx - 3, by - 3, 3, 4, (255, 220, 210),
                             wobble=0.2, blur=1, alpha=190, seed=int(bx) + 1))
    comp(img, dry_strokes((W, H), (W * 0.15, H * 0.3, W * 0.85, H * 0.7),
                          (120, 130, 70), 50, 20, seed=57, alpha=55, width=2))
    return save(img, "environment/obstacles/obstacle_bush_sparse_001.png", (W, H))


# ----------------------------------------------------------------------------
# 食物
# ----------------------------------------------------------------------------
def gen_food_ground_insect():
    W, H = 96, 64
    img = newimg(W, H)
    comp(img, paint_blob((W, H), W * 0.5, H * 0.58, 20, 13, (58, 52, 48),
                         wobble=0.1, blur=2, seed=61))
    comp(img, paint_blob((W, H), W * 0.42, H * 0.5, 7, 5, BIRD_CREAM,
                         wobble=0.2, blur=1, alpha=200, seed=62))
    d = ImageDraw.Draw(img)
    for dx in (-1, 1):
        d.line([(W * 0.5, H * 0.6), (W * 0.5 + dx * 16, H * 0.82)], fill=(40, 36, 34, 180), width=2)
    d.line([(W * 0.62, H * 0.5), (W * 0.78, H * 0.34)], fill=(40, 36, 34, 160), width=1)
    return save(img, "food/food_ground_insect_001.png", (W, H))


def gen_food_seed():
    W, H = 96, 64
    img = newimg(W, H)
    # 暗色柔光底，让米黄种子从暖沙背景上跳出来（可读性）
    comp(img, paint_blob((W, H), W * 0.5, H * 0.62, 34, 20, (74, 58, 40),
                         wobble=0.2, blur=6, alpha=150, seed=69))
    rnd = random.Random(70)
    cols = [SEED_BEIGE, (172, 134, 88), (224, 202, 150)]
    for i in range(11):
        x = W * 0.5 + rnd.uniform(-26, 26)
        y = H * 0.62 + rnd.uniform(-12, 12)
        rx, ry = rnd.uniform(6, 9), rnd.uniform(4, 6)
        # 深色描边垫底，增强与沙地的边界对比
        comp(img, paint_blob((W, H), x, y, rx + 1.6, ry + 1.6, (96, 70, 44),
                             wobble=0.18, blur=1, alpha=210, seed=69 + i))
        comp(img, paint_blob((W, H), x, y, rx, ry,
                             rnd.choice(cols), wobble=0.18, blur=1, seed=70 + i))
        comp(img, paint_blob((W, H), x - rx * 0.3, y - ry * 0.3, rx * 0.3, ry * 0.3,
                             (245, 232, 200), wobble=0.2, blur=1, alpha=190, seed=170 + i))
    return save(img, "food/food_seed_cluster_001.png", (W, H))


def gen_food_berries():
    W, H = 132, 96
    img = newimg(W, H)
    # 两片叶
    comp(img, paint_blob((W, H), W * 0.36, H * 0.3, 24, 13, FOREST, wobble=0.2, blur=3, seed=80))
    comp(img, paint_blob((W, H), W * 0.62, H * 0.32, 22, 12, OLIVE, wobble=0.2, blur=3, seed=81))
    berries = [(W * 0.40, H * 0.58, BERRY_RED), (W * 0.56, H * 0.55, BERRY_PINK),
               (W * 0.48, H * 0.72, BERRY_RED), (W * 0.64, H * 0.70, BERRY_RED),
               (W * 0.34, H * 0.72, BERRY_PINK)]
    for bx, by, col in berries:
        comp(img, paint_blob((W, H), bx, by, 14, 15, col, wobble=0.1, blur=2, seed=int(bx * by)))
        comp(img, paint_blob((W, H), bx - 4, by - 5, 4, 5, (255, 230, 224),
                             wobble=0.2, blur=1, alpha=200, seed=int(bx * by) + 1))
    return save(img, "food/food_bush_berries_001.png", (W, H))


def gen_food_larva():
    W, H = 360, 337
    img = newimg(W, H)
    d = ImageDraw.Draw(img)
    cx = W * 0.5
    d.line([(cx, 12), (cx, H * 0.42)], fill=(78, 86, 56, 170), width=3)
    comp(img, paint_blob((W, H), cx, H * 0.62, 70, 105, LARVA_PALE,
                         wobble=0.1, blur=8, grain=0.18, seed=90))
    comp(img, paint_blob((W, H), cx - 18, H * 0.5, 26, 40, (250, 244, 210),
                         wobble=0.15, blur=8, alpha=160, seed=91))
    # 体节线
    for i in range(4):
        yy = H * (0.48 + i * 0.1)
        d.arc([cx - 52, yy - 14, cx + 52, yy + 14], 200, 340, fill=(206, 192, 140, 150), width=3)
    return save(img, "food/food_canopy_larva_001.png", (W, H))


def gen_food_fruit():
    W, H = 343, 360
    img = newimg(W, H)
    d = ImageDraw.Draw(img)
    comp(img, paint_blob((W, H), W * 0.55, H * 0.22, 40, 22, FOREST, wobble=0.2, blur=4, seed=100))
    fruits = [(W * 0.40, H * 0.58, 70, FRUIT_ORNG), (W * 0.62, H * 0.55, 64, BERRY_RED),
              (W * 0.52, H * 0.78, 60, FRUIT_ORNG)]
    for fx, fy, r, col in fruits:
        d.line([(fx, fy - r), (W * 0.52, H * 0.3)], fill=(96, 70, 48, 170), width=3)
        comp(img, paint_blob((W, H), fx, fy, r, r * 1.05, col, wobble=0.08, blur=5, grain=0.16, seed=int(fx)))
        comp(img, paint_blob((W, H), fx - r * 0.3, fy - r * 0.35, r * 0.28, r * 0.32,
                             (255, 234, 200), wobble=0.2, blur=4, alpha=170, seed=int(fx) + 1))
    return save(img, "food/food_canopy_fruit_cluster_001.png", (W, H))


def gen_food_warm_light():
    W, H = 180, 130
    img = newimg(W, H)
    pts = [(W * 0.5, H * 0.5, 1.0), (W * 0.3, H * 0.4, 0.7), (W * 0.7, H * 0.62, 0.8)]
    for x, y, s in pts:
        comp(img, radial_glow((W, H), x, y, 46 * s, WARM_LIGHT, inner=int(150 * s), gamma=2.0))
    for x, y, s in pts:
        comp(img, paint_blob((W, H), x, y, 5, 5, (255, 248, 220), wobble=0.2, blur=1,
                             alpha=int(230 * s), seed=int(x + y)))
    return save(img, "food/food_night_warm_light_insects_001.png", (W, H))


def gen_food_cold_light():
    W, H = 144, 144
    img = newimg(W, H)
    comp(img, radial_glow((W, H), W * 0.5, H * 0.5, 60, COLD_LIGHT, inner=140, gamma=2.2))
    comp(img, radial_glow((W, H), W * 0.5, H * 0.5, 26, (236, 246, 255), inner=200, gamma=1.6))
    comp(img, paint_blob((W, H), W * 0.5, H * 0.5, 5, 7, (245, 250, 255),
                         wobble=0.2, blur=1, alpha=230, seed=110))
    return save(img, "food/food_cold_false_light_001.png", (W, H))


# ----------------------------------------------------------------------------
# 天敌（深色剪影，约小鸟 2x，深蓝/墨绿）
# ----------------------------------------------------------------------------
def _raptor_mask(W, H, pose):
    """返回猛禽剪影 L 通道（从下方看的展翅鹰，朝向无关，左右对称）。"""
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    cx, cy = W * 0.5, H * 0.5
    if pose == "dash":
        wing_dx, wing_dy, tip_dy = 0.46, 0.06, 0.30
        body_ry = 0.40
    elif pose == "aim":
        wing_dx, wing_dy, tip_dy = 0.44, -0.10, 0.05
        body_ry = 0.34
    else:  # hover
        wing_dx, wing_dy, tip_dy = 0.48, -0.18, -0.02
        body_ry = 0.32
    # 身体
    d.ellipse([cx - W * 0.07, cy - H * body_ry, cx + W * 0.07, cy + H * body_ry], fill=255)
    # 头
    d.ellipse([cx - W * 0.05, cy - H * (body_ry + 0.12), cx + W * 0.05, cy - H * (body_ry - 0.02)], fill=255)
    # 两翼（对称多边形）
    for sgn in (-1, 1):
        wing = [
            (cx, cy - H * 0.14),
            (cx + sgn * W * wing_dx, cy - H * (0.14 + wing_dy)),
            (cx + sgn * W * (wing_dx + 0.02), cy + H * tip_dy),
            (cx + sgn * W * 0.18, cy + H * 0.10),
            (cx, cy + H * 0.06),
        ]
        d.polygon(wing, fill=255)
    # 尾
    d.polygon([(cx - W * 0.06, cy + H * body_ry * 0.7),
               (cx + W * 0.06, cy + H * body_ry * 0.7),
               (cx, cy + H * (body_ry + 0.16))], fill=255)
    return m.filter(ImageFilter.GaussianBlur(1.2))


def _raptor_image(W, H, pose, color=(27, 42, 58), alpha=255):
    mask = _raptor_mask(W, H, pose)
    arr = np.asarray(mask).astype(float) / 255.0
    # 颜色起伏，保留剪影但有手绘体积
    cj = lowfreq_noise(W, H, cells=6, seed=200) * 2 - 1
    out = np.zeros((H, W, 4))
    for k in range(3):
        out[:, :, k] = np.clip(color[k] + cj * 10, 0, 255)
    out[:, :, 3] = arr * alpha
    return Image.fromarray(out.astype("uint8"), "RGBA")


def gen_predator_poses():
    W, H = 288, 144
    results = []
    for pose, name in [("hover", "predator_hawk_hover_001.png"),
                       ("aim", "predator_hawk_aim_001.png"),
                       ("dash", "predator_hawk_dash_001.png")]:
        img = _raptor_image(W, H, pose, color=(25, 40, 56))
        results.append(save(img, "characters/predators/" + name, (W, H)))
    # 残影：dash 剪影 + 半透明拖尾
    after = newimg(W, H)
    for i, a in enumerate([60, 100, 150]):
        layer = _raptor_image(W, H, "dash", color=(40, 60, 86), alpha=a)
        off = newimg(W, H)
        off.alpha_composite(layer, (int(-i * 22), int(i * 4)))
        comp(after, off)
    comp(after, _raptor_image(W, H, "dash", color=(25, 40, 56), alpha=255))
    results.append(save(after, "characters/predators/predator_hawk_afterimage_001.png", (W, H)))
    return results


def gen_predator_trajectory():
    W, H = 512, 80
    img = newimg(W, H)
    # 克制的红色虚线轨迹，左向（指向小鸟），柔边渐隐
    d = ImageDraw.Draw(img)
    cy = H * 0.5
    x = 8
    while x < W - 20:
        seg = random.Random(int(x)).uniform(18, 30)
        a = int(150 * (x / W))  # 越靠目标（左）越淡？这里右端蓄力端更亮
        a = int(60 + 120 * (1 - x / W))
        d.line([(x, cy), (x + seg, cy)], fill=DANGER_RED + (a,), width=5)
        x += seg + 16
    img = img.filter(ImageFilter.GaussianBlur(1.4))
    # 箭头（指向左）
    d2 = ImageDraw.Draw(img)
    d2.polygon([(10, cy), (34, cy - 14), (34, cy + 14)], fill=DANGER_RED + (200,))
    return save(img, "characters/predators/predator_attack_trajectory_001.png", (W, H))


# ----------------------------------------------------------------------------
# 天气（全屏 1280x720）
# ----------------------------------------------------------------------------
def _rain_layer(W, H, n, width, alpha, length, slant, color, seed):
    img = newimg(W, H)
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    for _ in range(n):
        x = rnd.uniform(-50, W)
        y = rnd.uniform(-50, H)
        a = int(alpha * rnd.uniform(0.5, 1.0))
        d.line([(x, y), (x + slant, y + length)], fill=color + (a,), width=width)
    return img


def gen_weather_drizzle():
    W, H = 1280, 720
    img = _rain_layer(W, H, 140, 1, 70, 38, 10, (210, 220, 226), 300)
    return save(img, "weather/weather_drizzle_lines_001.png", (W, H))


def gen_weather_rain():
    W, H = 1280, 720
    img = newimg(W, H)
    comp(img, _rain_layer(W, H, 360, 2, 95, 60, 18, (200, 212, 220), 310))
    comp(img, _rain_layer(W, H, 180, 1, 70, 44, 14, (220, 228, 234), 311))
    return save(img, "weather/weather_rain_lines_001.png", (W, H))


def gen_weather_storm():
    W, H = 1280, 720
    img = newimg(W, H)
    comp(img, _rain_layer(W, H, 520, 2, 110, 70, 22, (196, 206, 214), 320))
    # 水雾横带
    mist = newimg(W, H)
    rnd = random.Random(321)
    for _ in range(6):
        y = rnd.uniform(0, H)
        comp(mist, paint_blob((W, H), rnd.uniform(0, W), y, rnd.uniform(300, 520),
                              rnd.uniform(60, 130), RAIN_LITE, wobble=0.3, blur=40,
                              alpha=70, grain=0.1, seed=int(y)))
    comp(img, mist)
    return save(img, "weather/weather_storm_mist_001.png", (W, H))


# ----------------------------------------------------------------------------
# 时间/夜航覆盖层（全屏）
# ----------------------------------------------------------------------------
def _vgrad(W, H, top, bottom, top_a, bottom_a):
    arr = np.zeros((H, W, 4))
    for y in range(H):
        t = y / (H - 1)
        for k in range(3):
            arr[y, :, k] = top[k] * (1 - t) + bottom[k] * t
        arr[y, :, 3] = top_a * (1 - t) + bottom_a * t
    return Image.fromarray(arr.astype("uint8"), "RGBA")


def gen_overlay_dusk():
    W, H = 1280, 720
    img = _vgrad(W, H, (250, 170, 120), (90, 70, 120), 110, 90)
    return save(img, "environment/overlays/overlay_dusk_tint_001.png", (W, H))


def gen_overlay_night():
    W, H = 1280, 720
    img = _vgrad(W, H, (12, 30, 70), (6, 18, 44), 165, 195)
    return save(img, "environment/overlays/overlay_night_tint_001.png", (W, H))


def gen_overlay_dawn():
    W, H = 1280, 720
    img = _vgrad(W, H, (255, 222, 180), (150, 180, 190), 95, 60)
    comp(img, radial_glow((W, H), W * 0.2, H * 0.3, 480, (255, 236, 200), inner=90, gamma=2.2))
    return save(img, "environment/overlays/overlay_dawn_transition_001.png", (W, H))


def gen_overlay_stars():
    W, H = 1280, 720
    img = newimg(W, H)
    d = ImageDraw.Draw(img)
    rnd = random.Random(400)
    for _ in range(150):
        x = rnd.uniform(0, W)
        y = rnd.uniform(0, H * 0.7)
        r = rnd.uniform(0.6, 2.2)
        a = int(rnd.uniform(80, 220) * (1 - y / H))
        col = rnd.choice([(255, 255, 245), (220, 230, 255), (255, 240, 210)])
        d.ellipse([x - r, y - r, x + r, y + r], fill=col + (a,))
    # 少量较亮星带光晕
    for _ in range(8):
        x = rnd.uniform(0, W); y = rnd.uniform(0, H * 0.5)
        comp(img, radial_glow((W, H), x, y, 10, (255, 255, 240), inner=120, gamma=2.0))
    return save(img, "environment/overlays/overlay_stars_distant_lights_001.png", (W, H))


def gen_overlay_grey_cloud():
    W, H = 1280, 720
    img = newimg(W, H)
    rnd = random.Random(410)
    for _ in range(7):
        x = rnd.uniform(W * 0.2, W)
        y = rnd.uniform(H * 0.1, H * 0.5)
        comp(img, paint_blob((W, H), x, y, rnd.uniform(260, 420), rnd.uniform(110, 170),
                             (96, 104, 112), wobble=0.3, blur=50, alpha=120, grain=0.12, seed=int(x)))
    return save(img, "environment/overlays/weather_grey_cloud_warning_overlay_001.png", (W, H))


# ----------------------------------------------------------------------------
# HUD
# ----------------------------------------------------------------------------
def _soft_panel(W, H, color, radius, *, border=None, alpha=235, pad=4):
    img = newimg(W, H)
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([pad, pad, W - pad, H - pad], radius=radius, fill=alpha)
    mask = mask.filter(ImageFilter.GaussianBlur(2))
    base = Image.new("RGBA", (W, H), color + (255,))
    base.putalpha(mask)
    img.alpha_composite(base)
    if border:
        b = Image.new("L", (W, H), 0)
        ImageDraw.Draw(b).rounded_rectangle([pad, pad, W - pad, H - pad], radius=radius,
                                            outline=255, width=max(2, H // 40))
        bcol = Image.new("RGBA", (W, H), border + (255,))
        bcol.putalpha(b.filter(ImageFilter.GaussianBlur(1)))
        img.alpha_composite(bcol)
    return img


def gen_hud_hunger():
    W, H = 620, 160
    img = _soft_panel(W, H, (44, 52, 46), 60, border=(226, 208, 170), alpha=150)
    # 左侧麦穗/种子暖色徽标
    comp(img, paint_blob((W, H), 95, H * 0.5, 30, 46, (224, 196, 120), wobble=0.12, blur=4, seed=500))
    d = ImageDraw.Draw(img)
    for i in range(5):
        yy = H * 0.3 + i * 16
        d.line([(95, yy), (78, yy - 8)], fill=(180, 150, 80, 220), width=4)
        d.line([(95, yy), (112, yy - 8)], fill=(180, 150, 80, 220), width=4)
    # 右侧凹槽（数值条占位）
    comp(img, _soft_panel(W, H, (26, 30, 32), 36, alpha=130, pad=0).crop((160, 50, 600, 110)).resize((440, 60)) if False else newimg(W, H))
    slot = newimg(W, H)
    ImageDraw.Draw(slot).rounded_rectangle([150, 54, 596, 108], radius=26, fill=(20, 24, 26, 120))
    comp(img, slot)
    return save(img, "ui/hud/ui_hunger_meter_001.png", (W, H))


def gen_hud_height():
    W, H = 90, 360
    img = _soft_panel(W, H, (40, 56, 60), 36, border=(200, 214, 210), alpha=140)
    d = ImageDraw.Draw(img)
    # 渐变：上蓝下绿
    grad = _vgrad(W, H, (110, 170, 180), (110, 140, 80), 120, 120)
    gm = Image.new("L", (W, H), 0)
    ImageDraw.Draw(gm).rounded_rectangle([20, 14, W - 20, H - 14], radius=18, fill=255)
    grad.putalpha(gm)
    comp(img, grad)
    # 刻度
    for i in range(11):
        yy = 18 + i * (H - 36) / 10
        w = 16 if i % 5 == 0 else 9
        d.line([(W * 0.5 - w, yy), (W * 0.5 + w, yy)], fill=(255, 255, 250, 180), width=2)
    # 小鸟标记
    comp(img, paint_blob((W, H), W * 0.5, H * 0.4, 12, 8, BIRD_BROWN, wobble=0.2, blur=1, seed=510))
    return save(img, "ui/hud/ui_height_meter_001.png", (W, H))


def gen_hud_wetness():
    W, H = 260, 84
    img = _soft_panel(W, H, (32, 48, 64), 30, border=(150, 190, 230), alpha=150)
    # 水滴徽标
    comp(img, paint_blob((W, H), 40, H * 0.5, 18, 24, (90, 150, 210), wobble=0.1, blur=3, seed=520))
    comp(img, paint_blob((W, H), 34, H * 0.42, 5, 7, (200, 230, 255), wobble=0.2, blur=1, alpha=200, seed=521))
    slot = newimg(W, H)
    ImageDraw.Draw(slot).rounded_rectangle([74, 30, 240, 56], radius=13, fill=(20, 30, 40, 120))
    comp(img, slot)
    return save(img, "ui/hud/ui_wetness_meter_001.png", (W, H))


def gen_hud_distance_sign():
    W, H = 520, 233
    img = newimg(W, H)
    # 木桩
    d = ImageDraw.Draw(img)
    for px in (W * 0.30, W * 0.70):
        comp(img, paint_blob((W, H), px, H * 0.72, 14, 80, WOOD_DK, wobble=0.18, blur=3, seed=int(px)))
    # 木牌
    board = _soft_panel(W, H, WOOD, 28, border=WOOD_DK, alpha=245)
    bm = Image.new("L", (W, H), 0)
    ImageDraw.Draw(bm).rounded_rectangle([40, 26, W - 40, 150], radius=24, fill=255)
    board.putalpha(bm.filter(ImageFilter.GaussianBlur(2)))
    comp(img, board)
    # 木纹
    comp(img, dry_strokes((W, H), (60, 40, W - 60, 140), (120, 88, 58), 40, 30, seed=530, alpha=60, width=2))
    # 中央留浅色区给代码文字
    center = newimg(W, H)
    ImageDraw.Draw(center).rounded_rectangle([70, 44, W - 70, 132], radius=18, fill=(232, 214, 178, 90))
    comp(img, center)
    return save(img, "ui/hud/ui_distance_sign_001.png", (W, H))


def gen_hud_night_timer():
    """6 帧 240x240：月相+柔光脉动。"""
    fw, fh, n = 240, 240, 6
    sheet = newimg(fw * n, fh)
    for i in range(n):
        f = newimg(fw, fh)
        cx, cy = fw * 0.5, fh * 0.5
        pulse = 0.5 + 0.5 * math.sin(i / n * 2 * math.pi)
        comp(f, radial_glow((fw, fh), cx, cy, 96, (150, 170, 220), inner=int(70 + 60 * pulse), gamma=2.2))
        # 月盘
        comp(f, paint_blob((fw, fh), cx, cy, 58, 58, (236, 240, 250), wobble=0.06, blur=4, seed=540))
        # 阴影盘做月相（随帧移动）
        shadow_dx = (i / (n - 1) * 2 - 1) * 64
        sh = newimg(fw, fh)
        ImageDraw.Draw(sh).ellipse([cx - 58 + shadow_dx, cy - 58, cx + 58 + shadow_dx, cy + 58],
                                   fill=(14, 26, 52, 235))
        sh = sh.filter(ImageFilter.GaussianBlur(3))
        # 仅在月盘范围内裁剪阴影
        moon_mask = Image.new("L", (fw, fh), 0)
        ImageDraw.Draw(moon_mask).ellipse([cx - 58, cy - 58, cx + 58, cy + 58], fill=255)
        sh.putalpha(Image.composite(sh.getchannel("A"), Image.new("L", (fw, fh), 0), moon_mask))
        comp(f, sh)
        # 小星点
        d = ImageDraw.Draw(f)
        for sx, sy in [(40, 50), (200, 70), (60, 190), (190, 195)]:
            d.ellipse([sx - 2, sy - 2, sx + 2, sy + 2], fill=(255, 255, 240, 200))
        sheet.alpha_composite(f, (i * fw, 0))
    return save(sheet, "ui/hud/ui_night_timer_001.png", (fw * n, fh))


def gen_hud_warning_arrow():
    """4 帧 156x126：克制红橙警告箭头脉动。"""
    fw, fh, n = 156, 126, 4
    sheet = newimg(fw * n, fh)
    for i in range(n):
        f = newimg(fw, fh)
        pulse = [0.6, 1.0, 0.8, 0.5][i]
        cx, cy = fw * 0.5, fh * 0.5
        comp(f, radial_glow((fw, fh), cx, cy, 70, (220, 120, 90), inner=int(70 * pulse), gamma=2.0))
        scale = 0.8 + 0.2 * pulse
        aw, ah = 52 * scale, 40 * scale
        d = ImageDraw.Draw(f)
        col = (210, 96, 78, int(200 + 55 * pulse))
        # 右指箭头（威胁来自右侧）
        d.polygon([(cx - aw, cy - ah * 0.5), (cx, cy - ah * 0.5), (cx, cy - ah),
                   (cx + aw, cy), (cx, cy + ah), (cx, cy + ah * 0.5),
                   (cx - aw, cy + ah * 0.5)], fill=col)
        f = f.filter(ImageFilter.GaussianBlur(0.8))
        sheet.alpha_composite(f, (i * fw, 0))
    return save(sheet, "ui/hud/ui_warning_arrow_001.png", (fw * n, fh))


# ----------------------------------------------------------------------------
# 菜单面板
# ----------------------------------------------------------------------------
def gen_menu_panel():
    W, H = 820, 586
    img = _soft_panel(W, H, PANEL_CREAM, 48, border=(150, 110, 72), alpha=244, pad=14)
    # 纸纹
    comp(img, dry_strokes((W, H), (40, 40, W - 40, H - 40), (200, 180, 140), 120, 40,
                          seed=600, alpha=30, width=2))
    # 顶部装饰条
    bar = newimg(W, H)
    ImageDraw.Draw(bar).rounded_rectangle([60, 40, W - 60, 96], radius=24, fill=(150, 110, 72, 120))
    comp(img, bar)
    # 四角小叶片点缀
    for cxp, cyp in [(70, 70), (W - 70, 70), (70, H - 70), (W - 70, H - 70)]:
        comp(img, paint_blob((W, H), cxp, cyp, 18, 10, FOREST, wobble=0.3, blur=3, alpha=150, seed=int(cxp + cyp)))
    return save(img, "ui/menus/ui_pause_and_game_over_panels_001.png", (W, H))


# ----------------------------------------------------------------------------
# VFX
# ----------------------------------------------------------------------------
def gen_vfx_pickup_burst():
    W, H = 385, 420
    img = newimg(W, H)
    cx, cy = W * 0.5, H * 0.5
    comp(img, radial_glow((W, H), cx, cy, 120, GOLD, inner=120, gamma=2.2))
    d = ImageDraw.Draw(img)
    rnd = random.Random(700)
    for i in range(16):
        a = 2 * math.pi * i / 16 + rnd.uniform(-0.1, 0.1)
        r0 = 40; r1 = rnd.uniform(120, 170)
        x0, y0 = cx + math.cos(a) * r0, cy + math.sin(a) * r0
        x1, y1 = cx + math.cos(a) * r1, cy + math.sin(a) * r1
        d.line([(x0, y0), (x1, y1)], fill=(255, 224, 150, 180), width=4)
    for _ in range(24):
        a = rnd.uniform(0, 2 * math.pi); r = rnd.uniform(50, 175)
        x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
        rr = rnd.uniform(3, 7)
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(255, 236, 170, 220))
    img = img.filter(ImageFilter.GaussianBlur(1.0))
    return save(img, "vfx/vfx_food_pickup_burst_gold_001.png", (W, H))


def gen_vfx_collision_flash():
    W, H = 144, 144
    img = newimg(W, H)
    comp(img, radial_glow((W, H), W * 0.5, H * 0.5, 70, (255, 230, 200), inner=200, gamma=1.8))
    comp(img, radial_glow((W, H), W * 0.5, H * 0.5, 36, (255, 250, 240), inner=230, gamma=1.4))
    return save(img, "vfx/vfx_collision_flash_001.png", (W, H))


def gen_vfx_feathers():
    W, H = 256, 128
    img = newimg(W, H)
    rnd = random.Random(710)
    for _ in range(7):
        x = rnd.uniform(30, W - 30); y = rnd.uniform(20, H - 20)
        col = rnd.choice([BIRD_CREAM, BIRD_BROWN, (200, 180, 160)])
        ang = rnd.uniform(0, math.pi)
        rx, ry = 16, 7
        feather = newimg(W, H)
        ImageDraw.Draw(feather).ellipse([x - rx, y - ry, x + rx, y + ry], fill=col + (210,))
        feather = feather.rotate(math.degrees(ang), center=(x, y))
        comp(img, feather)
        d = ImageDraw.Draw(img)
        d.line([(x - math.cos(ang) * rx, y - math.sin(ang) * rx),
                (x + math.cos(ang) * rx, y + math.sin(ang) * rx)], fill=(90, 70, 56, 150), width=1)
    return save(img.filter(ImageFilter.GaussianBlur(0.5)), "vfx/vfx_feather_particles_001.png", (W, H))


def gen_vfx_speed_lines():
    W, H = 320, 128
    img = newimg(W, H)
    d = ImageDraw.Draw(img)
    rnd = random.Random(720)
    for _ in range(22):
        y = rnd.uniform(8, H - 8)
        x0 = rnd.uniform(0, W * 0.5)
        ln = rnd.uniform(60, 160)
        a = int(rnd.uniform(60, 150))
        d.line([(x0, y), (x0 + ln, y)], fill=(255, 255, 255, a), width=rnd.choice([1, 2]))
    return save(img.filter(ImageFilter.GaussianBlur(0.6)), "vfx/vfx_speed_lines_001.png", (W, H))


def gen_vfx_warm_glow():
    W, H = 256, 256
    img = radial_glow((W, H), W * 0.5, H * 0.5, 124, WARM_LIGHT, inner=190, gamma=2.0)
    comp(img, radial_glow((W, H), W * 0.5, H * 0.5, 50, (255, 245, 210), inner=150, gamma=1.6))
    return save(img, "vfx/vfx_warm_light_glow_001.png", (W, H))


def gen_vfx_cold_glow():
    W, H = 256, 256
    img = radial_glow((W, H), W * 0.5, H * 0.5, 124, COLD_LIGHT, inner=180, gamma=2.1)
    comp(img, radial_glow((W, H), W * 0.5, H * 0.5, 48, (235, 245, 255), inner=160, gamma=1.6))
    return save(img, "vfx/vfx_cold_light_flicker_001.png", (W, H))


def gen_vfx_screen_darken():
    W, H = 1280, 720
    yy, xx = np.mgrid[0:H, 0:W]
    cx, cy = W / 2, H / 2
    dist = np.sqrt(((xx - cx) / (W / 2)) ** 2 + ((yy - cy) / (H / 2)) ** 2)
    a = np.clip(dist - 0.35, 0, 1) ** 1.6 * 150
    out = np.zeros((H, W, 4))
    out[:, :, 0] = 8; out[:, :, 1] = 16; out[:, :, 2] = 30
    out[:, :, 3] = a
    img = Image.fromarray(out.astype("uint8"), "RGBA")
    return save(img, "vfx/vfx_screen_darken_fade_001.png", (W, H))


# ----------------------------------------------------------------------------
ALL = [
    gen_obstacle_tree_tall, gen_obstacle_tree_food, gen_bush_dense, gen_bush_sparse,
    gen_food_ground_insect, gen_food_seed, gen_food_berries, gen_food_larva,
    gen_food_fruit, gen_food_warm_light, gen_food_cold_light,
    gen_predator_poses, gen_predator_trajectory,
    gen_weather_drizzle, gen_weather_rain, gen_weather_storm,
    gen_overlay_dusk, gen_overlay_night, gen_overlay_dawn, gen_overlay_stars, gen_overlay_grey_cloud,
    gen_hud_hunger, gen_hud_height, gen_hud_wetness, gen_hud_distance_sign,
    gen_hud_night_timer, gen_hud_warning_arrow,
    gen_menu_panel,
    gen_vfx_pickup_burst, gen_vfx_collision_flash, gen_vfx_feathers, gen_vfx_speed_lines,
    gen_vfx_warm_glow, gen_vfx_cold_glow, gen_vfx_screen_darken,
]


def main():
    random.seed(1)
    np.random.seed(1)
    count = 0
    for fn in ALL:
        res = fn()
        if isinstance(res, list):
            for path, size in res:
                print(f"  {size[0]}x{size[1]}  {os.path.relpath(path, ART)}")
                count += 1
        else:
            path, size = res
            print(f"  {size[0]}x{size[1]}  {os.path.relpath(path, ART)}")
            count += 1
    print(f"\n生成完成：{count} 个资产")


if __name__ == "__main__":
    main()
