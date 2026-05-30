extends Area2D
class_name HomewardPlayerBird

const BIRD_FRAME_DIR: String = "res://assets/bird/flying"

@export var initial_height_m: float = 50.0
@export var climb_speed_mps: float = 34.0
@export var descend_speed_mps: float = 34.0
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


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 6
	get_viewport().size_changed.connect(_layout)
	_setup_collision()
	_setup_animation()
	reset()


func _process(delta: float) -> void:
	_update_input(delta)
	_layout()
	_update_damage_flash(delta)


func reset() -> void:
	height_m = initial_height_m
	is_climbing = false
	is_descending = false
	is_accelerating = false
	_running = true
	_flash_time = 0.0
	modulate = Color.WHITE
	_layout()


func set_running(value: bool) -> void:
	_running = value
	if not _running:
		is_climbing = false
		is_descending = false
		is_accelerating = false


func flash_damage() -> void:
	_flash_time = 0.35


func _update_input(delta: float) -> void:
	if not _running:
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

	if is_climbing:
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

	var frame_files: Array[String] = _get_png_files(BIRD_FRAME_DIR)
	if frame_files.is_empty():
		push_error("No bird animation frames found in: %s" % BIRD_FRAME_DIR)
		return

	for frame_path in frame_files:
		var frame_texture: Texture2D = load(frame_path) as Texture2D
		if frame_texture != null:
			frames.add_frame("fly", frame_texture)

	sprite.sprite_frames = frames
	sprite.animation = "fly"
	sprite.play()
	sprite.flip_h = true
	sprite.scale = Vector2(0.45, 0.45)


func _get_png_files(path: String) -> Array[String]:
	var files: Array[String] = []
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_error("Cannot open bird frame directory: %s" % path)
		return files

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			files.append(path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files
