extends Node2D

const INITIAL_HUNGER: float = 60.0
const MAX_HUNGER: float = 100.0
const NORMAL_SCROLL_SPEED: float = 150.0
const ACCEL_SCROLL_SPEED: float = 270.0
const DISTANCE_PIXELS_PER_METER: float = 10.0

@onready var world: HomewardScrollingWorld = $World
@onready var player: HomewardPlayerBird = $Player
@onready var spawner: HomewardSpawner = $Spawner
@onready var hud: HomewardHUD = $HUD
@onready var intro: HomewardIntroScreen = $Intro

var running: bool = false
var hunger: float = INITIAL_HUNGER
var distance_m: float = 0.0
var flight_time: float = 0.0
var _intro_active: bool = true
var _hunger_tick_timer: float = 0.0
var _hit_pause_timer: float = 0.0


func _ready() -> void:
	spawner.food_collected.connect(_on_food_collected)
	spawner.obstacle_hit.connect(_on_obstacle_hit)
	intro.start_requested.connect(_on_intro_start_requested)
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
		hud.update_stats(hunger, player.height_m, distance_m, flight_time)
		return

	flight_time += delta
	_hit_pause_timer = maxf(0.0, _hit_pause_timer - delta)

	var scroll_speed: float = _current_scroll_speed()
	world.set_scroll_speed(scroll_speed)
	world.set_height_ratio(player.height_m / 100.0)
	spawner.scroll_speed = scroll_speed

	distance_m += scroll_speed * delta / DISTANCE_PIXELS_PER_METER
	_consume_hunger(delta)
	hud.update_stats(hunger, player.height_m, distance_m, flight_time)

	if hunger <= 0.0:
		_game_over()


func _reset_run() -> void:
	_prepare_run_state()
	_set_gameplay_active(true)


func _prepare_run_state() -> void:
	running = false
	hunger = INITIAL_HUNGER
	distance_m = 0.0
	flight_time = 0.0
	_hunger_tick_timer = 0.0
	_hit_pause_timer = 0.0

	player.reset()
	world.reset()
	world.set_scroll_speed(NORMAL_SCROLL_SPEED)
	spawner.reset()
	hud.hide_game_over()
	hud.update_stats(hunger, player.height_m, distance_m, flight_time)


func _set_gameplay_active(value: bool) -> void:
	running = value
	player.set_running(value)
	spawner.set_running(value)
	hud.visible = value
	if not value:
		world.set_scroll_speed(0.0)


func _on_intro_start_requested() -> void:
	_intro_active = false
	_reset_run()


func _current_scroll_speed() -> float:
	if _hit_pause_timer > 0.0:
		return 0.0
	if player.is_accelerating:
		return ACCEL_SCROLL_SPEED
	return NORMAL_SCROLL_SPEED


func _consume_hunger(delta: float) -> void:
	_hunger_tick_timer += delta

	while _hunger_tick_timer >= 0.5 and running:
		_hunger_tick_timer -= 0.5
		var cost: float = 1.0
		if player.is_climbing:
			cost += 0.5
		if player.is_descending:
			cost += 0.2
		if player.is_accelerating:
			cost += 0.7
		hunger = maxf(0.0, hunger - cost)


func _on_food_collected(hunger_gain: float) -> void:
	if not running:
		return
	hunger = minf(MAX_HUNGER, hunger + hunger_gain)
	hud.update_stats(hunger, player.height_m, distance_m, flight_time)


func _on_obstacle_hit(hunger_loss: float) -> void:
	if not running:
		return
	hunger = maxf(0.0, hunger - hunger_loss)
	_hit_pause_timer = 0.18
	if player.has_method("flash_damage"):
		player.flash_damage()
	hud.update_stats(hunger, player.height_m, distance_m, flight_time)
	if hunger <= 0.0:
		_game_over()


func _game_over() -> void:
	running = false
	world.set_scroll_speed(0.0)
	spawner.set_running(false)
	player.set_running(false)
	hud.show_game_over(distance_m, flight_time)
