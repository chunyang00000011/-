# Homeward Game Design v1.2

## 1. Project Summary

**Title:** Homeward / 归途

**Genre:** 2D side-view endless flying survival game

**Camera:** Horizontal landscape view. The bird appears to fly from left to right while the world scrolls from right to left.

**Core fantasy:** A small migratory shorebird crosses grassland, forest, rain, night, wind, and human-made traps while managing hunger and route choice.

**Core loop:**

1. Maintain flight and choose height.
2. Collect food by collision.
3. Avoid obstacles, traps, predators, and dangerous weather.
4. Balance low-altitude food rewards against high-altitude safety and wind benefits.
5. Survive as far as possible and record total distance.

## 2. Screen And Height Model

The game remains **landscape** for PC and Web. The `0m~100m` height range is an abstract gameplay height, not a literal full-scene physical scale.

### 2.1 Viewport

| Target | Base Resolution | Notes |
| --- | --- | --- |
| PC/Web prototype | 1280x720 | Current project target |
| Future wide support | 16:9 to 21:9 | Expand horizontally, keep gameplay height mapping stable |

### 2.2 Height Mapping

| Gameplay Height | Meaning | Screen Role |
| --- | --- | --- |
| 0m | Ground / water surface | Bottom interaction band |
| 15m | Ground food / traps | Low collision band |
| 30m | Low-altitude boundary | Bushes, dense obstacles |
| 60m | Mid/high boundary | Main safe route transition |
| 70m | Tree canopy food | Upper forest objects |
| 90m | Night warm-light route | High guiding-light band |
| 100m | High air ceiling | Top clamp |

The visible screen may cover a large vertical slice of the environment. The bird should be scaled smaller than the raw source art so the background and obstacles have room to read.

### 2.3 Vertical Camera / Background Movement

The bird has a gameplay height value from `0` to `100`. When the bird moves up or down, the visual world responds:

- The bird remains near the horizontal focus area, around 40% to 45% of screen width.
- The bird moves vertically within a comfortable screen band.
- The background layer shifts vertically opposite to the bird's height change, creating the feeling that the bird is climbing or descending through a taller environment.
- Background vertical movement is clamped at the image's upper and lower limits so empty space is never shown.
- Foreground objects and interactables use the same height-to-screen conversion as the bird.

For the current background, use a conservative vertical offset range first. If the source image does not contain enough vertical content, use parallax layers or painted extensions later.

## 3. Controls

### 3.1 Final Control Scheme

| Platform | Input | Effect |
| --- | --- | --- |
| PC/Web | `W` / Up Arrow | Climb |
| PC/Web | `S` / Down Arrow | Descend |
| PC/Web | `Space` / Left Mouse Hold | Accelerate |
| Mobile future | Swipe up | Climb |
| Mobile future | Swipe down | Descend |
| Mobile future | Hold screen | Accelerate |

Mouse click-to-step can remain as a prototype helper, but the formal design uses continuous climb/descent and hold-to-accelerate.

### 3.2 Movement Rules

| Rule | Value |
| --- | --- |
| Height range | `0m~100m` |
| Initial height | `50m` |
| Climb speed | `20m/s` |
| Descend speed | `20m/s` |
| Release behavior | Hold current height after `0.1s` smoothing |
| Normal scroll speed | `150 px/s` |
| Accelerated scroll speed | `270 px/s` |

## 4. Core Stats

| Stat | Range | Initial | Role |
| --- | --- | --- | --- |
| Hunger | `0~100` | `60` | Fuel for flight. Reaching `0` triggers collapse/fall logic. |
| Height | `0m~100m` | `50m` | Determines routes, collision bands, wind, resources, and predator risk. |
| Feather Wetness | `0~100` | `0` | Increases in rain and raises energy cost. |
| Distance | `0m+` | `0m` | Main score and difficulty driver. |
| Flight Time | `0s+` | `0s` | Drives night-cycle timing and some event scheduling. |

## 5. Hunger Consumption

Use one unified formula to avoid double-counting.

```text
final_consumption_per_0_5s =
base_consumption
* wind_multiplier
* wetness_multiplier
* height_multiplier
* speed_multiplier
+ operation_extra_cost
```

### 5.1 Base And Operation Cost

| State | Value |
| --- | --- |
| Base consumption | `1 / 0.5s` |
| Climbing extra cost | `+0.5 / 0.5s` |
| Descending extra cost | `+0.2 / 0.5s` |
| Accelerating extra cost | `+0.7 / 0.5s` |

### 5.2 Multipliers

| Variable | Condition | Multiplier |
| --- | --- | --- |
| Wind | Tailwind | `x0.6` |
| Wind | No wind | `x1.0` |
| Wind | Headwind | `x1.4` |
| Wetness | Dry `0~20` | `x1.0` |
| Wetness | Damp `21~50` | `x1.2` |
| Wetness | Wet `51~80` | `x1.5` |
| Wetness | Soaked `81~100` | `x2.0` |
| Height | `0~60m` | `x1.0` |
| Height | `61~100m` | `x0.8` |
| Speed | Normal | `x1.0` |
| Speed | Accelerating | `x1.4` |

## 6. Height Bands And Route Choice

| Height | Band | Food | Obstacles | Predator Risk | Wind Bias | Design Meaning |
| --- | --- | --- | --- | --- | --- | --- |
| `0~30m` | Low | Rich | High | Low | Headwind more likely | Rewarding but dangerous |
| `31~60m` | Mid | Medium | Medium | Medium | Balanced | Stable default route |
| `61~100m` | High | Sparse | Low | High | Tailwind more likely | Efficient but exposed |

## 7. Food System

Food is collected by collision. No click interaction is required.

| Food Type | Height Range | Hunger | Risk / Note |
| --- | --- | --- | --- |
| Ground insects / seeds | `0~15m` | `+8` | Requires flying close to ground |
| Ground bait | `0~10m` | `+15` | 60% chance to trigger trap |
| Bush berries | `15~35m` | `+10` | May be inside passable bush |
| Canopy larvae / fruit | `35~70m` | `+12` | Requires canopy-height flight |
| Night warm-light insects | `70~90m` | `+5` | Only during night |
| Lake flying insects | `20~50m` | `+5` | Only during lake segments |

### 7.1 Food Generation

| Rule | Value |
| --- | --- |
| Base check interval | `1.5s` |
| Minimum horizontal spacing | `200px` |
| Spawn height | Random within food type range |
| Visibility | Visible to player unless hidden by night or storm rules |
| Feedback | Food disappears, particles spawn, floating value appears |

## 8. Obstacle And Trap System

### 8.1 Trees

| Property | Value |
| --- | --- |
| Height coverage | Trunk/canopy roughly `0~70m` |
| Base spawn check | Every `3s`, 25% chance |
| Minimum spacing | `200px` |
| Collision effect | Hunger `-10`, pause `0.3s`, knockback `50px` |
| Food relation | Some canopies carry larvae/fruit |

### 8.2 Bushes

| Property | Value |
| --- | --- |
| Height coverage | `0~35m` |
| Base spawn check | Every `3s`, 15% chance |
| Passable variant | 40%, sparse leaves, berries visible |
| Dense variant | 60%, collision causes Hunger `-5`, pause `0.2s` |

### 8.3 Bird Trap

| Property | Value |
| --- | --- |
| Trigger object | Ground bait |
| Height | `0~10m` |
| Safe result | 40%, food gained normally |
| Trap result | 60%, net/basket triggers |
| Trap effect | Hunger `-15`, control locked for `3s` |
| Escape | Automatic after `3s`; optional future interaction can reduce duration |

## 9. Predator System

Predators are large dark silhouettes such as hawks or falcons.

| Phase | Duration | Behavior |
| --- | --- | --- |
| Appear | `1.0s` | Enters from right or top edge near the bird |
| Aim | `0.8s` | Shows red attack trajectory toward current bird position |
| Dash | `0.5s` | Dashes in a straight line |
| Resolve | Instant | Hit if bird overlaps path width |

| Result | Effect |
| --- | --- |
| Hit | Hunger `-12`, screen flash, feather particles |
| Miss | Predator exits left side |

Height modifies spawn chance:

| Bird Height | Multiplier |
| --- | --- |
| `<30m` | `x0.5` |
| `31~60m` | `x1.0` |
| `>60m` | `x1.5` |

## 10. Weather And Wind

### 10.1 Rain

| Rule | Value |
| --- | --- |
| Check interval | Every `8s` |
| Base chance | 12% |
| Duration | `10~18s` |
| Warning | Grey cloud shadow appears `2s` before rain |

| Stage | Time | Visual | Wetness |
| --- | --- | --- | --- |
| Drizzle | `0~4s` | Sparse diagonal rain | `+3/s` |
| Rain | `5~8s` | Dense diagonal rain | `+6/s` |
| Storm | `9s+` | Rain plus mist and lower contrast | `+10/s` |

After rain ends, wetness decreases by `3/s` until it returns to dry.

### 10.2 Wind

| Wind | Check | Base Chance | Duration | Effect |
| --- | --- | --- | --- | --- |
| Tailwind | Every `5s` | 20% | `6~10s` | Hunger multiplier `x0.6`, acceleration feels stronger |
| Headwind | Every `5s` | 15% | `4~8s` | Hunger multiplier `x1.4`, scroll speed reduced 20% |
| No wind | Fallback | Remaining time | Variable | Default state |

High altitude increases tailwind chance by 30%. Low altitude increases headwind chance by 30%.

## 11. Night Flight

Night is periodic, not random.

| Rule | Value |
| --- | --- |
| First trigger | `120s` |
| Cycle | Every `120s`, shortened by difficulty later |
| Total duration | `15s` |

| Stage | Duration | Visual | Gameplay |
| --- | --- | --- | --- |
| Dusk | `5s` | Sky darkens, food colors fade | Food still visible but less readable |
| Night | `7s` | Dark blue background, silhouettes | Normal food hidden; light-route gameplay active |
| Dawn | `3s` | Scene brightens | Food fades back in |

During full night:

| Light | Height | Chance | Effect |
| --- | --- | --- | --- |
| Warm yellow light | `70~90m` | 65% per `3s` check | Hunger `+5` |
| Cold white light | `10~30m` | 35% per `3s` check | Hunger `-5` |

## 12. Lake Segments

Lake segments interrupt the grassland/forest route.

| Rule | Value |
| --- | --- |
| Check | Every `800m` |
| Chance | 40% |
| Segment length | About `300m` of flight distance |
| Low-altitude effect | Ground food, bait, and low traps disappear |
| Special food | Flying insects can appear at `20~50m` |

## 13. Failure And Recovery

| Failure Trigger | Result |
| --- | --- |
| Hunger `<=0` and height `>0m` | Bird falls for `3s`, then game over |
| Hunger `<=0` and height `=0m` | Bird collapses on ground |
| Ground collapse with food collision within `3s` | Recover to Hunger `10` |
| Ground collapse without recovery | Game over |

Game over screen shows:

- Flight distance
- Flight time
- Food collected
- Highest altitude reached
- Best distance record

## 14. Difficulty Progression

Difficulty scales mainly by distance.

| Distance | Level | Changes |
| --- | --- | --- |
| `0~1000m` | Easy | Food generous, predators rare, weather mild |
| `1000~3000m` | Normal | Predators and trees increase |
| `3000~5000m` | Hard | Night more frequent, traps and headwind increase |
| `5000~8000m` | Extreme | Rain lasts longer, combined risks appear |
| `8000m+` | Survival | Most probabilities approach caps |

### 14.1 Scaling Rules

| System | Per `1000m` | Cap |
| --- | --- | --- |
| Food interval | Shortens by 5% | Minimum `1.0s` |
| Predator chance | `+3%` | 30% |
| Tree chance | `+3%` | 40% |
| Trap chance | `+1%` | 15% |
| Headwind chance | `+2%` | 25% |
| Rain duration | `+1s` | 28s |
| Night cycle | Every `2000m`, shorten by `10s` | Minimum `80s` |

## 15. Event Director

To prevent unfair overlaps, use an event director instead of letting every system spawn independently.

### 15.1 Spawn Lanes

| Lane | Examples | Can Overlap? |
| --- | --- | --- |
| Resource lane | Food, warm light, flying insects | Yes, if spacing is safe |
| Obstacle lane | Tree, dense bush, lake edge | Limited |
| Threat lane | Predator, trap result | Avoid stacking with major obstacle |
| Weather lane | Rain, wind, night | Can overlap, but cap intensity |

### 15.2 Fairness Rules

- Never spawn predator dash and unavoidable tree in the same immediate dodge window.
- Keep at least `0.8s` reaction time for threats.
- Never place food inside impossible collision geometry.
- During the first `30s`, disable predator and trap failure.
- During tutorial/prototype mode, show debug height bands and collision boxes.

## 16. MVP Development Scope

### V0.1 Core Flight

- Horizontal scrolling background
- Bird animation and smaller scale
- Continuous height value `0~100m`
- Vertical background/camera offset based on height
- Hunger, distance, and height UI
- Basic food collision
- Game over when hunger reaches zero

### V0.2 Route Choice

- Height bands
- Food type distribution
- Trees and bushes
- Unified hunger formula
- Basic difficulty scaling

### V0.3 Atmosphere And Risk

- Wind
- Rain and wetness
- Night flight
- Lake segments

### V0.4 Full Challenge

- Predators
- Bait/trap system
- Polish effects
- Save best score
- Export builds for Windows and Web

## 17. Deployment Plan

### 17.1 Internal Testing

1. Export Windows build first.
2. Share `.zip` with team.
3. Collect feedback on control feel, visibility, and hunger pacing.

### 17.2 Web Demo

1. Export Web build after asset sizes are optimized.
2. Keep initial load small.
3. Test Chrome, Edge, and Firefox.
4. Host on Gitee Pages, itch.io, or a static web host.

### 17.3 Release Checklist

- Main menu
- Pause menu
- Game over summary
- Audio volume controls
- Version number in UI
- Credits and asset license list
- Keyboard and touch controls documented
- Export presets committed if stable
- Team workflow documented in Git
