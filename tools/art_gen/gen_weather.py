"""归途 — 天气资产重绘（雨线 + 暴雨水雾）
Full-screen 1280x720, shown at full modulate. Rain falls diagonally
(scene scrolls right→left, so rain leans left for motion harmony).
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter
import common as K
from common import mix

W, H = 1280, 720
OUT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "weather"))


def save(im, name):
    im.save(os.path.join(OUT, name))
    print("  ok", name, im.size)


def rain_layer(count, length, lean, width, color, seed, blur=0.0):
    """Diagonal rain streaks. lean = horizontal drift over the streak length."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rnd = random.Random(seed)
    for _ in range(count):
        x = rnd.randint(-60, W + 60)
        y = rnd.randint(-40, H)
        ln = length * rnd.uniform(0.7, 1.25)
        lx = lean * rnd.uniform(0.8, 1.2)
        a = int(color[3] * rnd.uniform(0.5, 1.0))
        d.line([(x, y), (x - lx, y + ln)], fill=color[:3] + (a,), width=width)
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    return im


def drizzle():
    """Sparse thin drizzle."""
    im = rain_layer(220, 46, 10, 1, (210, 220, 228, 150), 301)
    save(im, "weather_drizzle_lines_001.png")


def rain():
    """Dense heavier rain — two layers (far/near) for depth."""
    far = rain_layer(360, 70, 18, 1, (200, 212, 222, 130), 311, blur=0.6)
    near = rain_layer(300, 110, 30, 2, (220, 230, 240, 190), 312)
    im = Image.alpha_composite(far, near)
    save(im, "weather_rain_lines_001.png")


def storm_mist():
    """Heavy rain veil + drifting water mist + darken — storm phase."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # misty fog bands
    fog = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    rnd = random.Random(321)
    for _ in range(26):
        x = rnd.randint(-100, W); y = rnd.randint(0, H)
        rx = rnd.randint(180, 420); ry = rnd.randint(50, 130)
        shade = rnd.randint(180, 210)
        fd.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(shade, shade + 4, shade + 8, 55))
    fog = fog.filter(ImageFilter.GaussianBlur(40))
    im = Image.alpha_composite(im, fog)
    # dense streaks
    streaks = rain_layer(260, 130, 34, 2, (225, 235, 245, 160), 322)
    im = Image.alpha_composite(im, streaks)
    save(im, "weather_storm_mist_001.png")


if __name__ == "__main__":
    print("WEATHER →", OUT)
    drizzle()
    rain()
    storm_mist()
