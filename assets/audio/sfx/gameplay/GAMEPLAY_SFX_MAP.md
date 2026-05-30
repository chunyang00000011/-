# Gameplay SFX Map

Generated event-level placeholder SFX for Homeward. These are synthesized locally so they can be used as prototype assets without additional external licensing. Replace or mix them with final authored sounds later.

## Player

- `player/wing_flap_soft_*.wav`: normal flap variation.
- `player/wing_climb_effort_01.wav`: continuous climb / repeated flap.
- `player/wing_descend_glide_01.wav`: descending glide.
- `player/accelerate_air_push_*.wav`: acceleration whoosh.
- `player/feather_loss_soft_*.wav`: hit feather particles.

## Food

- `food/ground_insect_pickup_*.wav`: ground insects.
- `food/seed_pickup_*.wav`: seeds.
- `food/bush_berry_pickup_*.wav`: bush berries.
- `food/canopy_larva_pickup_*.wav`: canopy larvae.
- `food/canopy_fruit_pickup_*.wav`: canopy fruit.
- `food/lake_insect_pickup_*.wav`: lake insects.
- `food/night_warm_light_pickup_*.wav`: safe night warm lights.
- `food/cold_false_light_penalty_*.wav`: cold false light penalty.

## Obstacles And Traps

- `obstacle/tree_hit_soft_*.wav`: tree collision.
- `obstacle/sparse_bush_pass_*.wav`: passable bush rustle.
- `obstacle/dense_bush_hit_*.wav`: dense bush impact.
- `obstacle/ground_bump_01.wav`: low-altitude ground contact.
- `trap/bait_warning_string_*.wav`: visible trap hint tick.
- `trap/net_snap_*.wav`: trap trigger.
- `trap/basket_drop_01.wav`: basket/net landing.
- `trap/trapped_rustle_*.wav`: trapped 3-second struggle loop pieces.
- `trap/escape_release_01.wav`: automatic escape release.

## Predator

- `predator/warning_far_*.wav`: predator entrance warning.
- `predator/aim_lock_*.wav`: 0.8s aim/trajectory warning.
- `predator/dash_fast_*.wav`: dash attack.
- `predator/near_miss_01.wav`: missed dash passes by.
- `predator/hit_bird_01.wav`: predator hit.
- `predator/afterimage_trail_01.wav`: trail/afterimage accent.

## Weather, Night, And Lake

- `weather/drizzle_loop_soft_01.wav`, `weather/rain_medium_loop_01.wav`, `weather/storm_mist_loop_01.wav`: layered rain intensity.
- `weather/tailwind_gust_*.wav`, `weather/headwind_pushback_*.wav`: wind state transitions.
- `weather/rain_warning_cloud_01.wav`: grey cloud warning.
- `weather/droplet_on_feather_*.wav`: wetness feedback.
- `lake/water_lap_loop_01.wav`, `lake/small_splash_*.wav`, `lake/insect_swarm_loop_01.wav`: lake segment.
- `night/dusk_fade_in_01.wav`, `night/night_arrive_01.wav`, `night/warm_guiding_light_spawn_01.wav`, `night/cold_light_flicker_01.wav`, `night/dawn_return_01.wav`: night cycle.

## UI And State

- `ui/menu_hover_*.wav`, `ui/menu_confirm_01.wav`, `ui/pause_open_01.wav`, `ui/pause_close_01.wav`: menus.
- `ui/warning_arrow_01.wav`: warning indicator.
- `ui/hunger_gain_tick_01.wav`, `ui/hunger_loss_tick_01.wav`, `ui/height_band_change_01.wav`, `ui/best_distance_mark_01.wav`: HUD feedback.
- `state/run_start_01.wav`, `state/falling_warning_01.wav`, `state/recover_food_ground_01.wav`, `state/game_over_soft_01.wav`: run lifecycle.
