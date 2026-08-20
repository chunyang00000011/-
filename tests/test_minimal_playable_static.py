from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class MinimalPlayableStaticTest(unittest.TestCase):
    def test_minimal_playable_modules_exist_with_expected_interfaces(self):
        expected = {
            "scripts/player_bird.gd": ["height_m", "is_climbing", "is_descending", "is_accelerating", "func reset"],
            "scripts/scrolling_world.gd": ["func set_scroll_speed", "func set_height_ratio", "func reset"],
            "scripts/spawner.gd": ["signal food_collected", "signal obstacle_hit", "func set_running", "func reset"],
            "scripts/collectible_food.gd": ["signal collected", "hunger_gain", "func setup"],
            "scripts/obstacle.gd": ["signal hit", "hunger_loss", "func setup"],
            "scripts/hud.gd": ["func update_stats", "func show_game_over", "func hide_game_over"],
        }

        for path, snippets in expected.items():
            self.assertTrue((ROOT / path).exists(), f"missing {path}")
            source = read(path)
            for snippet in snippets:
                self.assertIn(snippet, source, f"{path} missing {snippet}")

    def test_main_scene_wires_modular_runtime_nodes(self):
        scene = read("scenes/main.tscn")

        for node_name in [
            "World",
            "Player",
            "Spawner",
            "HUD",
            "Intro",
            "DifficultySystem",
            "WeatherSystem",
            "NightSystem",
            "PredatorSystem",
            "AchievementSystem",
            "Vfx",
            "PauseMenu",
        ]:
            self.assertIn(f'name="{node_name}"', scene)

        for script_path in [
            "res://scripts/main.gd",
            "res://scripts/scrolling_world.gd",
            "res://scripts/player_bird.gd",
            "res://scripts/spawner.gd",
            "res://scripts/hud.gd",
            "res://scripts/intro_screen.gd",
            "res://scripts/difficulty_system.gd",
            "res://scripts/weather_system.gd",
            "res://scripts/night_system.gd",
            "res://scripts/predator_system.gd",
            "res://scripts/vfx.gd",
            "res://scripts/pause_menu.gd",
            "res://scripts/achievement_system.gd",
        ]:
            self.assertIn(script_path, scene)

    def test_intro_assets_and_flow_are_wired_before_gameplay(self):
        scene = read("scenes/main.tscn")
        main = read("scripts/main.gd")
        intro = read("scripts/intro_screen.gd")

        for asset_path in [
            "assets/intro/homeward_intro.mp4",
            "assets/intro/homeward_intro.ogv",
            "assets/intro/homeward_title.png",
        ]:
            self.assertTrue((ROOT / asset_path).exists(), f"missing {asset_path}")

        for snippet in [
            "VideoStreamPlayer",
            "TextureRect",
            "ClickPrompt",
            "res://assets/intro/homeward_intro.mp4",
            "res://assets/intro/homeward_intro.ogv",
            "res://assets/intro/homeward_title.png",
        ]:
            self.assertIn(snippet, scene)

        for snippet in [
            "signal start_requested",
            "func begin",
            "_on_video_finished",
            "show_title",
            "点击屏幕开始你的归途",
            "InputEventMouseButton",
            "InputEventScreenTouch",
        ]:
            self.assertIn(snippet, intro)

        for snippet in [
            "var _intro_active: bool = true",
            "intro.start_requested.connect(_on_intro_start_requested)",
            "_set_gameplay_active(false)",
            "_on_intro_start_requested",
            "player.set_running(value)",
            "spawner.set_running(value)",
            "hud.visible = value",
        ]:
            self.assertIn(snippet, main)

    def test_project_input_actions_support_continuous_flight_acceleration_restart_and_pause(self):
        project = read("project.godot")

        for action in ["bird_up", "bird_down", "bird_accelerate", "restart_run", "pause_menu"]:
            self.assertIn(f"{action}=", project)

        self.assertIn('"keycode":32', project)
        self.assertIn('"button_index":1', project)
        self.assertIn('"keycode":82', project)
        self.assertIn('"keycode":4194305', project)  # KEY_ESCAPE

    def test_project_registers_autoloads_and_version(self):
        project = read("project.godot")

        self.assertIn("[autoload]", project)
        self.assertIn('AudioManager="*res://scripts/audio_manager.gd"', project)
        self.assertIn('SaveData="*res://scripts/save_data.gd"', project)
        self.assertIn("config/version=", project)

    def test_main_coordinates_core_game_loop_and_game_over(self):
        source = read("scripts/main.gd")

        for snippet in [
            "INITIAL_HUNGER",
            "_consume_hunger",
            "_game_over",
            "hud.show_game_over",
            "spawner.set_running(false)",
            'Input.is_action_just_pressed("restart_run")',
            "food_collected.connect",
            "obstacle_hit.connect",
        ]:
            self.assertIn(snippet, source)

    def test_weight_metric_is_not_part_of_current_design_or_runtime(self):
        checked_paths = [
            "docs/归途_游戏设计规格.md",
            "docs/homeward_game_design.md",
            "docs/归途_美术风格设定.md",
            "docs/art_asset_overview.md",
            "scripts/main.gd",
            "scripts/hud.gd",
            "scripts/spawner.gd",
            "scripts/collectible_food.gd",
        ]

        for path in checked_paths:
            source = read(path).lower()
            self.assertNotIn("体重", source, f"{path} should not mention 体重")
            self.assertNotIn("weight", source, f"{path} should not mention weight")

    def test_removed_systems_are_not_present(self):
        # 风、湖泊、陷阱（含诱饵/湖面飞虫）已从设计中删除。
        spawner = read("scripts/spawner.gd")
        main = read("scripts/main.gd")

        for removed in ["food_ground_bait", "food_lake_insects", "ground_bait", "lake_insects"]:
            self.assertNotIn(removed, spawner, f"spawner should not reference removed {removed}")

        # 饱食度公式不含风向倍率。
        self.assertNotIn("风向", main)
        self.assertNotIn("headwind", main.lower())
        self.assertNotIn("tailwind", main.lower())

    def test_bushes_are_grounded_sparse_obstacles_with_split_timers(self):
        player = read("scripts/player_bird.gd")
        spawner = read("scripts/spawner.gd")

        self.assertIn("@export var climb_speed_mps: float = 84.0", player)
        self.assertIn("@export var descend_speed_mps: float = 84.0", player)
        # 树木与灌木各自独立判定（每 3s），不再用单一 obstacle_interval。
        self.assertIn("const OBSTACLE_CHECK_INTERVAL: float = 3.0", spawner)
        self.assertIn("const BUSH_CHANCE: float = 0.15", spawner)
        self.assertIn("func _spawn_tree", spawner)
        self.assertIn("func _spawn_bush", spawner)
        self.assertIn("_ground_obstacle_position(spawn_x, float(config[\"visual_scale\"]), texture)", spawner)
        self.assertIn("Vector2(155.0, 82.0)", spawner)

    def test_route_height_layers_and_food_types_are_configured(self):
        spawner = read("scripts/spawner.gd")
        food = read("scripts/collectible_food.gd")

        for snippet in [
            'const HEIGHT_LAYER_LOW: String = "low"',
            'const HEIGHT_LAYER_MID: String = "mid"',
            'const HEIGHT_LAYER_HIGH: String = "high"',
            "func height_layer_for(height_m: float) -> String:",
            "if height_m <= 30.0:",
            "if height_m <= 60.0:",
        ]:
            self.assertIn(snippet, spawner)

        expected_foods = {
            "ground_insect": ["0.0", "15.0", "8.0", "food_ground_insect_001.png"],
            "seed_cluster": ["0.0", "15.0", "8.0", "food_seed_cluster_001.png"],
            "bush_berries": ["15.0", "35.0", "10.0", "food_bush_berries_001.png"],
            "canopy_larva": ["35.0", "70.0", "12.0", "food_canopy_larva_001.png"],
            "canopy_fruit": ["35.0", "70.0", "12.0", "food_canopy_fruit_cluster_001.png"],
        }

        for food_id, snippets in expected_foods.items():
            self.assertIn(f'"id": "{food_id}"', spawner)
            for snippet in snippets:
                self.assertIn(snippet, spawner, f"{food_id} missing {snippet}")

        for snippet in [
            "var food_type: StringName",
            "var height_m: float",
            "func setup(spawn_position: Vector2, config: Dictionary) -> void:",
            'food_type = StringName(config["id"])',
            'hunger_gain = float(config["gain"])',
        ]:
            self.assertIn(snippet, food)

    def test_background_obstacles_do_not_follow_player_height(self):
        main = read("scripts/main.gd")
        world = read("scripts/scrolling_world.gd")

        self.assertNotIn("world.set_height_ratio(player.height_m / 100.0)", main)
        self.assertIn("const BACKGROUND_HEIGHT_RATIO: float = 0.5", main)
        self.assertIn("world.set_height_ratio(BACKGROUND_HEIGHT_RATIO)", main)
        self.assertIn("func set_height_ratio(value: float) -> void:", world)

    def test_obstacle_layers_spacing_and_hitboxes_are_configured(self):
        spawner = read("scripts/spawner.gd")

        for snippet in [
            "const MIN_OBSTACLE_FOOD_GAP_PX: float = 240.0",
            "var _last_resource_spawn_x: float = -9999.0",
            "var _last_obstacle_spawn_x: float = -9999.0",
            "func _spawn_x_for_channel(last_spawn_x: float, base_extra_x: float) -> float:",
            "_last_resource_spawn_x = food.position.x",
            "_last_obstacle_spawn_x = obstacle.position.x",
        ]:
            self.assertIn(snippet, spawner)

        for snippet in [
            "TREE_OBSTACLE_CONFIGS",
            '"min_scale": 0.42',
            '"max_scale": 0.68',
            "BUSH_OBSTACLE_CONFIGS",
            '"min_height": 0.0',
            '"max_height": 35.0',
            "Vector2(155.0, 82.0)",
        ]:
            self.assertIn(snippet, spawner)

    def test_hunger_formula_uses_wetness_height_speed_and_action_costs(self):
        main = read("scripts/main.gd")

        for snippet in [
            "weather.get_wetness_multiplier()",
            "_height_multiplier()",
            "1.4 if player.is_accelerating else 1.0",
            "extra += 0.5",
            "extra += 0.2",
            "extra += 0.7",
            "0.8 if player.height_m > 60.0 else 1.0",
        ]:
            self.assertIn(snippet, main)

    def test_difficulty_system_curves_and_bounds(self):
        difficulty = read("scripts/difficulty_system.gd")

        for snippet in [
            "func params_for_distance(distance_m: float) -> Dictionary:",
            "FOOD_INTERVAL_MIN",
            "TREE_CHANCE_MAX",
            "PREDATOR_CHANCE_MAX",
            "RAIN_DURATION_MAX",
            "NIGHT_PERIOD_MIN",
            '"food_interval"',
            '"tree_chance"',
            '"predator_chance"',
            '"rain_duration"',
            '"night_period"',
        ]:
            self.assertIn(snippet, difficulty)

    def test_weather_system_phases_and_wetness_multiplier(self):
        weather = read("scripts/weather_system.gd")

        for snippet in [
            "signal weather_phase_changed",
            "func get_wetness_multiplier() -> float:",
            "func set_rain_duration",
            "func is_raining() -> bool:",
            "PHASE_WARNING",
            "PHASE_DRIZZLE",
            "PHASE_RAIN",
            "PHASE_STORM",
            "var wetness: float = 0.0",
        ]:
            self.assertIn(snippet, weather)

    def test_night_system_cycle_and_light_food(self):
        night = read("scripts/night_system.gd")

        for snippet in [
            "signal night_phase_changed",
            "signal light_food_requested",
            "func is_night_hiding_food() -> bool:",
            "PHASE_DUSK",
            "PHASE_NIGHT",
            "PHASE_DAWN",
            "FIRST_TRIGGER: float = 120.0",
            "night_warm_light",
            "night_cold_light",
        ]:
            self.assertIn(snippet, night)

    def test_predator_system_height_modulation_and_safe_window(self):
        system = read("scripts/predator_system.gd")
        predator = read("scripts/predator.gd")

        for snippet in [
            "signal predator_hit",
            "signal predator_warning",
            "SAFE_START_TIME: float = 15.0",
            "func _height_multiplier() -> float:",
            "return 0.5",
            "return 1.5",
        ]:
            self.assertIn(snippet, system)

        for snippet in [
            "PHASE_APPEAR",
            "PHASE_AIM",
            "PHASE_DASH",
            "APPEAR_TIME: float = 1.0",
            "AIM_TIME: float = 0.6",
            "DASH_TIME: float = 0.5",
            "HIT_LOSS: float = 12.0",
        ]:
            self.assertIn(snippet, predator)

    def test_pause_menu_audio_and_save_systems_exist(self):
        pause = read("scripts/pause_menu.gd")
        audio = read("scripts/audio_manager.gd")
        save = read("scripts/save_data.gd")

        for snippet in [
            "signal resume_requested",
            "signal restart_requested",
            "signal quit_to_title_requested",
            "get_tree().paused = true",
            'is_action_pressed("pause_menu")',
        ]:
            self.assertIn(snippet, pause)

        for snippet in [
            "func play_music",
            "func play_sfx",
            "func set_music_volume",
            "func set_sfx_volume",
        ]:
            self.assertIn(snippet, audio)

        for snippet in [
            "func get_best_distance",
            "func update_best_distance",
            "user://homeward_save.cfg",
        ]:
            self.assertIn(snippet, save)

    def test_difficulty_enhancement_numbers(self):
        difficulty = read("scripts/difficulty_system.gd")
        predator_system = read("scripts/predator_system.gd")
        predator = read("scripts/predator.gd")
        main = read("scripts/main.gd")

        self.assertIn("PREDATOR_CHANCE_MAX: float = 0.45", difficulty)
        self.assertIn("0.04 * steps_1000", difficulty)
        self.assertIn("SAFE_START_TIME: float = 15.0", predator_system)
        self.assertIn("CHECK_INTERVAL: float = 1.6", predator_system)
        self.assertIn("AIM_TIME: float = 0.6", predator)
        self.assertIn("var base_cost: float = 1.3", main)

    def test_predator_early_lock_and_near_miss(self):
        predator = read("scripts/predator.gd")
        system = read("scripts/predator_system.gd")

        for snippet in [
            "AIM_LOCK_RATIO",
            "NEAR_MISS_RADIUS",
            "signal dodged",
            "signal near_miss",
            "func abort_attack",
            "_locked = true",
            "PHASE_FLEE",
            "dodged.emit()",
            "near_miss.emit()",
        ]:
            self.assertIn(snippet, predator)

        for snippet in [
            "signal predator_dodged",
            "signal predator_near_miss",
            "func scare_predators",
        ]:
            self.assertIn(snippet, system)

    def test_achievement_system_and_persistence(self):
        ach = read("scripts/achievement_system.gd")
        save = read("scripts/save_data.gd")
        main = read("scripts/main.gd")

        for ach_id in [
            "yi_niao",
            "cheng_le",
            "biao_fei",
            "bu_shang_dang",
            "min_jie",
            "xian_xiang",
            "luo_tang",
            "ye_xing",
            "wan_li",
            "chang_lai",
        ]:
            self.assertIn(f'"id": "{ach_id}"', ach)

        for snippet in [
            "signal achievement_unlocked",
            "func check_unlocks",
            "func notify_event",
        ]:
            self.assertIn(snippet, ach)

        for snippet in [
            "func add_stat",
            "func get_stat",
            "func is_unlocked",
            "func unlock",
            "func get_unlocked",
            "func flush",
        ]:
            self.assertIn(snippet, save)

        for snippet in [
            "achievements.achievement_unlocked.connect",
            "predators.predator_dodged.connect",
            "predators.predator_near_miss.connect",
            'achievements.notify_event("hunger_full")',
            'achievements.notify_event("clean_night")',
        ]:
            self.assertIn(snippet, main)

    def test_wing_flap_input_and_handler(self):
        project = read("project.godot")
        main = read("scripts/main.gd")
        vfx = read("scripts/vfx.gd")

        self.assertIn("bird_flap=", project)
        self.assertIn('"keycode":70', project)  # KEY_F
        for snippet in [
            "FLAP_COST",
            "FLAP_COOLDOWN",
            "FLAP_RADIUS",
            'Input.is_action_just_pressed("bird_flap")',
            "predators.scare_predators(",
            "vfx.play_flap(",
        ]:
            self.assertIn(snippet, main)
        self.assertIn("func play_flap", vfx)

    def test_night_vision_shader_wired(self):
        night = read("scripts/night_system.gd")
        self.assertTrue((ROOT / "assets/shaders/night_vision.gdshader").exists())

        for snippet in [
            "NIGHT_VISION_SHADER",
            "func set_player",
            "func _update_night_vision",
            "light_center",
            "ShaderMaterial",
            "NV_NIGHT_OUTER",
            "NV_DUSK_OUTER",
        ]:
            self.assertIn(snippet, night)

        shader = read("assets/shaders/night_vision.gdshader")
        self.assertIn("uniform vec2 light_center", shader)
        self.assertIn("uniform float darkness", shader)
        self.assertIn("smoothstep", shader)

    def test_hud_toast_and_achievement_list(self):
        hud = read("scripts/hud.gd")
        for snippet in [
            "func show_achievement_toast",
            "func show_near_miss",
            "_populate_achievement_list",
            "HomewardAchievementSystem.ACHIEVEMENTS",
        ]:
            self.assertIn(snippet, hud)


if __name__ == "__main__":
    unittest.main()
