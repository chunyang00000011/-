extends Node2D

const INITIAL_HUNGER: float = 60.0
const MAX_HUNGER: float = 100.0
const NORMAL_SCROLL_SPEED: float = 280.0
const ACCEL_SCROLL_SPEED: float = 500.0
const DISTANCE_PIXELS_PER_METER: float = 10.0
const BACKGROUND_HEIGHT_RATIO: float = 0.5

const FALL_DURATION: float = 3.0
const COLLAPSE_RECOVER_WINDOW: float = 3.0
const COLLAPSE_RECOVER_HUNGER: float = 10.0

@onready var world: HomewardScrollingWorld = $World
@onready var player: HomewardPlayerBird = $Player
@onready var spawner: HomewardSpawner = $Spawner
@onready var hud: HomewardHUD = $HUD
@onready var intro: HomewardIntroScreen = $Intro
@onready var difficulty: HomewardDifficultySystem = $DifficultySystem
@onready var weather: HomewardWeatherSystem = $WeatherSystem
@onready var night: HomewardNightSystem = $NightSystem
@onready var predators: HomewardPredatorSystem = $PredatorSystem
@onready var vfx: HomewardVfx = $Vfx
@onready var pause_menu: HomewardPauseMenu = $PauseMenu
@onready var achievements: HomewardAchievementSystem = $AchievementSystem

const FLAP_COST: float = 3.0
const FLAP_COOLDOWN: float = 4.0
const FLAP_RADIUS: float = 320.0
const NEAR_MISS_GAIN: float = 4.0

const INSECT_FOOD_IDS: Array[String] = ["ground_insect", "canopy_larva"]

var running: bool = false
var hunger: float = INITIAL_HUNGER
var distance_m: float = 0.0
var flight_time: float = 0.0
var max_height_reached: float = 0.0
var food_count: int = 0

var _intro_active: bool = true
var _hunger_tick_timer: float = 0.0
var _hit_pause_timer: float = 0.0
var _falling: bool = false
var _fall_timer: float = 0.0
var _collapsed: bool = false
var _collapse_timer: float = 0.0
var _flap_cooldown: float = 0.0
var _ate_cold_light_this_night: bool = false
var _scroll_multiplier: float = 1.0
var _achievement_check_timer: float = 0.0
var _was_climbing: bool = false
var _was_descending: bool = false
var _was_accelerating: bool = false
var _height_band: String = "low"
var _droplet_timer: float = 0.0


func _ready() -> void:
	spawner.food_collected.connect(_on_food_collected)
	spawner.obstacle_hit.connect(_on_obstacle_hit)
	night.light_food_requested.connect(_on_light_food_requested)
	night.night_phase_changed.connect(_on_night_phase_changed)
	weather.weather_phase_changed.connect(_on_weather_phase_changed)
	predators.predator_hit.connect(_on_predator_hit)
	predators.predator_warning.connect(_on_predator_warning)
	predators.predator_dodged.connect(_on_predator_dodged)
	predators.predator_near_miss.connect(_on_predator_near_miss)
	achievements.achievement_unlocked.connect(_on_achievement_unlocked)
	intro.start_requested.connect(_on_intro_start_requested)
	pause_menu.resume_requested.connect(_on_resume_requested)
	pause_menu.restart_requested.connect(_on_pause_restart_requested)
	pause_menu.quit_to_title_requested.connect(_on_quit_to_title_requested)

	predators.set_player(player)
	night.set_player(player)

	_prepare_run_state()
	_set_gameplay_active(false)
	intro.begin()


func _process(delta: float) -> void:
	if _intro_active:
		return

	if Input.is_action_just_pressed("restart_run"):
		_reset_run()
		return

	if not running:
		_process_end_states(delta)
		return

	flight_time += delta
	max_height_reached = maxf(max_height_reached, player.height_m)
	_hit_pause_timer = maxf(0.0, _hit_pause_timer - delta)
	_flap_cooldown = maxf(0.0, _flap_cooldown - delta)

	if Input.is_action_just_pressed("bird_flap"):
		_try_flap()

	_apply_difficulty()

	var scroll_speed: float = _current_scroll_speed()
	world.set_scroll_speed(scroll_speed)
	world.set_height_ratio(BACKGROUND_HEIGHT_RATIO)
	spawner.scroll_speed = scroll_speed

	distance_m += scroll_speed * delta / DISTANCE_PIXELS_PER_METER
	_consume_hunger(delta)

	if weather.is_raining():
		achievements_add_stat("rain_seconds", delta)

	_achievement_check_timer += delta
	if _achievement_check_timer >= 0.5:
		_achievement_check_timer = 0.0
		achievements.check_unlocks()

	spawner.set_hide_regular_food(night.is_night_hiding_food())
	vfx.set_speed_lines_active(player.is_accelerating)
	_update_flight_audio(delta)

	_update_hud()

	if hunger <= 0.0:
		_begin_failure()


func _process_end_states(delta: float) -> void:
	# 坠落 / 倒地阶段：系统已停，但仍推进结束动画与恢复窗口。
	if _falling:
		_fall_timer += delta
		_update_hud()
		if player.is_on_ground():
			_enter_collapse()
		elif _fall_timer >= FALL_DURATION:
			_game_over()
		return

	if _collapsed:
		_collapse_timer += delta
		_update_hud()
		if _collapse_timer >= COLLAPSE_RECOVER_WINDOW:
			_game_over()
		return

	_update_hud()


func _reset_run() -> void:
	_prepare_run_state()
	_set_gameplay_active(true)
	achievements_add_stat("runs", 1.0)
	achievements.check_unlocks()
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.play_music()
		audio.play_sfx("run_start")
		audio.set_wind_active(true)
		audio.set_weather_phase("clear")


func _prepare_run_state() -> void:
	running = false
	hunger = INITIAL_HUNGER
	distance_m = 0.0
	flight_time = 0.0
	max_height_reached = 50.0
	food_count = 0
	_hunger_tick_timer = 0.0
	_hit_pause_timer = 0.0
	_falling = false
	_fall_timer = 0.0
	_collapsed = false
	_collapse_timer = 0.0
	_flap_cooldown = 0.0
	_ate_cold_light_this_night = false
	_was_climbing = false
	_was_descending = false
	_was_accelerating = false
	_height_band = "low"
	_droplet_timer = 0.0

	_scroll_multiplier = 1.0
	player.reset()
	world.reset()
	world.set_height_ratio(BACKGROUND_HEIGHT_RATIO)
	world.set_scroll_speed(NORMAL_SCROLL_SPEED)
	spawner.reset()
	weather.reset()
	night.reset()
	predators.reset()
	vfx.reset()
	hud.hide_game_over()
	hud.set_warning_visible(false)
	_update_hud()


func _set_gameplay_active(value: bool) -> void:
	running = value
	player.set_running(value)
	spawner.set_running(value)
	weather.set_running(value)
	night.set_running(value)
	predators.set_running(value)
	pause_menu.set_active(value)
	hud.visible = value
	if not value:
		world.set_scroll_speed(0.0)


func _apply_difficulty() -> void:
	var params: Dictionary = difficulty.params_for_distance(distance_m)
	spawner.set_difficulty(float(params["food_interval"]), float(params["tree_chance"]))
	weather.set_rain_duration(float(params["rain_duration"]))
	night.set_period(float(params["night_period"]))
	predators.set_base_chance(float(params["predator_chance"]))
	_scroll_multiplier = float(params["scroll_multiplier"])


func _on_intro_start_requested() -> void:
	_intro_active = false
	_reset_run()


func _current_scroll_speed() -> float:
	if _hit_pause_timer > 0.0:
		return 0.0
	var base_speed: float = ACCEL_SCROLL_SPEED if player.is_accelerating else NORMAL_SCROLL_SPEED
	return base_speed * _scroll_multiplier


func _consume_hunger(delta: float) -> void:
	_hunger_tick_timer += delta

	while _hunger_tick_timer >= 0.5 and running:
		_hunger_tick_timer -= 0.5

		var base_cost: float = 1.3
		var multiplier: float = weather.get_wetness_multiplier()
		multiplier *= _height_multiplier()
		multiplier *= 1.4 if player.is_accelerating else 1.0

		var extra: float = 0.0
		if player.is_climbing:
			extra += 0.5
		if player.is_descending:
			extra += 0.2
		if player.is_accelerating:
			extra += 0.7

		var cost: float = base_cost * multiplier + extra
		hunger = maxf(0.0, hunger - cost)


func _height_multiplier() -> float:
	return 0.8 if player.height_m > 60.0 else 1.0


func _update_flight_audio(delta: float) -> void:
	if not has_node("/root/AudioManager"):
		return
	var audio = get_node("/root/AudioManager")

	# 进入爬升 / 下滑 / 加速时各触发一次起始音。
	if player.is_climbing and not _was_climbing:
		audio.play_sfx("wing_climb")
	if player.is_descending and not _was_descending:
		audio.play_sfx("wing_descend")
	if player.is_accelerating and not _was_accelerating:
		audio.play_sfx("accelerate")
	_was_climbing = player.is_climbing
	_was_descending = player.is_descending
	_was_accelerating = player.is_accelerating

	# 高度分层切换提示音（low / mid / high）。
	var band: String = spawner.height_layer_for(player.height_m)
	if band != _height_band:
		_height_band = band
		audio.play_sfx("height_band")

	# 雨天时偶发雨滴打在羽毛上的细节音。
	if weather.is_raining():
		_droplet_timer -= delta
		if _droplet_timer <= 0.0:
			audio.play_sfx("droplet")
			_droplet_timer = randf_range(1.2, 2.6)
	else:
		_droplet_timer = 0.0


func _on_food_collected(hunger_gain: float, food_id: String, world_pos: Vector2) -> void:
	if not running and not _collapsed:
		return

	# 倒地恢复：3s 内碰到正收益食物恢复到 10。
	if _collapsed:
		if hunger_gain > 0.0:
			_recover_from_collapse()
		return

	hunger = minf(MAX_HUNGER, hunger + hunger_gain)
	if hunger_gain > 0.0:
		food_count += 1
		achievements_add_stat("food_total", 1.0)
		if food_id in INSECT_FOOD_IDS:
			achievements_add_stat("insects", 1.0)
		achievements.check_unlocks()
	if food_id == "night_cold_light":
		_ate_cold_light_this_night = true
	if hunger >= MAX_HUNGER:
		achievements.notify_event("hunger_full")
	vfx.play_pickup(world_pos)
	hud.show_floating_delta(hunger_gain, world_pos)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_food_sfx(food_id)
	_update_hud()


func _on_obstacle_hit(hunger_loss: float, obstacle_kind: String, world_pos: Vector2) -> void:
	if not running:
		return
	hunger = maxf(0.0, hunger - hunger_loss)
	_hit_pause_timer = 0.3 if obstacle_kind == "tree" else 0.2
	player.flash_damage()
	vfx.play_hit(world_pos)
	hud.show_floating_delta(-hunger_loss, world_pos)
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.play_sfx("tree_hit" if obstacle_kind == "tree" else "bush_hit")
		audio.play_sfx("feather_loss")
	_update_hud()
	if hunger <= 0.0:
		_begin_failure()


func _on_predator_hit(hunger_loss: float) -> void:
	if not running:
		return
	hunger = maxf(0.0, hunger - hunger_loss)
	player.flash_damage()
	vfx.play_hit(player.global_position)
	hud.show_floating_delta(-hunger_loss, player.global_position)
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.play_sfx("predator_dash")
		audio.play_sfx("predator_hit")
		audio.play_sfx("feather_loss")
	_update_hud()
	if hunger <= 0.0:
		_begin_failure()


func _on_predator_warning(active: bool) -> void:
	hud.set_warning_visible(active)
	if active and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("predator_aim")


func _on_light_food_requested(config: Dictionary) -> void:
	spawner.spawn_light_food(config)
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		if String(config.get("id", "")) == "night_cold_light":
			audio.play_sfx("cold_light_spawn")
		else:
			audio.play_sfx("warm_light_spawn")


func _on_night_phase_changed(phase: String) -> void:
	hud.set_night_visible(phase != HomewardNightSystem.PHASE_DAY)
	hud.update_night_countdown(_night_phase_label(phase))
	if phase == HomewardNightSystem.PHASE_NIGHT:
		_ate_cold_light_this_night = false
	elif phase == HomewardNightSystem.PHASE_DAWN and running:
		# 撑到黎明：累计一次夜航；整夜未吃冷光则触发"我不上当"。
		achievements_add_stat("nights_survived", 1.0)
		achievements.check_unlocks()
		if not _ate_cold_light_this_night:
			achievements.notify_event("clean_night")
	if not has_node("/root/AudioManager"):
		return
	var audio = get_node("/root/AudioManager")
	match phase:
		HomewardNightSystem.PHASE_DUSK:
			audio.play_sfx("night_dusk")
		HomewardNightSystem.PHASE_NIGHT:
			audio.play_sfx("night_arrive")
		HomewardNightSystem.PHASE_DAWN:
			audio.play_sfx("night_dawn")


func _on_weather_phase_changed(phase: String) -> void:
	if not has_node("/root/AudioManager"):
		return
	var audio = get_node("/root/AudioManager")
	audio.set_weather_phase(phase)
	if phase == HomewardWeatherSystem.PHASE_WARNING:
		audio.play_sfx("rain_warning")


func _night_phase_label(phase: String) -> String:
	match phase:
		HomewardNightSystem.PHASE_DUSK:
			return "黄昏"
		HomewardNightSystem.PHASE_NIGHT:
			return "黑夜"
		HomewardNightSystem.PHASE_DAWN:
			return "黎明"
		_:
			return ""


func _begin_failure() -> void:
	if _falling or _collapsed:
		return
	running = false
	spawner.set_running(false)
	weather.set_running(false)
	night.set_running(false)
	predators.set_running(false)
	world.set_scroll_speed(0.0)
	vfx.set_speed_lines_active(false)

	if player.is_on_ground():
		_enter_collapse()
	else:
		_falling = true
		_fall_timer = 0.0
		player.set_running(false)
		player.enter_falling()
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("falling")


func _enter_collapse() -> void:
	_falling = false
	_collapsed = true
	_collapse_timer = 0.0
	player.set_running(false)
	player.enter_collapse()
	# 倒地后允许食物碰撞触发恢复，重新喂食 spawner。
	spawner.set_running(true)
	spawner.scroll_speed = NORMAL_SCROLL_SPEED
	world.set_scroll_speed(NORMAL_SCROLL_SPEED)


func _recover_from_collapse() -> void:
	_collapsed = false
	_collapse_timer = 0.0
	hunger = COLLAPSE_RECOVER_HUNGER
	player.clear_forced_state()
	player.set_running(true)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("recover")
	_set_gameplay_active(true)
	_update_hud()


func _game_over() -> void:
	_falling = false
	_collapsed = false
	running = false
	pause_menu.set_active(false)
	world.set_scroll_speed(0.0)
	spawner.set_running(false)
	player.set_running(false)
	vfx.set_speed_lines_active(false)

	var best: float = distance_m
	var new_record: bool = false
	if has_node("/root/SaveData"):
		var save = get_node("/root/SaveData")
		new_record = save.update_best_distance(distance_m)
		best = save.get_best_distance()
		save.flush()

	achievements.check_unlocks()

	hud.set_warning_visible(false)
	hud.show_game_over(distance_m, flight_time, food_count, max_height_reached, best)
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.stop_all_loops(0.8)
		audio.play_sfx("game_over")
		if new_record:
			audio.play_sfx("best_distance")


func _on_resume_requested() -> void:
	pass


func _on_pause_restart_requested() -> void:
	_reset_run()


func _on_quit_to_title_requested() -> void:
	_set_gameplay_active(false)
	_intro_active = true
	if has_node("/root/SaveData"):
		get_node("/root/SaveData").flush()
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.stop_all_loops(0.6)
		audio.stop_music()
	intro.begin()


func _update_hud() -> void:
	hud.update_stats(hunger, player.height_m, distance_m, flight_time)
	hud.update_wetness(weather.wetness)


func _try_flap() -> void:
	if _flap_cooldown > 0.0:
		return
	_flap_cooldown = FLAP_COOLDOWN
	hunger = maxf(0.0, hunger - FLAP_COST)
	predators.scare_predators(player.global_position, FLAP_RADIUS)
	vfx.play_flap(player.global_position)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("wing_flap")
	_update_hud()
	if hunger <= 0.0:
		_begin_failure()


func _on_predator_dodged() -> void:
	if not running:
		return
	achievements_add_stat("predators_dodged", 1.0)
	achievements.check_unlocks()


func _on_predator_near_miss() -> void:
	# 擦身：正反馈 + 计一次擦身。
	if not running:
		return
	hunger = minf(MAX_HUNGER, hunger + NEAR_MISS_GAIN)
	achievements_add_stat("near_miss", 1.0)
	achievements.check_unlocks()
	hud.show_floating_delta(NEAR_MISS_GAIN, player.global_position)
	hud.show_near_miss(player.global_position)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("predator_near_miss")
	_update_hud()


func _on_achievement_unlocked(_id: String, title: String, description: String) -> void:
	hud.show_achievement_toast(title, description)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("menu_confirm")


func achievements_add_stat(key: String, amount: float) -> void:
	if has_node("/root/SaveData"):
		get_node("/root/SaveData").add_stat(key, amount)
