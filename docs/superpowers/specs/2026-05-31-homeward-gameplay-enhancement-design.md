# 《归途》玩法增强设计 v1.0

日期：2026-05-31
状态：待用户确认
依赖：本设计在 `2026-05-31-homeward-systems-completion-design.md` 已实现的系统之上叠加，不重构既有架构。

## 1. 目标与范围

针对当前版本的五点反馈做增强：

1. **难度偏低** → 加快体力消耗、天敌更密更快但"可预判可躲"。
2. **可玩性不足** → 新增终身累计成就系统（幽默成就语）。
3. **交互性** → 新增"振翅惊吓"（主动反制）+ "擦身奖励"（被动正反馈）。
4. **夜晚视野** → 夜里加入跟随小鸟的柔和光圈，圈外压暗；黄昏圈大、黑夜最小、黎明放大消失。

已确认的方向（用户选择）：
- 难度强度：**明显增强**（体力 2.6/秒、天敌更密更快但可躲、安全期 15s）。
- 成就范围：**终身累计**（跨局持久化）。
- 交互机制：**振翅惊吓 + 擦身奖励**（不做夜间提灯、不做顺风气流——后者也与既有"删风系统"决定一致）。
- 夜视边缘：**柔和渐变**。

明确不做：夜间提灯、顺风/下降气流、单局成就重置。

## 2. 架构变更总览

| 文件 | 变更类型 | 说明 |
| --- | --- | --- |
| `scripts/difficulty_system.gd` | 改数值 | 天敌概率上限与增速提高 |
| `scripts/predator_system.gd` | 改数值 + 加方法 | 安全期/检测间隔缩短；新增 `scare_predators()`；转发 `predator_dodged` / `predator_near_miss` 信号 |
| `scripts/predator.gd` | 改逻辑 | 蓄力**提前锁定**并冻结轨迹（核心可躲性）；冲刺期擦身检测；可被惊吓打断 |
| `scripts/main.gd` | 改数值 + 接线 | 基础体力消耗上调；接成就系统；擦身奖励；振翅输入→惊吓 |
| `scripts/player_bird.gd` | 加逻辑 | 振翅动作的体力代价与冷却（或由 main 持有，见 §5.1） |
| `scripts/save_data.gd` | 扩展 | 终身累计统计 + 已解锁成就的读写 |
| `scripts/achievement_system.gd` | **新建** | 成就定义、解锁判定、`achievement_unlocked` 信号 |
| `scripts/night_system.gd` | 加逻辑 | 夜视光圈着色器，跟随小鸟，按阶段调半径 |
| `scripts/hud.gd` | 加逻辑 | 成就解锁 toast；结算/暂停页成就列表 |
| `scenes/main.tscn` | 加节点 | 挂 `AchievementSystem` 节点 |
| `project.godot` | 加输入 | 新增 `bird_flap` 动作 |
| `tests/test_minimal_playable_static.py` | 加断言 | 新接口/常量/成就定义的静态检查 |

`AchievementSystem` 做成挂在 `Main` 下的独立节点，只依赖 `SaveData`（autoload）做持久化，通过信号通知 HUD。其余系统通过 `main.gd` 喂事件给它，保持 `main.gd` 协调者角色不变。

## 3. 难度增强

### 3.1 体力消耗（main.gd）

`_consume_hunger()` 基础消耗 `base_cost` **1.0 → 1.3**（每 0.5s 结算，即 2.0/秒 → 2.6/秒）。其余倍率/操作额外消耗公式不变。初始饱食度 60、上限 100 不变。

> 影响：平均"必须进食"的节奏更紧，找食压力更真实。倒地恢复窗口（3s 内吃到正收益恢复到 10）保持不变，避免难度变化把容错砍没。

### 3.2 天敌密度与速度

| 参数 | 文件 | 现值 | 新值 |
| --- | --- | --- | --- |
| 安全期 `SAFE_START_TIME` | predator_system.gd | 30s | **15s** |
| 检测间隔 `CHECK_INTERVAL` | predator_system.gd | 2.2s | **1.6s** |
| 天敌概率上限 `PREDATOR_CHANCE_MAX` | difficulty_system.gd | 0.30 | **0.45** |
| 天敌概率增速 | difficulty_system.gd | +0.03 / 1000m | **+0.04 / 1000m** |
| 蓄力时长 `AIM_TIME` | predator.gd | 0.8s | **0.6s** |

按高度的概率倍率（<30m ×0.5 / 31–60m ×1.0 / >60m ×1.5）保持不变。

### 3.3 可躲性：提前锁定 + 冻结轨迹（核心改动）

**问题**：现在天敌在蓄力**结束的瞬间**才按小鸟当时位置锁定方向（predator.gd 蓄力期轨迹一直跟着小鸟），玩家无法在蓄力中靠移动躲开——只能靠运气。

**改法**：蓄力分两段——

| 子阶段 | 占蓄力比例 | 行为 |
| --- | --- | --- |
| 瞄准 | 前 40% | 轨迹线实时跟随小鸟，红色半透明 |
| 锁定 | 后 60% | **冻结**冲刺方向与轨迹线；轨迹变为更亮/更粗的"已锁定"样式，给出明确的"危险直线" |

冲刺沿锁定的那条直线进行。于是 `AIM_TIME=0.6s` 下，玩家有约 **0.36s** 在锁定后看到固定红线，可上/下移动离开该线完成躲避。"天敌变多变快"但"每一次都看得见、可破解"。

实现要点：predator.gd 在 `_tick_aim()` 内，当 `_timer >= AIM_TIME * 0.4` 时锁定 `_dash_dir` 并停止更新轨迹朝向，同时切换轨迹 `modulate`/缩放表示锁定。HUD 警告箭头在锁定瞬间起仍显示。

## 4. 成就系统（终身累计）

### 4.1 持久化（save_data.gd 扩展）

在现有 `best_distance` 之外，新增累计计数与已解锁集合，写入同一 `user://homeward_save.cfg`：

```
[progress]
best_distance = <float>          # 已有
[stats]                          # 新增：终身累计
runs = <int>                     # 游玩局数
food_total = <int>               # 累计吃食物次数（正收益）
insects = <int>                  # 累计吃昆虫（ground_insect + canopy_larva）
predators_dodged = <int>         # 累计躲过天敌冲刺
near_miss = <int>                # 累计擦身
nights_survived = <int>          # 累计经历夜航（撑到黎明）
rain_seconds = <float>           # 累计雨中飞行秒数
[achievements]                   # 新增：已解锁
unlocked = PackedStringArray([...])   # 成就 id 列表
```

新增 API：
- `add_stat(key: String, amount) -> void`（累加并保存）
- `get_stat(key: String) -> float`
- `is_unlocked(id: String) -> bool`
- `unlock(id: String) -> bool`（首次解锁返回 true 并保存）
- `get_unlocked() -> PackedStringArray`

写盘策略：累计计数在每局结束时批量落盘一次（避免每帧写盘）；成就解锁即时落盘。

### 4.2 成就定义（achievement_system.gd）

两类：**计数阈值型**（读 SaveData 累计值）与**事件触发型**（单局内满足某条件即永久解锁）。

| id | 标题 | 解锁条件 | 类型 |
| --- | --- | --- | --- |
| `yi_niao` | 我是益鸟 | 累计吃 10 只虫 | 计数 `insects ≥ 10` |
| `cheng_le` | 有点撑了 | 累计吃 20 次食物 | 计数 `food_total ≥ 20` |
| `biao_fei` | 膘肥体壮 | 饱食度首次达到 100 | 事件 |
| `bu_shang_dang` | 我不上当 | 整夜未吃冷光假食并撑到黎明 | 事件 |
| `min_jie` | 身手敏捷 | 累计躲过 20 次天敌冲刺 | 计数 `predators_dodged ≥ 20` |
| `xian_xiang` | 险象环生 | 累计擦身 10 次 | 计数 `near_miss ≥ 10` |
| `luo_tang` | 落汤鸟 | 累计雨中飞行 60s | 计数 `rain_seconds ≥ 60` |
| `ye_xing` | 夜行者 | 累计经历 5 次夜航 | 计数 `nights_survived ≥ 5` |
| `wan_li` | 万里归途 | 历史最佳距离 ≥ 5000m | 计数 `best_distance ≥ 5000` |
| `chang_lai` | 常来常往 | 累计游玩 20 局 | 计数 `runs ≥ 20` |

成就定义为脚本内常量数组（id / 标题 / 一行幽默描述 / 判定）。事件型由 main 在事件发生时调用 `achievement_system.notify_event(name, payload)`；计数型在累计值变化后统一 `check_unlocks()`。

### 4.3 事件接线（main.gd → achievement_system）

| 触发点（main.gd 现有回调） | 喂给成就系统 |
| --- | --- |
| `_on_food_collected`（正收益） | `food_total++`；若 food_id ∈ {ground_insect, canopy_larva} 则 `insects++`；冷光被吃则置本局"吃过冷光"标记 |
| 饱食度更新后 == 100 | `notify_event("hunger_full")` → `biao_fei` |
| `predator_dodged` 信号 | `predators_dodged++` |
| `predator_near_miss` 信号 | `near_miss++`（同时计一次 dodge） |
| 夜航 `PHASE_DAWN` 到达且本局存活 | `nights_survived++`；若本局"吃过冷光"标记为假 → `notify_event("clean_night")` → `bu_shang_dang` |
| 雨天每帧（`weather` 正在下雨） | `rain_seconds += delta` |
| `_reset_run` 开始新一局 | `runs++` |
| 游戏结束 | 比较并更新 `best_distance`（已有），批量落盘累计值 |

### 4.4 表现（hud.gd）

- **解锁 toast**：屏幕上方滑入小手账卡片（复用纸张主题色，代码绘制 `StyleBoxFlat` 即可，无需新美术），显示"🏅 成就解锁：<标题>"+ 一行描述，2.5s 后淡出。多个解锁排队逐条显示。音效复用 `menu_confirm`。
- **成就列表**：在结算面板与暂停面板新增"成就"区/页，列出全部成就，已解锁显示标题+描述，未解锁显示"???"或灰色锁定态。布局用现有 Label/VBox，不引入新贴图。

> 注：toast 文案中的奖牌图标如需图形而非 emoji，可后续用既有美术管线补一张小图标，本期先用文字/emoji，避免阻塞。

## 5. 交互机制

### 5.1 振翅惊吓

- **输入**：`project.godot` 新增动作 `bird_flap`，绑定一个空闲键（建议 `F`；与上/下/加速/重开/暂停不冲突）。
- **效果**：按下时对**处于蓄力阶段**、且在小鸟周围半径内的天敌触发"惊吓"——天敌中止攻击、向上飞离画面（不再冲刺）。对**已进入冲刺**的天敌无效（冲刺已锁死，只能靠移动躲）。
- **代价与冷却**：每次 -3 饱食度，冷却 4s（冷却中按键无效、不扣体力）。
- **数值**：惊吓半径 ≈ 320px（约等于天敌蓄力时的悬停距离）。
- **接线**：main 持有冷却计时器与输入检测（`Input.is_action_just_pressed("bird_flap")`），调用 `predators.scare_predators(player.global_position, 320.0)`；`predator_system.scare_predators()` 遍历子节点，对 AIM 阶段且在半径内的天敌调用 `predator.abort_attack()`。
- **predator.gd `abort_attack()`**：清警告 → 切到一个"逃离"状态（沿斜上方飞出画面后 `queue_free`），本次不计为 dodge（玩家是主动反制，不算"躲过冲刺"）。
- **表现**：小鸟位置弹出一圈快速扩散的半透明白环（复用 `vfx_collision_flash` 以青白色 modulate 播放即可）；音效复用 `predator_aim` 或后续补一个振翅声（本期可先复用）。

### 5.2 擦身奖励

- **触发**：天敌**冲刺未命中**，但冲刺过程中与小鸟的最近距离落在"擦身带"内（命中半径 38px 之外、但 ≤ 88px 内）。
- **奖励**：+4 饱食度，小鸟处弹浮字"好险!"（复用 `hud.show_floating_delta`，或专用文字弹窗）。
- **统计**：`near_miss++`，并同时计一次 `predators_dodged`。
- **接线**：predator.gd 在 `_tick_dash()` 每帧记录到 player 的最近距离 `_min_dash_dist`；冲刺结束进入 DONE 时判定：若 `_has_hit==false` 则发 `dodged`；若 `_min_dash_dist ≤ 88` 再发 `near_miss`。两信号经 predator_system 转发到 main。
- **目的**：把"天敌变多"从纯惩罚转为"贴身博弈有正反馈"，鼓励主动走位而非一味远离。无需新按键。

## 6. 夜晚视野光圈（柔和渐变）

### 6.1 表现

夜里在既有全屏夜色罩之上，叠加一个**跟随小鸟的柔和光圈**：圈内可见（仅受夜色罩本身的轻微染色），圈外平滑压暗。圆心跟随小鸟屏幕位置（随高度上下移动）。

| 阶段 | 光圈半径 | 圈外最大压暗 |
| --- | --- | --- |
| 黄昏 dusk | 大（外缘 ≈ 520px） | 轻（α ≈ 0.35） |
| 黑夜 night | 小（外缘 ≈ 300px） | 重（α ≈ 0.82） |
| 黎明 dawn | 由小平滑放大至消失 | 由重渐隐到 0 |
| 白天 day | 无（着色器关闭） | 0 |

阶段切换时半径/压暗用插值平滑过渡（约 0.6s），避免突变。柔和边缘由着色器的 `smoothstep` 内外半径实现。

### 6.2 实现

- **节点**：night_system 的覆盖 `CanvasLayer`（layer 7）内新增一个全屏 `ColorRect`，挂自定义 `canvas_item` 着色器；位于夜色 `TextureRect` 之上、HUD（更高 layer）之下。
- **着色器 uniform**：`light_center`（屏幕 UV，已做宽高比校正）、`inner_radius`、`outer_radius`（UV 单位）、`darkness`（0–1）。片元按到圆心的校正距离做 `smoothstep(inner, outer, d)`，输出 `vec4(0,0,0, darkness * v)`。宽高比校正：UV 的 x 乘以 `aspect = 1280/720`，圆心同样校正，保证是正圆而非椭圆。
- **跟随**：night_system 通过 `set_player(player)`（仿 predator_system）拿到小鸟引用，`_process` 中（仅夜航阶段）把 `player.global_position` 转成 UV 写入 `light_center`，并按当前阶段+过渡进度写 `outer_radius`/`darkness`。
- **协同**（无需额外工作）：暖光食物（70–90m）与冷光假食（10–30m）本就自带 glow，在缩小的视野里自然成为"光点导航"；圈外天敌虽难看清，但 HUD 警告箭头仍提示，张力提升且仍公平。

## 7. 输入变更（project.godot）

新增动作 `bird_flap`（建议绑定 `F` 键）。现有 `bird_up` / `bird_down` / `bird_accelerate` / `restart_run` / `pause_menu` 全部保留。

## 8. 测试（tests/test_minimal_playable_static.py）

保持纯 Python 静态源码检查（不依赖 Godot 运行时），新增断言：

- 数值改动：`base_cost` 含 1.3；predator_system 含 `SAFE_START_TIME = 15`、`CHECK_INTERVAL`≈1.6；difficulty 含 `PREDATOR_CHANCE_MAX`≈0.45；predator `AIM_TIME`≈0.6。
- 提前锁定：predator.gd 含蓄力比例锁定逻辑（断言存在锁定相关标记/方法）。
- 新接口：`predator_system.scare_predators`、`predator.abort_attack`、信号 `predator_dodged` / `predator_near_miss`。
- 成就：`achievement_system.gd` 存在且定义全部成就 id；`save_data.gd` 含 `add_stat`/`get_stat`/`is_unlocked`/`unlock`/`get_unlocked`。
- 夜视：night_system 含着色器/`light_center`/`set_player`。
- 输入：project.godot 含 `bird_flap`。

## 9. 验证

- `python -m unittest tests/test_minimal_playable_static.py` 全绿。
- 在 Godot 编辑器打开，确认无脚本/着色器解析错误。
- 手动游玩：体力压力是否合理、天敌锁定后是否真能靠走位躲、振翅是否能打断蓄力天敌、擦身是否弹"好险!"、夜里光圈是否跟随且黄昏大黑夜小、成就 toast 与列表是否正确、重启后成就/累计是否持久。
- 若环境无法运行 Godot GUI，将明确说明仅完成静态验证。

## 10. 实现顺序（建议）

1. save_data.gd 扩展（累计统计 + 成就持久化）
2. achievement_system.gd 新建 + 挂节点 + main 接线
3. 难度数值（main / difficulty_system / predator_system / predator）
4. 天敌提前锁定 + 冻结轨迹（predator.gd）
5. 擦身检测 + dodged/near_miss 信号 + main 奖励接线
6. 振翅惊吓（输入 + scare_predators + abort_attack + main 冷却/代价 + VFX）
7. 夜视光圈着色器（night_system + 跟随 + 阶段半径）
8. HUD 成就 toast + 成就列表
9. 更新测试 + 验证
