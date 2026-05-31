# 《归途》美术资产大重绘 — 设计规格

> 日期：2026-05-31 · 状态：已批准，进入实施

## 1. 目标

替换游戏中除「背景 / 音频 / 角色」以外的全部美术资产，新资产贴合现有
手绘半写实背景的调色板与笔触感，同时更接近真实场景。UI 以「自然旅途·野外
手账」为主题重新设计。两个关键状态图标做成多帧动画并接线播放。删除陷阱系统
及一切无用资产。

## 2. 保留（不动）

- `assets/art/environment/backgrounds_loopable/`（全部 10 张）
- `assets/art/characters/`（小鸟 7 态 + 天敌 5 图，含当前未引用的 `trapped`、
  `afterimage` —— 用户明确要求保留整个 characters）
- `assets/audio/`（全部）
- `assets/intro/`（标题 logo + 开场视频）

## 3. 美术风格

严格对齐背景采样调色板：

| 场景 | 关键色 |
| --- | --- |
| 白天天空 | `#5497a4` 青绿 |
| 草原 | `#a1a485` / `#73753b` 橄榄 |
| 夜深蓝 | `#06264f` |
| 雨灰 | `#a6aeb3` |
| 黄昏 | `#9f818a` mauve / `#bd7b6d` salmon |

技法：2× 超采样后缩小得柔和边缘；多层半透明叠加；轻噪点做有机质感。

## 4. 重绘清单（33 个，全部沿用原生分辨率，零代码尺寸改动）

代码中 `visual_scale`、hitbox、`KEEP_ASPECT` 容器尺寸均按当前像素尺寸调好，
**新资产必须保持各自原生分辨率**，否则屏上比例错乱。

| 类别 | 数量 | 资产 |
| --- | --- | --- |
| 食物 | 7 | ground_insect, seed_cluster, bush_berries, canopy_larva, canopy_fruit_cluster, night_warm_light_insects, cold_false_light |
| 障碍 | 4 | tree_tall, tree_food_points, bush_dense, bush_sparse |
| 覆盖层 | 5 | dawn_transition, dusk_tint, night_tint, stars_distant_lights, grey_cloud_warning |
| 天气 | 3 | drizzle_lines, rain_lines, storm_mist |
| VFX | 7 | food_pickup_burst_gold, collision_flash, feather_particles, speed_lines, warm_light_glow, cold_light_flicker, screen_darken_fade |
| UI | 7 | hunger_meter, distance_sign, night_timer, warning_arrow, pause_and_game_over_panels, height_meter, wetness_meter |

> 注：`height_meter` 与 `wetness_meter` 是 `hud.gd` 中的死 preload（被预加载但
> 未显示，进度条由代码 StyleBoxFlat 绘制）。重绘以免 preload 报错，且与主题统一。

## 5. UI 主题：自然旅途·野外手账

暖色羊皮纸 / 木质底，叶脉与细绳装饰边框，手绘迁徙路线意象。

- 距离牌 = 木质路标，中心留白给代码渲染的数字
- 暂停 / 结算面板 = 手账内页，留出 7 行结算文字的平静区
- 饱食横幅 = 手账标签条

## 6. 多帧动画图标（需改 `hud.gd`）

两个真正需要细腻变化的图标做水平精灵表 + 接线播放：

| 图标 | 帧数 | 行为 |
| --- | --- | --- |
| 警告箭头 | 4 | 红光脉冲闪烁，天敌蓄力 / 警告期持续播放 |
| 夜航计时 | 6 | 月相 / 暖光呼吸明灭，夜航期持续播放 |

实现：精灵表 PNG 写回原路径原文件名（保持 `preload` 不变）；`hud.gd` 增加一个
轻量帧步进助手（`AtlasTexture` + `_process` 中按帧率推进），仅作用于这两个图标，
其余图标保持静态单帧。动画图标的精灵表整体宽度 = 单帧宽 × 帧数，单帧尺寸保持
原 HUD 显示尺寸不变。

## 7. 删除清单（15 个 PNG + 各自 `.import`）

均在 git 中可恢复。

- `traps/` 全部 ×4（陷阱系统已移除）
- 无用食物：`food_ground_bait`、`food_lake_insects`
- 无用障碍：`obstacle_lake_edge`、`obstacle_tree_wind`
- 无用 UI：`ui_floating_delta`、`ui_wind_headwind`、`ui_wind_tailwind`、`ui_main_menu_art`

**保留** `source_sheets/`：带 `.gdignore`，不进游戏包，可能是美术母版，删除零收益。

## 8. 工具与验证

- 生成脚本置于 `tools/art_gen/`，可复现、参数化、按类别分文件。
- 验证：
  1. `python -m unittest tests/test_minimal_playable_static.py`（静态源码检查）
  2. Godot `--import`（如本机可用）重导入，确认无导入错误
  3. 资产尺寸核对脚本，确认重绘资产分辨率与原始一致
- 清理：删除临时 `.art_preview/` 预览目录。

## 9. 范围外

不新增玩法、不改数值、不动除 `hud.gd` 动画接线外的游戏逻辑。
