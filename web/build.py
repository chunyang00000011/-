#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""归途 轻量版打包器：优化精灵 + 内嵌音频 -> 单个 HTML 文件。

混合美术方案：复用真实精灵图（小鸟/食物/树木/灌木/天敌/VFX），
背景由 template.html 中的 canvas 代码绘制（不占体积）。
音频：BGM(ogg) + 关键 SFX(wav->base64)。
"""
import base64
import io
import os
import sys

from PIL import Image

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(ROOT, "web", "template.html")
OUTPUT = os.path.join(ROOT, "web", "归途_轻量版.html")

# 精灵：key -> (相对路径, 最大宽度px)。下采样到游戏内实际显示尺寸的 ~2x 即可。
SPRITES = {}

def add_bird_frames():
    d = "assets/bird/flying"
    for i in range(1, 26):
        SPRITES[f"fly_{i:03d}"] = (f"{d}/player_bird_s04_f{i:03d}.png", 110)

BIRD_STATES = {
    "bird_climb": "assets/art/characters/player_bird/states/player_bird_climb_001.png",
    "bird_descend": "assets/art/characters/player_bird/states/player_bird_descend_001.png",
    "bird_accelerate": "assets/art/characters/player_bird/states/player_bird_accelerate_001.png",
    "bird_hit": "assets/art/characters/player_bird/states/player_bird_hit_001.png",
    "bird_falling": "assets/art/characters/player_bird/states/player_bird_falling_001.png",
    "bird_collapse": "assets/art/characters/player_bird/states/player_bird_ground_collapse_001.png",
}
FOOD = {
    "food_ground_insect": "assets/art/food/food_ground_insect_001.png",
    "food_seed_cluster": "assets/art/food/food_seed_cluster_001.png",
    "food_bush_berries": "assets/art/food/food_bush_berries_001.png",
    "food_canopy_larva": "assets/art/food/food_canopy_larva_001.png",
    "food_canopy_fruit": "assets/art/food/food_canopy_fruit_cluster_001.png",
    "food_warm_light": "assets/art/food/food_night_warm_light_insects_001.png",
    "food_cold_light": "assets/art/food/food_cold_false_light_001.png",
}
OBSTACLES = {
    "tree_tall": "assets/art/environment/obstacles/obstacle_tree_tall_001.png",
    "tree_food": "assets/art/environment/obstacles/obstacle_tree_food_points_001.png",
    "bush_dense": "assets/art/environment/obstacles/obstacle_bush_dense_001.png",
    "bush_sparse": "assets/art/environment/obstacles/obstacle_bush_sparse_001.png",
}
PREDATORS = {
    # 程序化生成的暖棕 painterly 老鹰（web 专用，不影响 Godot 端原图）。
    "pred_hover": "assets/art/characters/predators/web_generated/hawk_hover.png",
    "pred_aim": "assets/art/characters/predators/web_generated/hawk_aim.png",
    "pred_dash": "assets/art/characters/predators/web_generated/hawk_dash.png",
    "traj": "assets/art/characters/predators/predator_attack_trajectory_001.png",
}
VFX = {
    "vfx_pickup": "assets/art/vfx/vfx_food_pickup_burst_gold_001.png",
    "glow_warm": "assets/art/vfx/vfx_warm_light_glow_001.png",
    "glow_cold": "assets/art/vfx/vfx_cold_light_flicker_001.png",
}

# 各类精灵的最大宽度（控制体积；游戏内缩放系数小，无需原分辨率）
MAXW = {
    **{k: 110 for k in []},
}

def build_sprite_manifest():
    add_bird_frames()
    for k, p in BIRD_STATES.items():
        SPRITES[k] = (p, 200)
    for k, p in FOOD.items():
        SPRITES[k] = (p, 180)
    for k, p in OBSTACLES.items():
        SPRITES[k] = (p, 360)  # 树最大，0.7 缩放下显示约 380px
    for k, p in PREDATORS.items():
        SPRITES[k] = (p, 300)
    for k, p in VFX.items():
        SPRITES[k] = (p, 256)

# 场景背景：复用游戏端真实贴图，按相位切换（白天/黄昏/夜晚/雨）。
# WebP 压缩后极小，循环横向滚动，替代原先简陋的代码绘制地形。
SCENES = {
    "bg_day": "assets/art/environment/backgrounds_loopable/bg_scene_grassland_forest_day_001_loop_001.png",
    "bg_dusk": "assets/art/environment/backgrounds_loopable/bg_scene_dusk_001_loop_001.png",
    "bg_night": "assets/art/environment/backgrounds_loopable/bg_scene_night_001_loop_001.png",
    "bg_rain": "assets/art/environment/backgrounds_loopable/bg_scene_rain_001_loop_001.png",
}
SCENE_MAX_W = 1280
SCENE_WEBP_QUALITY = 80

# 音频：key -> 相对路径
BGM = ("bgm", "assets/audio/music/homeward_birds_wind_ambient.ogg")
SFX = {
    "run_start": "assets/audio/sfx/gameplay/state/run_start_01.wav",
    "game_over": "assets/audio/sfx/gameplay/state/game_over_soft_01.wav",
    "falling": "assets/audio/sfx/gameplay/state/falling_warning_01.wav",
    "recover": "assets/audio/sfx/gameplay/state/recover_food_ground_01.wav",
    "food_ground_insect": "assets/audio/sfx/gameplay/food/ground_insect_pickup_01.wav",
    "food_seed_cluster": "assets/audio/sfx/gameplay/food/seed_pickup_01.wav",
    "food_bush_berries": "assets/audio/sfx/gameplay/food/bush_berry_pickup_01.wav",
    "food_canopy_larva": "assets/audio/sfx/gameplay/food/canopy_larva_pickup_01.wav",
    "food_canopy_fruit": "assets/audio/sfx/gameplay/food/canopy_fruit_pickup_01.wav",
    "food_night_warm_light": "assets/audio/sfx/gameplay/food/night_warm_light_pickup_01.wav",
    "food_night_cold_light": "assets/audio/sfx/gameplay/food/cold_false_light_penalty_01.wav",
    "food_generic": "assets/audio/sfx/gameplay/food/ground_insect_pickup_01.wav",
    "tree_hit": "assets/audio/sfx/gameplay/obstacle/tree_hit_soft_01.wav",
    "bush_hit": "assets/audio/sfx/gameplay/obstacle/dense_bush_hit_01.wav",
    "predator_aim": "assets/audio/sfx/gameplay/predator/aim_lock_01.wav",
    "predator_hit": "assets/audio/sfx/gameplay/predator/hit_bird_01.wav",
    "rain_warning": "assets/audio/sfx/gameplay/weather/rain_warning_cloud_01.wav",
    "night_dusk": "assets/audio/sfx/gameplay/night/dusk_fade_in_01.wav",
    "night_arrive": "assets/audio/sfx/gameplay/night/night_arrive_01.wav",
    "night_dawn": "assets/audio/sfx/gameplay/night/dawn_return_01.wav",
    "menu_confirm": "assets/audio/sfx/gameplay/ui/menu_confirm_01.wav",
}

MIME = {".wav": "audio/wav", ".ogg": "audio/ogg", ".mp3": "audio/mpeg"}


def encode_image(rel_path, max_w):
    full = os.path.join(ROOT, rel_path)
    if not os.path.exists(full):
        print(f"  [缺失] {rel_path}")
        return None
    im = Image.open(full).convert("RGBA")
    orig_w, orig_h = im.width, im.height  # 记录原始尺寸：显示缩放基于原图，与压缩无关
    if im.width > max_w:
        ratio = max_w / im.width
        im = im.resize((max_w, max(1, int(im.height * ratio))), Image.LANCZOS)
    # 量化到调色板 + alpha，显著压缩。保留透明度。
    buf = io.BytesIO()
    # 用 optimize PNG；带 alpha 的图量化可能损边缘，统一用优化 PNG 更安全
    im.save(buf, format="PNG", optimize=True)
    data = buf.getvalue()
    b64 = base64.b64encode(data).decode("ascii")
    return {"s": f"data:image/png;base64,{b64}", "w": orig_w, "h": orig_h}, len(data)


def encode_scene(rel_path):
    """场景背景：缩放到 1280 宽，WebP 压缩（不透明，RGB）。"""
    full = os.path.join(ROOT, rel_path)
    if not os.path.exists(full):
        print(f"  [缺失] {rel_path}")
        return None
    im = Image.open(full).convert("RGB")
    if im.width > SCENE_MAX_W:
        ratio = SCENE_MAX_W / im.width
        im = im.resize((SCENE_MAX_W, max(1, int(im.height * ratio))), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format="WEBP", quality=SCENE_WEBP_QUALITY, method=6)
    data = buf.getvalue()
    b64 = base64.b64encode(data).decode("ascii")
    return f"data:image/webp;base64,{b64}", len(data)


def encode_audio(rel_path):
    full = os.path.join(ROOT, rel_path)
    if not os.path.exists(full):
        print(f"  [缺失] {rel_path}")
        return None
    ext = os.path.splitext(full)[1].lower()
    mime = MIME.get(ext, "application/octet-stream")
    with open(full, "rb") as f:
        data = f.read()
    b64 = base64.b64encode(data).decode("ascii")
    return f"data:{mime};base64,{b64}", len(data)


def main():
    build_sprite_manifest()
    images = {}
    audio = {}
    img_bytes = 0
    aud_bytes = 0

    print("== 编码精灵 ==")
    for key, (rel, maxw) in SPRITES.items():
        r = encode_image(rel, maxw)
        if r:
            images[key], n = r
            img_bytes += n

    print("== 编码场景背景 ==")
    scene_bytes = 0
    for key, rel in SCENES.items():
        r = encode_scene(rel)
        if r:
            images[key], n = r
            scene_bytes += n
            print(f"  {key}: {n/1024:.0f} KB")

    print("== 编码音频 ==")
    r = encode_audio(BGM[1])
    if r:
        audio[BGM[0]], n = r
        aud_bytes += n
    for key, rel in SFX.items():
        r = encode_audio(rel)
        if r:
            audio[key], n = r
            aud_bytes += n

    # 组装 JS 资源对象
    import json
    assets_obj = {"images": images, "audio": audio}
    assets_json = json.dumps(assets_obj, ensure_ascii=False, separators=(",", ":"))

    with open(TEMPLATE, "r", encoding="utf-8") as f:
        html = f.read()
    if "__ASSETS__" not in html:
        print("错误：模板缺少 __ASSETS__ 占位符")
        sys.exit(1)
    html = html.replace("__ASSETS__", assets_json)

    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write(html)

    total = len(html.encode("utf-8"))
    print("\n== 完成 ==")
    print(f"  精灵原始字节: {img_bytes/1024:.0f} KB  ({len(images)} 张)")
    print(f"  音频原始字节: {aud_bytes/1024/1024:.2f} MB  ({len(audio)} 个)")
    print(f"  输出文件:    {OUTPUT}")
    print(f"  最终大小:    {total/1024/1024:.2f} MB")
    if total > 8 * 1024 * 1024:
        print("  [!] 超过 8MB!")
    else:
        print(f"  [OK] 在 8MB 预算内 (余 {(8*1024*1024-total)/1024/1024:.2f} MB)")


if __name__ == "__main__":
    main()
