#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""程序化生成老鹰天敌精灵（俯视视角），三种姿态：盘旋/锁定/俯冲。
风格对齐当前界面：温暖的大地棕色、柔和明暗、羽毛分层与翼尖分指，
而非原先生硬的纯黑剪影。输出独立文件，不动 Godot 游戏端原图。
"""
import os
import sys
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "art", "characters", "predators", "web_generated")
os.makedirs(OUT_DIR, exist_ok=True)

SS = 4               # 超采样倍数，最后缩小得到柔和抗锯齿边缘
W, H = 300, 200      # 输出尺寸（俯视，翼展横向）
CW, CH = W * SS, H * SS

# 调色板（暖棕，俯视猛禽背部）
C_TOP = np.array([176, 138, 96], dtype=float)    # 翼前缘受光：浅黄褐
C_MID = np.array([120, 92, 64], dtype=float)     # 翼面主色：中棕
C_BOT = np.array([72, 54, 40], dtype=float)      # 翼后缘/尾部：深棕
C_SPINE = np.array([60, 45, 34], dtype=float)    # 脊背阴影
C_RIM = np.array([214, 184, 142], dtype=float)   # 顶部高光描边
C_HEAD = np.array([86, 64, 46], dtype=float)     # 头部


def qbez(p0, p1, p2, n=40):
    """二次贝塞尔采样，得到平滑翼缘。"""
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    return pts


def wing_polygon(cx, shoulder_y, body_half, wingspan, tip_dy, chord, side):
    """构造一侧机翼多边形。side=+1 右翼, -1 左翼。
    tip_dy: 翼尖相对肩部的下沉量（越大越后掠/俯冲）。
    chord:  翼弦（前后宽度）。
    返回多边形点列 + 翼尖位置（用于画分指）。
    """
    sx = cx + side * body_half          # 肩部内侧
    tipx = cx + side * wingspan         # 翼尖
    tipy = shoulder_y + tip_dy
    # 前缘：肩 -> 翼尖（向上外凸）
    lead = qbez((sx, shoulder_y - chord * 0.15),
                (cx + side * wingspan * 0.6, shoulder_y - chord * 0.45),
                (tipx, tipy), 36)
    # 后缘：翼尖 -> 身体下方（向内凹）
    trail = qbez((tipx, tipy),
                 (cx + side * wingspan * 0.5, shoulder_y + chord * 0.85),
                 (sx, shoulder_y + chord * 0.95), 36)
    poly = lead + trail
    return poly, (tipx, tipy), (sx, shoulder_y)


def build_mask(sweep):
    """绘制白色剪影掩膜。sweep: 0=盘旋(平展) .. 1=俯冲(后掠)。"""
    img = Image.new("L", (CW, CH), 0)
    d = ImageDraw.Draw(img)
    cx = CW / 2
    shoulder_y = CH * 0.40

    body_half = CW * 0.052
    # 后掠越多翼展略收、翼尖下沉、翼弦变窄（更流线）
    wingspan = CW * (0.46 - 0.06 * sweep)
    tip_dy = CH * (-0.02 + 0.40 * sweep)
    chord = CH * (0.30 - 0.08 * sweep)

    # 两翼
    for side in (-1, 1):
        poly, tip, sh = wing_polygon(cx, shoulder_y, body_half, wingspan, tip_dy, chord, side)
        d.polygon([(int(x), int(y)) for x, y in poly], fill=255)
        # 翼尖分指（初级飞羽）：在翼尖附近切几道缝，营造猛禽手指
        fingers = 4
        for fi in range(fingers):
            fx = tip[0] - side * (CW * 0.012 * fi + CW * 0.004)
            fy = tip[1] + (fi - fingers / 2) * (CH * 0.018) + chord * 0.15
            # 用背景色细缝分隔羽尖
            d.line([(tip[0], tip[1]), (fx, fy)], fill=0, width=int(SS * 1.6))

    # 身体（纺锤形）
    body_top = shoulder_y - CH * 0.10
    body_bot = shoulder_y + CH * (0.30 + 0.12 * sweep)
    d.ellipse([cx - body_half * 1.5, body_top, cx + body_half * 1.5, body_bot], fill=255)

    # 尾羽（扇形，俯冲时收拢）
    tail_w = body_half * (2.6 - 1.2 * sweep)
    tail_len = CH * (0.20 + 0.06 * sweep)
    d.polygon([
        (cx - body_half * 0.8, body_bot - CH * 0.04),
        (cx + body_half * 0.8, body_bot - CH * 0.04),
        (cx + tail_w, body_bot + tail_len),
        (cx - tail_w, body_bot + tail_len),
    ], fill=255)

    # 头部（圆，俯视前方）
    head_r = body_half * 1.15
    head_cy = body_top + head_r * 0.2
    d.ellipse([cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r], fill=255)

    # 轻微羽化边缘
    img = img.filter(ImageFilter.GaussianBlur(SS * 0.9))
    return img, cx, shoulder_y, wingspan


def shade(mask_arr, cx, shoulder_y, wingspan):
    """在掩膜内做明暗+羽毛纹理着色，返回 RGB float 数组。"""
    ys, xs = np.mgrid[0:CH, 0:CW].astype(float)
    # 垂直渐变（头部受光 -> 尾部暗）
    vy = np.clip((ys - shoulder_y * 0.4) / (CH * 0.9), 0, 1)
    base = (C_TOP[None, None, :] * (1 - vy)[..., None] +
            C_BOT[None, None, :] * vy[..., None])
    # 翼面主色混入
    base = 0.55 * base + 0.45 * C_MID[None, None, :]

    # 脊背阴影：靠近中线压暗一点，形成身体体积
    spine = np.exp(-((xs - cx) / (CW * 0.045)) ** 2)
    base = base * (1 - 0.28 * spine[..., None]) + C_SPINE[None, None, :] * (0.28 * spine[..., None])

    # 羽毛分层：沿翼展方向的柔和明暗条带
    dist = np.abs(xs - cx) / max(1.0, wingspan)
    band = 0.07 * np.sin(dist * 26.0) + 0.05 * np.sin((ys - shoulder_y) / (CH * 0.06))
    base = base * (1.0 + band[..., None])

    # 顶部受光高光（来自左上）
    light = np.clip(1.0 - (ys - shoulder_y * 0.2) / (CH * 0.5), 0, 1) * \
            np.clip(1.0 - (xs - cx * 0.7) / (CW * 0.9), 0.2, 1)
    base = base + C_RIM[None, None, :] * (0.18 * light[..., None])

    return np.clip(base, 0, 255)


def make_rim(mask):
    """顶部边缘高光描边：掩膜与其下移版本的差。"""
    m = np.asarray(mask, dtype=float) / 255.0
    shifted = np.asarray(mask.transform(
        mask.size, Image.AFFINE, (1, 0, 0, 0, 1, SS * 4), resample=Image.BILINEAR),
        dtype=float) / 255.0
    rim = np.clip(m - shifted, 0, 1)  # 仅上缘亮
    return rim


def render(sweep, name):
    mask, cx, shoulder_y, wingspan = build_mask(sweep)
    color = shade(np.asarray(mask), cx, shoulder_y, wingspan)
    rim = make_rim(mask)
    color = color + C_RIM[None, None, :] * (0.5 * rim[..., None])
    color = np.clip(color, 0, 255)

    alpha = np.asarray(mask, dtype=np.uint8)
    rgba = np.dstack([color.astype(np.uint8), alpha])
    im = Image.fromarray(rgba, "RGBA")
    # 缩小到目标尺寸（抗锯齿）
    im = im.resize((W, H), Image.LANCZOS)
    path = os.path.join(OUT_DIR, name)
    im.save(path)
    print(f"  生成 {name}  ({W}x{H})")
    return path


def main():
    print("== 生成老鹰精灵（俯视, 暖棕painterly）==")
    render(0.05, "hawk_hover.png")   # 盘旋：翼展平
    render(0.42, "hawk_aim.png")     # 锁定：半收
    render(0.85, "hawk_dash.png")    # 俯冲：后掠流线
    print(f"输出目录: {OUT_DIR}")


if __name__ == "__main__":
    main()
