# Homeward Audio Usage Map

This map is based on the gameplay and art docs. It separates final-ish source assets from local prototype SFX.

## Recommended Bus Layout

- `Music`: long ambience/music loops.
- `Ambience`: wind, rain, lake, night beds.
- `SFX_Player`: flap, accelerate, glide, fall, recover.
- `SFX_World`: food, obstacles, traps, predators, weather accents.
- `SFX_UI`: HUD ticks, menu, pause, warnings.

## Music And Long Ambience

| Event | File | Notes |
| --- | --- | --- |
| Daytime flight bed | `music/homeward_birds_wind_ambient.ogg` | Low volume, loop under gameplay. |
| Wind layer | `sfx/ambient/wind_whoosh_loop.ogg` | Crossfade volume by wind strength. |
| Rain loop | `sfx/weather/rain_on_window_loop.wav` | Use with generated drizzle/rain/storm layers. |
| Lake water | `sfx/gameplay/lake/water_lap_loop_01.wav` | Fade in during lake segment. |
| Lake insects | `sfx/gameplay/lake/insect_swarm_loop_01.wav` | Small, high, quiet layer above water. |
| Night bed | `sfx/gameplay/night/night_arrive_01.wav` | One-shot transition into night; can pair with lower music volume. |

## Player Flight

| Event | Files | Notes |
| --- | --- | --- |
| Normal wing flap | `sfx/gameplay/player/wing_flap_soft_*.wav` | Randomize pitch +/- 4%. |
| Climb | `sfx/gameplay/player/wing_climb_effort_01.wav` | Trigger while holding climb, rate-limited. |
| Descend/glide | `sfx/gameplay/player/wing_descend_glide_01.wav` | Short layer when descending starts. |
| Accelerate | `sfx/gameplay/player/accelerate_air_push_*.wav` plus `sfx/player/wings_flap_large/wings_flap_large.ogg` | Use generated whoosh for soft version; use downloaded flap as heavier accent after trimming/mixing. |
| Feather loss | `sfx/gameplay/player/feather_loss_soft_*.wav` | On damage, with feather VFX. |

## Food And Resource Feedback

| Food Type | Files |
| --- | --- |
| Ground insects | `sfx/gameplay/food/ground_insect_pickup_*.wav` |
| Seeds | `sfx/gameplay/food/seed_pickup_*.wav` |
| Bush berries | `sfx/gameplay/food/bush_berry_pickup_*.wav` |
| Canopy larvae | `sfx/gameplay/food/canopy_larva_pickup_*.wav` |
| Canopy fruit | `sfx/gameplay/food/canopy_fruit_pickup_*.wav` |
| Lake insects | `sfx/gameplay/food/lake_insect_pickup_*.wav` |
| Warm night lights | `sfx/gameplay/food/night_warm_light_pickup_*.wav` or `sfx/pickup/food_pickup_gem_gather_reverb.wav` |
| Cold false lights | `sfx/gameplay/food/cold_false_light_penalty_*.wav` |

## Obstacles, Traps, And Damage

| Event | Files |
| --- | --- |
| Tree hit | `sfx/gameplay/obstacle/tree_hit_soft_*.wav`, downloaded alternatives `sfx/impact/80_cc0_rpg_sfx/wood_*.ogg` |
| Sparse bush pass | `sfx/gameplay/obstacle/sparse_bush_pass_*.wav` |
| Dense bush hit | `sfx/gameplay/obstacle/dense_bush_hit_*.wav` |
| Ground bump | `sfx/gameplay/obstacle/ground_bump_01.wav` |
| Collision flash | `sfx/gameplay/obstacle/collision_flash_01.wav` |
| Trap hint | `sfx/gameplay/trap/bait_warning_string_*.wav` |
| Trap trigger | `sfx/gameplay/trap/net_snap_*.wav` |
| Basket/net drop | `sfx/gameplay/trap/basket_drop_01.wav` |
| Trapped struggle | `sfx/gameplay/trap/trapped_rustle_*.wav` |
| Escape release | `sfx/gameplay/trap/escape_release_01.wav` |

## Predator

| Event | Files |
| --- | --- |
| Predator appears | `sfx/gameplay/predator/warning_far_*.wav` |
| Aim / red trajectory | `sfx/gameplay/predator/aim_lock_*.wav` |
| Dash attack | `sfx/gameplay/predator/dash_fast_*.wav`, downloaded alternatives `sfx/threat/swishes/swishes/swish-*.wav` |
| Near miss | `sfx/gameplay/predator/near_miss_01.wav` |
| Hit bird | `sfx/gameplay/predator/hit_bird_01.wav`, downloaded alternatives `sfx/impact/80_cc0_rpg_sfx/creature_hurt_*.ogg` |
| Afterimage trail | `sfx/gameplay/predator/afterimage_trail_01.wav` |

## Weather, Wind, Night, Lake

| Event | Files |
| --- | --- |
| Rain warning cloud | `sfx/gameplay/weather/rain_warning_cloud_01.wav` |
| Drizzle | `sfx/gameplay/weather/drizzle_loop_soft_01.wav` |
| Medium rain | `sfx/gameplay/weather/rain_medium_loop_01.wav` |
| Storm mist | `sfx/gameplay/weather/storm_mist_loop_01.wav` |
| Droplets on feathers/UI | `sfx/gameplay/weather/droplet_on_feather_*.wav` |
| Tailwind starts | `sfx/gameplay/weather/tailwind_gust_*.wav` |
| Headwind starts | `sfx/gameplay/weather/headwind_pushback_*.wav` |
| Lake splash | `sfx/gameplay/lake/small_splash_*.wav` |
| Dusk starts | `sfx/gameplay/night/dusk_fade_in_01.wav` |
| Warm guiding light | `sfx/gameplay/night/warm_guiding_light_spawn_01.wav` |
| Cold false light | `sfx/gameplay/night/cold_light_flicker_01.wav` |
| Dawn return | `sfx/gameplay/night/dawn_return_01.wav` |

## UI And State

| Event | Files |
| --- | --- |
| Menu hover | `sfx/gameplay/ui/menu_hover_*.wav` |
| Menu confirm | `sfx/gameplay/ui/menu_confirm_01.wav` |
| Pause open/close | `sfx/gameplay/ui/pause_open_01.wav`, `sfx/gameplay/ui/pause_close_01.wav` |
| Warning arrow | `sfx/gameplay/ui/warning_arrow_01.wav` |
| Hunger gain/loss | `sfx/gameplay/ui/hunger_gain_tick_01.wav`, `sfx/gameplay/ui/hunger_loss_tick_01.wav` |
| Height band change | `sfx/gameplay/ui/height_band_change_01.wav` |
| Best distance | `sfx/gameplay/ui/best_distance_mark_01.wav` |
| Run start | `sfx/gameplay/state/run_start_01.wav` |
| Falling warning | `sfx/gameplay/state/falling_warning_01.wav` |
| Ground recovery | `sfx/gameplay/state/recover_food_ground_01.wav` |
| Game over | `sfx/gameplay/state/game_over_soft_01.wav` |

## Mixing Notes

- Keep ambience low. The project tone is healing and natural, so gameplay one-shots should be readable but not sharp.
- Use random variation for repeated pickups and flaps to avoid fatigue.
- Weather should be layered: wind base + drizzle/rain/storm + occasional droplets.
- Night should reduce normal pickup loudness and make warm/cold light cues more distinct.
- Predator warning should duck ambience slightly for about 0.8s so the warning remains fair.
