extends Area2D
class_name HomewardPlayerBird

const BIRD_FRAME_DIR: String = "res://assets/bird/flying"
const BIRD_FRAME_PATHS := [
	"res://assets/bird/flying/player_bird_s04_f001.png",
	"res://assets/bird/flying/player_bird_s04_f002.png",
	"res://assets/bird/flying/player_bird_s04_f003.png",
	"res://assets/bird/flying/player_bird_s04_f004.png",
	"res://assets/bird/flying/player_bird_s04_f005.png",
	"res://assets/bird/flying/player_bird_s04_f006.png",
	"res://assets/bird/flying/player_bird_s04_f007.png",
	"res://assets/bird/flying/player_bird_s04_f008.png",
	"res://assets/bird/flying/player_bird_s04_f009.png",
	"res://assets/bird/flying/player_bird_s04_f010.png",
	"res://assets/bird/flying/player_bird_s04_f011.png",
	"res://assets/bird/flying/player_bird_s04_f012.png",
	"res://assets/bird/flying/player_bird_s04_f013.png",
	"res://assets/bird/flying/player_bird_s04_f014.png",
	"res://assets/bird/flying/player_bird_s04_f015.png",
	"res://assets/bird/flying/player_bird_s04_f016.png",
	"res://assets/bird/flying/player_bird_s04_f017.png",
	"res://assets/bird/flying/player_bird_s04_f018.png",
	"res://assets/bird/flying/player_bird_s04_f019.png",
	"res://assets/bird/flying/player_bird_s04_f020.png",
	"res://assets/bird/flying/player_bird_s04_f021.png",
	"res://assets/bird/flying/player_bird_s04_f022.png",
	"res://assets/bird/flying/player_bird_s04_f023.png",
	"res://assets/bird/flying/player_bird_s04_f024.png",
	"res://assets/bird/flying/player_bird_s04_f025.png",
]

const STATE_FLY: String = "fly"
const STATE_CLIMB: String = "climb"
const STATE_DESCEND: String = "descend"
const STATE_ACCELERATE: String = "accelerate"
const STATE_HIT: String = "hit"
const STATE_FALLING: String = "falling"
const STATE_COLLAPSE: String = "collapse"

const STATE_TEXTURES := {
	STATE_CLIMB: "res://assets/art/characters/player_bird/states/player_bird_climb_001.png",
	STATE_DESCEND: "res://assets/art/characters/player_bird/states/player_bird_descend_001.png",
	STATE_ACCELERATE: "res://assets/art/characters/player_bird/states/player_bird_accelerate_001.png",
	STATE_HIT: "res://assets/art/characters/player_bird/states/player_bird_hit_001.png",
	STATE_FALLING: "res://assets/art/characters/player_bird/states/player_bird_falling_001.png",
	STATE_COLLAPSE: "res://assets/art/characters/player_bird/states/player_bird_ground_collapse_001.png",
}

const FALL_SPEED_MPS: float = 38.0

@export var initial_height_m: float = 50.0
@export var climb_speed_mps: float = 84.0
@export var descend_speed_mps: float = 84.0
@export var animation_fps: float = 14.0
@export var horizontal_focus_ratio: float = 0.43
@export var top_screen_ratio: float = 0.18
@export var bottom_screen_ratio: float = 0.82

@onready var sprite: AnimatedSprite2D = $Sprite

var height_m: float = 50.0
var is_climbing: bool = false
var is_descending: bool = false
var is_accelerating: bool = false

var _running: bool = true
var _flash_time: float = 0.0
var _hit_time: float = 0.0
var _forced_state: String = ""
var _state: String = STATE_FLY
var _state_textures_cache := {}
var _state_sprite: Sprite2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 14
	get_viewport().size_changed.connect(_layout)
	_setup_collision()
	_setup_animation()
	_setup_state_sprite()
	reset()


func _process(delta: float) -> void:
	_update_input(delta)
	if _forced_state == STATE_FALLING:
		height_m = maxf(0.0, height_m - FALL_SPEED_MPS * delta)
	_layout()
	_update_damage_flash(delta)
	_update_state(delta)


func reset() -> void:
	height_m = initial_height_m
	is_climbing = false
	is_descending = false
	is_accelerating = false
	_running = true
	_flash_time = 0.0
	_hit_time = 0.0
	_forced_state = ""
	modulate = Color.WHITE
	_apply_state(STATE_FLY)
	_layout()


func set_running(value: bool) -> void:
	_running = value
	if not _running:
		is_climbing = false
		is_descending = false
		is_accelerating = false


func flash_damage() -> void:
	_flash_time = 0.35
	_hit_time = 0.35


func enter_falling() -> void:
	_forced_state = STATE_FALLING


func enter_collapse() -> void:
	_forced_state = STATE_COLLAPSE
	height_m = 0.0


func clear_forced_state() -> void:
	_forced_state = ""


func is_on_ground() -> bool:
	return height_m <= 0.5


func _update_input(delta: float) -> void:
	if not _running or _forced_state != "":
		return

	var wants_up: bool = Input.is_action_pressed("bird_up")
	var wants_down: bool = Input.is_action_pressed("bird_down")
	is_accelerating = Input.is_action_pressed("bird_accelerate")
	is_climbing = wants_up and not wants_down
	is_descending = wants_down and not wants_up

	if is_climbing:
		height_m += climb_speed_mps * delta
	elif is_descending:
		height_m -= descend_speed_mps * delta

	height_m = clampf(height_m, 0.0, 100.0)


func _layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)

	position.x = viewport_size.x * horizontal_focus_ratio
	var top_y: float = viewport_size.y * top_screen_ratio
	var bottom_y: float = viewport_size.y * bottom_screen_ratio
	position.y = lerpf(bottom_y, top_y, height_m / 100.0)

	if _forced_state == STATE_FALLING:
		rotation_degrees = lerpf(rotation_degrees, 35.0, 0.12)
	elif _forced_state == STATE_COLLAPSE:
		rotation_degrees = lerpf(rotation_degrees, 0.0, 0.2)
	elif is_climbing:
		rotation_degrees = lerpf(rotation_degrees, -7.0, 0.18)
	elif is_descending:
		rotation_degrees = lerpf(rotation_degrees, 7.0, 0.18)
	else:
		rotation_degrees = lerpf(rotation_degrees, 0.0, 0.12)


func _update_damage_flash(delta: float) -> void:
	if _flash_time <= 0.0:
		modulate = Color.WHITE
		return

	_flash_time = maxf(0.0, _flash_time - delta)
	var pulse: float = 0.5 + 0.5 * sin(_flash_time * 60.0)
	modulate = Color(1.0, 0.75 + pulse * 0.25, 0.75 + pulse * 0.25)


func _update_state(delta: float) -> void:
	_hit_time = maxf(0.0, _hit_time - delta)
	var target: String = _resolve_state()
	if target != _state:
		_apply_state(target)


func _resolve_state() -> String:
	if _forced_state != "":
		return _forced_state
	if _hit_time > 0.0:
		return STATE_HIT
	if is_accelerating:
		return STATE_ACCELERATE
	if is_climbing:
		return STATE_CLIMB
	if is_descending:
		return STATE_DESCEND
	return STATE_FLY


func _apply_state(state: String) -> void:
	_state = state
	if state == STATE_FLY:
		sprite.visible = true
		if not sprite.is_playing():
			sprite.play()
		_state_sprite.visible = false
		return

	var texture: Texture2D = _get_state_texture(state)
	if texture == null:
		# 无对应贴图时退回飞行动画。
		sprite.visible = true
		_state_sprite.visible = false
		return

	sprite.visible = false
	_state_sprite.texture = texture
	_state_sprite.visible = true


func _get_state_texture(state: String) -> Texture2D:
	if _state_textures_cache.has(state):
		return _state_textures_cache[state]
	var path: String = String(STATE_TEXTURES.get(state, ""))
	var texture: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	_state_textures_cache[state] = texture
	return texture


func _setup_state_sprite() -> void:
	_state_sprite = Sprite2D.new()
	_state_sprite.name = "StateSprite"
	_state_sprite.flip_h = true
	_state_sprite.scale = Vector2(0.55, 0.55)
	_state_sprite.visible = false
	add_child(_state_sprite)


func _setup_collision() -> void:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)

	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 30.0
	shape_node.shape = circle


func _setup_animation() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", animation_fps)

	if BIRD_FRAME_PATHS.is_empty():
		push_error("No bird animation frames found in: %s" % BIRD_FRAME_DIR)
		return

	for frame_path in BIRD_FRAME_PATHS:
		var frame_texture: Texture2D = load(frame_path) as Texture2D
		if frame_texture != null:
			frames.add_frame("fly", frame_texture)
		else:
			push_error("Cannot load bird animation frame: %s" % frame_path)

	sprite.sprite_frames = frames
	sprite.animation = "fly"
	sprite.play()
	sprite.flip_h = true
	sprite.scale = Vector2(0.45, 0.45)
