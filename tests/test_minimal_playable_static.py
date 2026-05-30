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

        for node_name in ["World", "Player", "Spawner", "HUD", "Intro"]:
            self.assertIn(f'name="{node_name}"', scene)

        for script_path in [
            "res://scripts/main.gd",
            "res://scripts/scrolling_world.gd",
            "res://scripts/player_bird.gd",
            "res://scripts/spawner.gd",
            "res://scripts/hud.gd",
            "res://scripts/intro_screen.gd",
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

    def test_project_input_actions_support_continuous_flight_acceleration_and_restart(self):
        project = read("project.godot")

        for action in ["bird_up", "bird_down", "bird_accelerate", "restart_run"]:
            self.assertIn(f"{action}=", project)

        self.assertIn('"keycode":32', project)
        self.assertIn('"button_index":1', project)
        self.assertIn('"keycode":82', project)

    def test_main_coordinates_core_game_loop_and_game_over(self):
        source = read("scripts/main.gd")

        for snippet in [
            "INITIAL_HUNGER",
            "_consume_hunger",
            "_game_over",
            "hud.show_game_over",
            "spawner.set_running(false)",
            "Input.is_action_just_pressed(\"restart_run\")",
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

    def test_bird_feels_faster_and_bushes_are_grounded_sparse_obstacles(self):
        player = read("scripts/player_bird.gd")
        spawner = read("scripts/spawner.gd")

        self.assertIn("@export var climb_speed_mps: float = 34.0", player)
        self.assertIn("@export var descend_speed_mps: float = 34.0", player)
        self.assertIn("@export var obstacle_interval: float = 4.6", spawner)
        self.assertIn("if _rng.randf() < 0.7:", spawner)
        self.assertIn("_ground_obstacle_position(spawn_x, 0.38, texture)", spawner)
        self.assertIn("Vector2(145.0, 70.0)", spawner)


if __name__ == "__main__":
    unittest.main()
