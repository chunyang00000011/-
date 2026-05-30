extends Node2D

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const BACKGROUND_TEXTURE: Texture2D = preload("res://assets/backgrounds/background_1.png")
const BIRD_FRAME_DIR: String = "res://assets/bird/flying"

@export var background_speed: float = 180.0
@export var bird_step: float = 92.0
@export var bird_move_speed: float = 7.5
@export var bird_animation_fps: float = 14.0

@onready var background_a: Sprite2D = $BackgroundA
@onready var background_b: Sprite2D = $BackgroundB
@onready var bird: AnimatedSprite2D = $Bird

var _background_width: float = 0.0
var _bird_target_y: float = 0.0
var _bird_min_y: float = 95.0
var _bird_max_y: float = 625.0


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_setup_background()
	_setup_bird_animation()
	_layout()


func _process(delta: float) -> void:
	_scroll_background(delta)
	bird.position.y = lerp(bird.position.y, _bird_target_y, 1.0 - exp(-bird_move_speed * delta))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("bird_up"):
		_nudge_bird(-bird_step)
	elif event.is_action_pressed("bird_down"):
		_nudge_bird(bird_step)
	else:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event == null or not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var direction: float = -1.0 if mouse_event.position.y < bird.global_position.y else 1.0
			_nudge_bird(direction * bird_step)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_nudge_bird(bird_step)


func _setup_background() -> void:
	background_a.texture = BACKGROUND_TEXTURE
	background_b.texture = BACKGROUND_TEXTURE
	_background_width = float(BACKGROUND_TEXTURE.get_width())
	background_a.centered = false
	background_b.centered = false


func _setup_bird_animation() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", bird_animation_fps)

	var frame_files: Array[String] = _get_png_files(BIRD_FRAME_DIR)
	if frame_files.is_empty():
		push_error("No bird animation frames found in: %s" % BIRD_FRAME_DIR)
		return

	for frame_path in frame_files:
		var frame_texture: Texture2D = load(frame_path) as Texture2D
		if frame_texture != null:
			frames.add_frame("fly", frame_texture)

	bird.sprite_frames = frames
	bird.animation = "fly"
	bird.play()
	bird.flip_h = true
	bird.scale = Vector2(1.05, 1.05)


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


func _layout() -> void:
	var viewport_size: Vector2 = Vector2(get_viewport_rect().size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = VIEWPORT_SIZE

	var bg_scale: float = max(viewport_size.x / float(BACKGROUND_TEXTURE.get_width()), viewport_size.y / float(BACKGROUND_TEXTURE.get_height()))
	var scaled_height: float = float(BACKGROUND_TEXTURE.get_height()) * bg_scale
	_background_width = float(BACKGROUND_TEXTURE.get_width()) * bg_scale

	for background in [background_a, background_b]:
		background.scale = Vector2(bg_scale, bg_scale)
		background.position.y = (viewport_size.y - scaled_height) * 0.5

	background_a.position.x = 0.0
	background_b.position.x = _background_width

	bird.position.x = viewport_size.x * 0.43
	_bird_min_y = viewport_size.y * 0.18
	_bird_max_y = viewport_size.y * 0.82
	_bird_target_y = clamp(_bird_target_y if _bird_target_y > 0.0 else viewport_size.y * 0.5, _bird_min_y, _bird_max_y)
	bird.position.y = clamp(bird.position.y if bird.position.y > 0.0 else _bird_target_y, _bird_min_y, _bird_max_y)


func _scroll_background(delta: float) -> void:
	var movement: float = background_speed * delta
	background_a.position.x -= movement
	background_b.position.x -= movement

	if background_a.position.x <= -_background_width:
		background_a.position.x = background_b.position.x + _background_width
	if background_b.position.x <= -_background_width:
		background_b.position.x = background_a.position.x + _background_width


func _nudge_bird(amount: float) -> void:
	_bird_target_y = clamp(_bird_target_y + amount, _bird_min_y, _bird_max_y)
