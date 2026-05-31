"""归途 — UI 资产重绘（自然旅途·野外手账主题）
Theme: warm parchment + wood + twine, hand-drawn migration-journal feel.

Static: hunger_meter, distance_sign, pause_and_game_over_panels,
        height_meter, wetness_meter.
Animated sprite sheets (horizontal, N frames): night_timer (6), warning_arrow (4).
  hud.gd is wired to step these via AtlasTexture.

Single-frame aspect of animated sheets matches each HUD display box so
STRETCH_KEEP_ASPECT behaves identically:
  night_timer box 72x72  -> square frames
  warning_arrow box 104x84 -> 104:84 frames
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import common as K
from common import SS, s, c, mix, soft_blob, radial_glow, paper_fill, rounded_panel, drop_shadow

OUT_HUD = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "ui", "hud"))
OUT_MENU = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "ui", "menus"))

FONT_PATH = "C:/Windows/Fonts/msyh.ttc"
FONT_BOLD = "C:/Windows/Fonts/msyhbd.ttc"


def font(px, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT_PATH, int(px * SS))


def save(im, w, h, path):
    out = K.finish(im, w, h)
    out.save(path)
    print("  ok", os.path.basename(path), out.size)


# ---------------------------------------------------------------------------
# decorative helpers
# ---------------------------------------------------------------------------

def twine_border(draw, box, col, width):
    """Dashed twine-style rounded border."""
    x0, y0, x1, y1 = box
    draw.rounded_rectangle([x0, y0, x1, y1], radius=s(14), outline=col, width=int(width))


def leaf_sprig(im, cx, cy, scale, ang=0.0):
    """A tiny decorative leaf sprig."""
    from common import tapered_leaf
    for i, d_ang in enumerate((-35, 0, 35)):
        tapered_leaf(im, cx, cy, s(22 * scale), s(9 * scale),
                     math.radians(ang + d_ang),
                     mix(K.PAL["leaf_mid"], K.PAL["leaf_dark"], 0.2 + i * 0.1) + (255,))


def wheat_icon(im, d, cx, cy, scale):
    """Small wheat/seed head icon (hunger)."""
    d.line([(cx, cy + s(16 * scale)), (cx, cy - s(14 * scale))],
           fill=K.PAL["grass_deep"] + (255,), width=s(2 * scale))
    for k in range(6):
        t = k / 5
        gy = cy + s(10 * scale) - t * s(24 * scale)
        rr = s(3.2 * scale)
        col = mix(K.PAL["seed_gold"], K.PAL["larva_cream"], t * 0.4)
        soft_blob(im, cx - s(3 * scale), gy, rr, rr * 1.3, col + (255,))
        soft_blob(im, cx + s(3 * scale), gy, rr, rr * 1.3, col + (255,))


def drop_icon(im, d, cx, cy, scale, col):
    """Water droplet (wetness)."""
    r = s(9 * scale)
    soft_blob(im, cx, cy + r * 0.3, r, r, col + (255,))
    d.polygon([(cx - r * 0.85, cy + r * 0.1), (cx, cy - r * 1.5), (cx + r * 0.85, cy + r * 0.1)], fill=col + (255,))
    soft_blob(im, cx - r * 0.3, cy + r * 0.2, r * 0.3, r * 0.4, (255, 255, 255, 150), blur=s(1))


# ---------------------------------------------------------------------------
# static UI
# ---------------------------------------------------------------------------

def hunger_meter(w=620, h=160):
    """Journal label ribbon above the (code-drawn) hunger bar."""
    W, H = w * SS, h * SS
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fill = paper_fill(W, int(H * 0.66), seed=611)
    panel = rounded_panel(W, int(H * 0.66), s(18), fill, c("wood_dark"), s(5))
    im.alpha_composite(panel, (0, int(H * 0.14)))
    d = ImageDraw.Draw(im)
    wheat_icon(im, d, s(46), int(H * 0.47), 2.4)
    f = font(34, bold=True)
    d.text((s(86), int(H * 0.46)), "饱  食", font=f, fill=c("ink"), anchor="lm")
    leaf_sprig(im, W - s(60), int(H * 0.46), 2.0, ang=180)
    save(im, w, h, os.path.join(OUT_HUD, "ui_hunger_meter_001.png"))


def wetness_meter(w=260, h=84):
    """Small journal tab for wetness (dead preload, themed)."""
    W, H = w * SS, h * SS
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fill = paper_fill(W, H, seed=621)
    panel = rounded_panel(W, H, s(14), fill, c("wood_dark"), s(4))
    im.alpha_composite(panel)
    d = ImageDraw.Draw(im)
    drop_icon(im, d, s(34), H // 2, 2.4, K.PAL["sky_teal"])
    f = font(30, bold=True)
    d.text((s(64), H // 2), "湿  度", font=f, fill=c("ink"), anchor="lm")
    save(im, w, h, os.path.join(OUT_HUD, "ui_wetness_meter_001.png"))


def distance_sign(w=520, h=233):
    """Wooden signpost; calm center for the code-rendered distance number."""
    W, H = w * SS, h * SS
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # post
    d = ImageDraw.Draw(im)
    post_x = W // 2
    d.rectangle([post_x - s(12), int(H * 0.5), post_x + s(12), H], fill=c("wood_dark"))
    # plank board
    bx0, by0, bx1, by1 = s(40), s(24), W - s(40), int(H * 0.66)
    board = Image.new("RGBA", (bx1 - bx0, by1 - by0), (0, 0, 0, 0))
    # wood plank fill with grain
    plank = Image.new("RGBA", board.size, c("wood"))
    pd = ImageDraw.Draw(plank)
    rnd = random.Random(631)
    for _ in range(40):
        yy = rnd.randint(0, board.size[1])
        pd.line([(0, yy), (board.size[0], yy + rnd.randint(-6, 6))],
                fill=mix(K.PAL["wood"], K.PAL["wood_dark"], rnd.uniform(0.2, 0.6)) + (90,), width=s(1))
    mask = Image.new("L", board.size, 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, board.size[0], board.size[1]], radius=s(16), fill=255)
    board.paste(plank, (0, 0), mask)
    bd = ImageDraw.Draw(board)
    bd.rounded_rectangle([s(3), s(3), board.size[0] - s(3), board.size[1] - s(3)],
                         radius=s(16), outline=c("wood_dark"), width=s(5))
    # nails
    for nx in (s(26), board.size[0] - s(26)):
        for ny in (s(22), board.size[1] - s(22)):
            bd.ellipse([nx - s(5), ny - s(5), nx + s(5), ny + s(5)], fill=c("bark_dark"))
    im.alpha_composite(board, (bx0, by0))
    # small leaf sprig top corner + label "距离"
    leaf_sprig(im, bx0 + s(40), by0 + s(8), 2.2, ang=200)
    f = font(22, bold=True)
    d.text((post_x, by0 + s(26)), "飞 行 距 离", font=f, fill=c("ink"), anchor="mm")
    save(im, w, h, os.path.join(OUT_HUD, "ui_distance_sign_001.png"))


def height_meter(w=90, h=360):
    """Vertical wooden altitude ruler (dead preload, themed)."""
    W, H = w * SS, h * SS
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fill = paper_fill(W, H, seed=641)
    panel = rounded_panel(W, H, s(16), fill, c("wood_dark"), s(4))
    im.alpha_composite(panel)
    d = ImageDraw.Draw(im)
    # tick marks
    for i in range(11):
        t = i / 10
        yy = int(s(12) + t * (H - s(24)))
        long_t = (i % 5 == 0)
        x1 = W - s(14) if not long_t else W - s(24)
        d.line([(s(14), yy), (x1, yy)], fill=c("ink", 200), width=s(2))
    save(im, w, h, os.path.join(OUT_HUD, "ui_height_meter_001.png"))


def panels(w=820, h=586):
    """Pause / game-over journal page; calm center for ~7 lines of text."""
    W, H = w * SS, h * SS
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fill = paper_fill(W, H, seed=651)
    panel = rounded_panel(W, H, s(26), fill, c("wood_dark"), s(8))
    # inner twine frame
    pd = ImageDraw.Draw(panel)
    pd.rounded_rectangle([s(26), s(26), W - s(26), H - s(26)],
                         radius=s(18), outline=c("twine"), width=s(3))
    # binding holes on left edge (journal feel)
    for i in range(5):
        yy = int(H * (0.18 + i * 0.16))
        pd.ellipse([s(40) - s(6), yy - s(6), s(40) + s(6), yy + s(6)], fill=c("paper_shadow"))
    im.alpha_composite(panel)
    d = ImageDraw.Draw(im)
    # header sprig + faint route line
    leaf_sprig(im, W // 2 - s(90), s(60), 2.6, ang=200)
    leaf_sprig(im, W // 2 + s(90), s(60), 2.6, ang=-20)
    # dashed migration route across the top
    rnd = random.Random(652)
    x = s(120); y = s(64)
    while x < W - s(120):
        nx = x + s(18)
        d.line([(x, y + math.sin(x / s(40)) * s(6)), (nx, y + math.sin(nx / s(40)) * s(6))],
               fill=c("ink", 120), width=s(2))
        x = nx + s(12)
    save(im, w, h, os.path.join(OUT_MENU, "ui_pause_and_game_over_panels_001.png"))


# ---------------------------------------------------------------------------
# animated sprite sheets
# ---------------------------------------------------------------------------

def _night_frame(fw, fh, phase):
    """One night-timer frame. phase in [0,1): warm glow breathes, moon constant."""
    im = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    cx, cy = fw // 2, fh // 2
    R = int(min(fw, fh) * 0.30)
    breath = 0.5 + 0.5 * math.sin(phase * math.tau)
    # warm breathing halo
    halo_r = int(R * (1.6 + 0.5 * breath))
    halo_a = int(70 + 90 * breath)
    im.alpha_composite(radial_glow(fw, fh, cx, cy, halo_r, c("warm_glow", halo_a)))
    # crescent moon: full disc minus offset shadow disc
    disc = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    dd = ImageDraw.Draw(disc)
    dd.ellipse([cx - R, cy - R, cx + R, cy + R], fill=c("warm_core", 255))
    shadow = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    off = int(R * 0.55)
    sd.ellipse([cx - R + off, cy - R - int(R * 0.12), cx + R + off, cy + R - int(R * 0.12)],
               fill=(0, 0, 0, 255))
    # subtract shadow from disc
    da = disc.split()[3]
    sa = shadow.split()[3]
    from PIL import ImageChops
    cut = ImageChops.subtract(da, sa)
    disc.putalpha(cut)
    im.alpha_composite(disc)
    # tiny star that twinkles opposite to breath
    star_a = int(120 + 120 * (1 - breath))
    sx, sy = int(cx + R * 1.1), int(cy - R * 0.9)
    ImageDraw.Draw(im).ellipse([sx - 2, sy - 2, sx + 2, sy + 2], fill=(255, 255, 255, star_a))
    return im


def night_timer_sheet(frames=6, fw_disp=240, fh_disp=240):
    """6-frame square sheet (box is 72x72)."""
    fw, fh = fw_disp * SS, fh_disp * SS
    sheet = Image.new("RGBA", (fw * frames, fh), (0, 0, 0, 0))
    for i in range(frames):
        fr = _night_frame(fw, fh, i / frames)
        sheet.paste(fr, (i * fw, 0))
    out = sheet.resize((fw_disp * frames, fh_disp), Image.LANCZOS)
    out.save(os.path.join(OUT_HUD, "ui_night_timer_001.png"))
    print("  ok ui_night_timer_001.png", out.size, f"({frames} frames @ {fw_disp}x{fh_disp})")


def _arrow_frame(fw, fh, phase):
    """One warning-arrow frame. Red alert chevron pointing left, pulsing."""
    im = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    cx, cy = fw // 2, fh // 2
    pulse = 0.5 + 0.5 * math.sin(phase * math.tau)
    # alert glow
    glow_a = int(60 + 120 * pulse)
    im.alpha_composite(radial_glow(fw, fh, cx, cy, int(min(fw, fh) * 0.6), K.PAL["warn_red"] + (glow_a,)))
    d = ImageDraw.Draw(im)
    scale = 0.85 + 0.15 * pulse
    aw = fw * 0.32 * scale
    ah = fh * 0.34 * scale
    col_a = int(200 + 55 * pulse)
    red = K.PAL["warn_red"] + (col_a,)
    # double chevron pointing left
    for off in (0, aw * 0.7):
        tip = (cx - aw + off, cy)
        top = (cx + off, cy - ah)
        bot = (cx + off, cy + ah)
        d.line([top, tip], fill=red, width=int(s(7) * scale))
        d.line([bot, tip], fill=red, width=int(s(7) * scale))
    return im


def warning_arrow_sheet(frames=4, fw_disp=156, fh_disp=126):
    """4-frame sheet, single-frame aspect 156:126 ≈ 104:84 box."""
    fw, fh = fw_disp * SS, fh_disp * SS
    sheet = Image.new("RGBA", (fw * frames, fh), (0, 0, 0, 0))
    for i in range(frames):
        fr = _arrow_frame(fw, fh, i / frames)
        sheet.paste(fr, (i * fw, 0))
    out = sheet.resize((fw_disp * frames, fh_disp), Image.LANCZOS)
    out.save(os.path.join(OUT_HUD, "ui_warning_arrow_001.png"))
    print("  ok ui_warning_arrow_001.png", out.size, f"({frames} frames @ {fw_disp}x{fh_disp})")


if __name__ == "__main__":
    print("UI HUD →", OUT_HUD)
    hunger_meter()
    wetness_meter()
    distance_sign()
    height_meter()
    night_timer_sheet()
    warning_arrow_sheet()
    print("UI MENUS →", OUT_MENU)
    panels()
