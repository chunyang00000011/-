# 《归途》系统完善设计 v1.0

日期：2026-05-31
状态：已与用户确认，待实现

## 1. 目标与范围

依据 `docs/归途_游戏设计规格.md`，将《归途》从当前的 V0.2 完成度补全到一个完整可玩的版本。

### 1.1 削减的系统

经用户决定，以下系统**不实现**，并清理其连带内容：

- **风系统（顺风/逆风）** —— 饱食度公式删去"风向倍率"；难度递进删去"逆风概率"；HUD 不显示风向图标。
- **湖泊段** —— 删去"湖面飞虫"食物类型。
- **捕鸟陷阱** —— 删去"地上鸟食诱饵"食物类型及被困机制。

### 1.2 实现的内容

- 补全饱食度统一消耗公式（湿度 / 高度 / 速度倍率 + 操作消耗）
- 难度递进系统（按飞行距离驱动）
- 雨天与羽毛湿度系统
- 夜航系统（黄昏 / 黑夜 / 黎明，暖光 / 冷光）
- 天敌系统（鹰隼四阶段攻击）
- 美术贴图 HUD（中文）与 VFX
- 玩家状态动画（爬升 / 下降 / 加速 / 受击 / 坠落 / 倒地）
- 暂停菜单（继续 / 重开 / 音量 / 返回标题）+ 版本号
- 音频系统（BGM + 事件 SFX + 音量控制）
- 历史最佳距离存档

## 2. 架构

各系统拆成挂在 `Main` 节点下的独立节点，各自管理状态，通过信号或查询与 `main.gd` 协作。`main.gd` 退回纯协调者角色。

| 节点 | 脚本 | 职责 | 与外部的接口 |
| --- | --- | --- | --- |
| `Main` | `main.gd` | run 状态、饱食度值与消耗公式、距离/时间、游戏结束/坠落/倒地判定、系统接线 | 协调全部子系统 |
| `DifficultySystem` | `difficulty_system.gd` | 纯函数：输入飞行距离 → 输出难度参数 | `params_for_distance(distance_m) -> Dictionary` |
| `WeatherSystem` | `weather_system.gd` | 雨天状态机 + 湿度值 + 雨/云/雾覆盖层 | `wetness` 属性、`get_wetness_multiplier()`、信号 `weather_phase_changed` |
| `NightSystem` | `night_system.gd` | 夜航周期状态机 + 夜色覆盖层 + 暖光/冷光生成 | 信号 `night_phase_changed(phase)`、`is_night_hiding_food()`、信号 `light_food_spawned` |
| `PredatorSystem` | `predator_system.gd` + `predator.gd` | 按高度调制概率生成天敌；每只走四阶段状态机 | 信号 `predator_hit(loss)`、信号 `predator_warning(active)` |
| `Spawner` | `spawner.gd`（改造） | 食物 + 障碍生成，接入夜航可见性与难度参数 | 信号 `food_collected`、`obstacle_hit` |
| `ScrollingWorld` | `scrolling_world.gd`（沿用） | 横向滚动背景 | `set_scroll_speed`、`set_height_ratio`、`reset` |
| `Player` | `player_bird.gd`（改造） | 飞行/高度/状态动画 | `height_m`、`is_climbing/is_descending/is_accelerating`、`set_state`、`reset` |
| `HUD` | `hud.gd`（改造） | 美术贴图 HUD + 浮字 + 警告箭头 + 结算面板 | `update_stats`、`show_floating_delta`、`show_game_over`、`set_*_visible` |
| `PauseMenu` | `pause_menu.gd`（新建） | ESC 暂停 + 继续/重开/音量/返回标题 | 信号 `resume_requested`、`restart_requested`、`quit_to_title_requested` |
| `AudioManager` | `audio_manager.gd`（autoload） | BGM + 事件 SFX + 音量总线 | `play_sfx(key)`、`set_music_volume`、`set_sfx_volume` |
| `SaveData` | `save_data.gd`（autoload 或并入 main） | 历史最佳距离读写 | `get_best_distance()`、`update_best_distance(d)` |

`Intro`（开场视频 + 标题）保持现状。点击标题后进入游戏。

## 3. 核心数值

### 3.1 饱食度消耗（main.gd）

```
每 0.5s 消耗 = 基础消耗 × 湿度倍率 × 高度倍率 × 速度倍率 + 操作额外消耗
```

| 项 | 值 |
| --- | --- |
| 基础消耗 | 1.0 / 0.5s |
| 上升额外 | +0.5 |
| 下降额外 | +0.2 |
| 加速额外 | +0.7 |
| 湿度倍率 | 0~20 ×1.0 / 21~50 ×1.2 / 51~80 ×1.5 / 81~100 ×2.0 |
| 高度倍率 | 0~60m ×1.0 / 61~100m ×0.8 |
| 速度倍率 | 普通 ×1.0 / 加速 ×1.4 |

湿度倍率向 `WeatherSystem` 查询；高度 / 速度 / 操作状态读 `Player`。

初始饱食度 60，上限 100。

### 3.2 难度递进（DifficultySystem，纯函数）

输入飞行距离 `distance_m`，输出难度参数。删去风/陷阱项。

| 参数 | 每 1000m 变化 | 上限 |
| --- | --- | --- |
| 食物间隔 | -5% | 最短 1.0s（基准 1.1s） |
| 天敌概率 | +3% | 30% |
| 树木概率 | +3% | 40%（基准 25%） |
| 雨天时长 | +1s | 28s（基准 10s） |
| 夜航周期 | 每 2000m -10s | 最短 80s（基准 120s） |

灌木概率固定 15%。

### 3.3 雨天与湿度（WeatherSystem）

- 判定间隔 8s，基础触发概率 12%。
- 雨前 2s 显示灰云预警 `weather_grey_cloud_warning_overlay_001.png`。
- 雨天总时长 = DifficultySystem 给出的 `rain_duration`（10~28s）。
- 阶段（按已下雨时长）：

| 阶段 | 时间 | 视觉 | 湿度变化 |
| --- | --- | --- | --- |
| 毛毛雨 | 0~4s | `weather_drizzle_lines_001.png` | +3/s |
| 大雨 | 5~8s | `weather_rain_lines_001.png` | +6/s |
| 暴雨 | 9s+ | 雨线 + `weather_storm_mist_001.png` 水雾 + `vfx_screen_darken_fade` | +10/s |

- 雨停后湿度每秒 -3 直到 0。
- 湿度范围 0~100，初始 0。

### 3.4 夜航（NightSystem）

周期性事件，非随机。

- 首次触发 120s；之后每个周期 = DifficultySystem 给出的 `night_period`（每 2000m -10s，最短 80s）。
- 总时长 15s。
- 阶段：

| 阶段 | 时长 | 视觉 | 玩法 |
| --- | --- | --- | --- |
| 黄昏 | 5s | `overlay_dusk_tint_001.png`，食物变淡 | 食物仍可见 |
| 黑夜 | 7s | `overlay_night_tint_001.png` + `overlay_stars_distant_lights_001.png` | 普通食物隐藏，光源玩法 |
| 黎明 | 3s | `overlay_dawn_transition_001.png` | 食物恢复 |

- 黑夜期每 3s 判定：
  - 暖黄光 70~90m，概率 65%，+5，贴图 `food_night_warm_light_insects_001.png`，VFX `vfx_warm_light_glow`
  - 冷白光 10~30m，概率 35%，-5，贴图 `food_cold_false_light_001.png`，VFX `vfx_cold_light_flicker`
- 黑夜期通过 `is_night_hiding_food()` / 信号通知 Spawner 隐藏普通食物的生成。

### 3.5 天敌（PredatorSystem）

- 前 30s 禁用。
- 基础生成概率随距离递增（DifficultySystem 的 `predator_chance`，上限 30%），按小鸟高度调制：

| 小鸟高度 | 倍率 |
| --- | --- |
| <30m | ×0.5 |
| 31~60m | ×1.0 |
| >60m | ×1.5 |

- 每只天敌状态机：

| 阶段 | 时长 | 行为 / 视觉 |
| --- | --- | --- |
| 出现 | 1.0s | 从右侧/上方进入，靠近小鸟，`predator_hawk_hover_001.png` |
| 蓄力 | 0.8s | 显示红色攻击轨迹 `predator_attack_trajectory_001.png`，锁定小鸟当前位置；HUD 警告箭头 |
| 冲刺 | 0.5s | 沿直线高速冲刺，`predator_hawk_dash_001.png` + `predator_hawk_afterimage` |
| 判定 | 瞬间 | 小鸟与攻击路径重叠则命中 |

- 命中：饱食度 -12，画面闪烁 `vfx_collision_flash`，羽毛粒子 `vfx_feather_particles`。
- 未命中：飞出画面左侧。
- 公平性：威胁出现给足 0.8s 反应时间；不与大型障碍同时压迫。

### 3.6 食物（Spawner，删诱饵 / 湖面飞虫）

| 食物类型 | 高度 | 饱食度 | 贴图 |
| --- | --- | --- | --- |
| 地面昆虫 | 0~15m | +8 | `food_ground_insect_001.png` |
| 种子 | 0~15m | +8 | `food_seed_cluster_001.png` |
| 灌木浆果 | 15~35m | +10 | `food_bush_berries_001.png` |
| 树冠虫蛹 | 35~70m | +12 | `food_canopy_larva_001.png` |
| 树冠果实 | 35~70m | +12 | `food_canopy_fruit_cluster_001.png` |

夜航暖光/冷光食物由 NightSystem 在黑夜期注入，不在常规生成表中。

- 基础食物判定间隔 1.5s（实际用 DifficultySystem 缩短后的值，最短 1.0s）。
- 最小水平间距 200px。
- 黑夜期隐藏常规食物。

### 3.7 障碍（Spawner）

| 障碍 | 高度 | 判定 | 碰撞效果 |
| --- | --- | --- | --- |
| 树木 | 树干/树冠 0~70m | 每 3s，概率 25%→40% | 饱食度 -10，暂停 0.3s，弹回 50px |
| 密实灌木 | 0~35m | 每 3s 内 15% 判定中的 60% | 饱食度 -5，暂停 0.2s |
| 稀疏灌木 | 0~35m | 同上的 40% | 浆果可见，叶片稀疏 |

移除诱饵。树木概率从 DifficultySystem 取。

### 3.8 失败与恢复（main.gd）

| 触发 | 结果 |
| --- | --- |
| 饱食度 ≤0 且高度 >0m | 坠落动画 `player_bird_falling_001.png`，3s 后游戏结束 |
| 饱食度 ≤0 且高度 =0m | 倒地 `player_bird_ground_collapse_001.png` |
| 倒地后 3s 内碰到食物 | 饱食度恢复到 10 |
| 倒地后未恢复 | 游戏结束 |

## 4. UI 与表现

### 4.1 HUD（hud.gd 改造，中文，美术贴图）

- 左上：饱食度表 `ui_hunger_meter`、高度表 `ui_height_meter`、湿度表 `ui_wetness_meter`（湿度>0 时显示）。
- 右上：距离牌 `ui_distance_sign`；夜航来临时显示夜航计时器 `ui_night_timer`。
- 食物拾取 / 受击：弹数值浮字 `ui_floating_delta`（"+8" / "-12" 等）。
- 天敌蓄力：屏幕边缘警告箭头 `ui_warning_arrow`。
- 游戏结束面板 `ui_pause_and_game_over_panels`，显示：飞行距离、飞行时间、收集食物数量、最高到达高度、历史最佳距离、"按 R 重试"。

### 4.2 VFX（即播即销毁）

| 事件 | 贴图 |
| --- | --- |
| 食物拾取 | `vfx_food_pickup_burst_gold_001.png` |
| 受击（障碍/天敌） | `vfx_collision_flash_001.png` + `vfx_feather_particles_001.png` |
| 加速 | `vfx_speed_lines_001.png` |
| 暖光食物 | `vfx_warm_light_glow_001.png` |
| 冷光食物 | `vfx_cold_light_flicker_001.png` |
| 暴雨 | `vfx_screen_darken_fade_001.png` |

### 4.3 玩家状态动画（player_bird.gd）

在现有 `fly` 动画基础上，按状态切换 `states/` 单帧贴图：爬升、下降、加速、受击、坠落、倒地。`set_state(state)` 由 main / player 内部逻辑调用。

### 4.4 暂停菜单（pause_menu.gd 新建，CanvasLayer）

- 游戏中按 ESC → `get_tree().paused = true` + 显示面板。
- 选项：继续 / 重新开始 / 音量滑块（Music + SFX）/ 返回标题。
- 面板贴图 `ui_pause_and_game_over_panels`，音效 `pause_open` / `pause_close`。
- 节点 `process_mode = ALWAYS` 以便暂停时仍响应。
- 版本号显示在标题页与暂停页角落，读 `application/config/version`。

## 5. 音频（audio_manager.gd，autoload）

- BGM：`homeward_birds_wind_ambient.ogg` 循环播放。
- 事件 SFX 映射（节选）：
  - 食物拾取：按类型选音（`food/*_pickup`）
  - 障碍命中：`obstacle/tree_hit_soft` / `dense_bush_hit`
  - 天敌：`predator/warning_far` / `aim_lock` / `dash_fast` / `hit_bird`
  - 夜航：`night/dusk_fade_in` / `night_arrive` / `dawn_return` / `warm_guiding_light_spawn` / `cold_light_flicker`
  - 天气：`weather/rain_warning_cloud` / `drizzle_loop_soft` / `rain_medium_loop` / `storm_mist_loop`
  - UI：`ui/menu_confirm` / `menu_hover` / `pause_open` / `pause_close`
  - 状态：`state/run_start` / `falling_warning` / `game_over_soft` / `recover_food_ground`
- 音量：音频总线 Master / Music / SFX，暂停菜单滑块调 Music + SFX 总线音量。

## 6. 存档（save_data.gd）

- 路径 `user://homeward_save.cfg`。
- 存历史最佳距离 `best_distance`。
- 游戏结束时比较并更新，结算面板显示当前与历史最佳。

## 7. 输入

`project.godot` 新增 `pause_menu` 动作（绑定 ESC）。现有 `bird_up` / `bird_down` / `bird_accelerate` / `restart_run` 保留。

## 8. 测试

现有 `tests/test_minimal_playable_static.py` 为静态源码检查，会因删系统 / 改数值而失败。处理：

- **更新现有测试**：移除诱饵（`food_ground_bait`）、湖面飞虫（`food_lake_insects`）、风相关断言。
- **新增接口断言**：DifficultySystem / WeatherSystem / NightSystem / PredatorSystem / PauseMenu / SaveData 的关键函数、信号、常量存在。
- **新增逻辑断言**：对 DifficultySystem 难度曲线的边界（0m / 1000m / 上限）做静态结构检查（纯文本断言，不运行 Godot）。

测试保持纯 Python 静态检查（不依赖 Godot 运行时），与现有测试一致。

## 9. 验证

- 在 Godot 编辑器中打开项目，确认无脚本解析错误。
- 运行 `python -m unittest tests/test_minimal_playable_static.py`，全绿。
- 手动游玩验证：飞行手感、雨/夜航/天敌触发、暂停菜单、结算与最高分保存。
- 由于环境可能无法运行 Godot GUI，若无法手动游玩将明确说明。

## 10. 实现顺序（建议）

1. 清理削减系统的连带内容（食物表、公式、难度项）+ DifficultySystem
2. 饱食度完整公式（main.gd）
3. WeatherSystem（雨 + 湿度 + 覆盖层）
4. NightSystem（夜航 + 暖/冷光）
5. PredatorSystem（天敌四阶段）
6. Spawner 改造（接入夜航可见性 + 难度参数）
7. Player 状态动画 + 失败/恢复
8. HUD 美术化 + VFX
9. PauseMenu + 版本号 + 输入
10. AudioManager + SaveData
11. 更新测试 + 验证
