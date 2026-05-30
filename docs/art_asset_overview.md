# Homeward Art Asset Overview v1.0

## 1. Art Direction

The game should feel like a watercolor nature survival journey: soft but readable, calm in motion, tense when weather, night, predators, or traps appear.

Primary goals:

- Clear silhouettes at gameplay speed.
- Strong readability between food, danger, and background.
- Consistent side-view 2D perspective.
- Landscape composition with enough vertical room to represent `0m~100m` height.
- Small bird scale so route choice and background height movement can be seen.

## 2. Existing Assets

| Asset | Current Location | Project Location | Status |
| --- | --- | --- | --- |
| Bird frame sequence | `C:/Users/john/OneDrive/Desktop/hekes/assets/art/characters/player_bird/frames` | `res://assets/bird/flying/` | `s04` flying frames imported |
| Main background | `C:/Users/john/OneDrive/Desktop/interesting project/background_1.png` | `res://assets/backgrounds/background_1.png` | Imported |

## 3. Recommended Project Folders

```text
assets/
  art/
    backgrounds/
    characters/
      player_bird/
      predators/
    food/
    obstacles/
    traps/
    weather/
    vfx/
    ui/
  audio/
    music/
    sfx/
```

Current project can keep existing `assets/backgrounds` and `assets/bird/flying`, but future assets should move toward this structure when convenient.

## 4. Player Bird

### 4.1 Required Animations

| Animation | Priority | Notes |
| --- | --- | --- |
| Glide / fly loop | High | Current `s04` can be used; mirror horizontally if needed |
| Climb | High | Wings slightly lifted, body angled up |
| Descend | High | Body angled down, wings relaxed |
| Accelerate / flap | Medium | Faster wing motion, stronger silhouette |
| Hit / damage | Medium | Shake pose, feather loss |
| Trapped | Medium | Bird under net/basket |
| Falling | Medium | Wings limp or tumbling downward |
| Ground collapse | Low | For recovery/game-over state |

### 4.2 Size Guidance

| Context | Suggested Display Size |
| --- | --- |
| 1280x720 gameplay | Bird body about `70~100px` wide |
| UI icon | `64x64` or `96x96` |
| Source frame padding | Keep transparent padding consistent |

The current source frames are larger than needed for gameplay. Scale the displayed `AnimatedSprite2D` down rather than resizing source files at first.

## 5. Background And Environment

### 5.1 Background Layers

| Layer | Priority | Purpose |
| --- | --- | --- |
| Far sky | High | Supports day, dusk, night, rain tint |
| Distant grassland/forest | High | Slow parallax |
| Mid trees and hills | Medium | Sense of travel |
| Ground strip | High | Low-altitude reference |
| Foreground grass | Medium | Fast parallax, depth |

For vertical height movement, background art should be taller than the viewport or split into layers that can shift vertically without exposing empty space.

### 5.2 Scene Variants

| Scene | Priority | Required Visuals |
| --- | --- | --- |
| Grassland + forest | High | Main endless route |
| Lake segment | Medium | Water strip, reflections, no ground food |
| Dusk | Medium | Warm-to-blue tint overlay |
| Night | Medium | Dark sky, silhouettes, stars, guiding lights |
| Rain | Medium | Grey cloud layer and rain effects |

## 6. Food Assets

| Food | Height Band | Priority | Visual Requirement |
| --- | --- | --- | --- |
| Ground insects | `0~15m` | High | Small animated dark bug, readable against grass |
| Seeds | `0~15m` | Medium | Small pale cluster |
| Ground bait | `0~10m` | High | Grain pile plus visible string/stick warning |
| Bush berries | `15~35m` | High | Red berries, visible from background |
| Canopy larvae | `35~70m` | High | Pale cocoon/larva hanging from branch |
| Canopy fruit | `35~70m` | Medium | Red/orange fruit |
| Night warm-light insects | `70~90m` | High | Warm glow with small insect specks |
| Cold false light | `10~30m` | High | Cold flickering light, less inviting |
| Lake flying insects | `20~50m` | Medium | Small swarm above water |

Food should use clear color accents because the background is visually rich.

## 7. Obstacles

| Obstacle | Priority | Required Variants |
| --- | --- | --- |
| Tree | High | Trunk + canopy, 2 to 4 silhouettes |
| Tree with food | High | Same tree plus canopy food attachment points |
| Sparse bush | High | Passable, berries visible |
| Dense bush | High | Dangerous, darker and fuller silhouette |
| Lake edge | Medium | Soft entry/exit transition |

Obstacle collision art should match gameplay hitboxes. Avoid highly detailed branches that look dangerous but are non-colliding unless visually faded.

## 8. Trap Assets

| Asset | Priority | Notes |
| --- | --- | --- |
| Grain bait pile | High | Also listed as food |
| String/stick hint | High | Must be visible enough to teach risk |
| Basket/net idle | Medium | Subtle, partially hidden |
| Basket/net triggered | High | Fast animation covering bird |
| Trapped overlay | High | Net/basket over bird for 3 seconds |

The trap should feel risky but fair. The bait must have warning details, especially after the first few runs.

## 9. Predator Assets

| Asset | Priority | Notes |
| --- | --- | --- |
| Hawk/falcon silhouette | High | About 2x bird size |
| Hover/aim pose | High | Readable during 0.8s warning |
| Dash pose | High | Stretched body, aggressive silhouette |
| Trail/afterimage | Medium | Shows speed and direction |
| Red trajectory line | High | Gameplay readability |

Predators can begin as silhouettes. Detailed painting is less important than attack readability.

## 10. Weather And Time Effects

| Effect | Priority | Assets Needed |
| --- | --- | --- |
| Grey cloud warning | High | Wide transparent shadow/cloud strip |
| Drizzle | Medium | Sparse diagonal rain particles |
| Rain | Medium | Dense rain particles |
| Storm mist | Medium | Semi-transparent fog/noise overlay |
| Wetness feedback | Low | Small droplets on bird or UI |
| Dusk tint | Medium | Color overlay / gradient |
| Night overlay | Medium | Dark blue overlay |
| Dawn transition | Medium | Lightening color overlay |
| Stars / distant lights | Low | Ambient night detail |

Most weather can be implemented with particles, shaders, and tint overlays rather than full painted frame sequences.

## 11. UI Assets

| UI Element | Priority | Notes |
| --- | --- | --- |
| Hunger bar | High | Main survival stat |
| Wetness meter | Medium | Important once rain exists |
| Weight indicator | Medium | Small numeric or icon meter |
| Height meter | High | Shows `0~100m` with band markers |
| Distance counter | High | Main score |
| Wind indicator | Medium | Tailwind/headwind icon |
| Night timer | Medium | Appears before/during night |
| Warning arrow | High | Predator/trap offscreen warning |
| Floating numbers | High | Hunger gain/loss feedback |
| Pause menu | Medium | Required before release |
| Game over panel | High | Distance, time, best score |

UI should be quiet and readable, not decorative. The game world should remain the focus.

## 12. VFX Assets

| VFX | Priority | Notes |
| --- | --- | --- |
| Food pickup particles | High | Small burst, color matches food |
| Feather particles | Medium | On predator hit or crash |
| Collision flash | Medium | Tree/bush/predator impact |
| Speed lines | Medium | During acceleration |
| Warm light glow | High | Night reward route |
| Cold light flicker | High | Night danger route |
| Screen darken/fade | High | Night and game over |

Use reusable particle systems where possible.

## 13. Audio Asset List

| Audio | Priority | Notes |
| --- | --- | --- |
| Ambient wind | Medium | Looping, low volume |
| Wing flap | Medium | Used for acceleration/climb |
| Food pickup | High | Positive feedback |
| Damage hit | High | Short impact |
| Trap trigger | Medium | Snap/net sound |
| Predator warning | High | Tense cue |
| Rain loop | Medium | Scales with rain intensity |
| Night ambience | Medium | Quiet tonal loop |
| Game over sting | Medium | Short ending cue |

Audio can come later than gameplay, but pickup and damage sounds should arrive early because they improve feel immediately.

## 14. Asset Production Priority

### Phase A: MVP

1. Player bird scaled and animated.
2. Main scrolling background with vertical offset support.
3. Hunger bar, distance counter, height meter.
4. Ground insects, bush berries, canopy food.
5. Basic tree and bush.
6. Pickup and damage VFX.

### Phase B: Risk Systems

1. Ground bait.
2. Trap net/basket.
3. Predator silhouette and attack trajectory.
4. Wind indicator.
5. Collision feedback polish.

### Phase C: Atmosphere

1. Rain particles and cloud warning.
2. Night overlays and warm/cold lights.
3. Lake segment.
4. Additional parallax layers.
5. Audio pass.

### Phase D: Release

1. Main menu art.
2. Game icon.
3. Loading screen.
4. Credits screen.
5. Store/Web capsule images.
6. Final compressed asset variants.

## 15. Naming Conventions

Use lowercase English names to avoid path and export issues.

```text
player_bird_fly_001.png
player_bird_climb_001.png
food_ground_insect_001.png
obstacle_tree_oak_001.png
trap_net_trigger_001.png
predator_hawk_dash_001.png
ui_hunger_bar_fill.png
vfx_food_pickup.tres
```

Recommended Godot import settings:

- Keep source PNG transparency.
- Use lossless or high-quality compression for small sprites.
- Use texture filtering based on art style. For watercolor/painted art, linear filtering is acceptable.
- Keep `.import` files committed so teammates get consistent imports.

