extends Node2D
class_name HomewardVfx

## 一次性视觉特效播放器：即播即销毁。
## 食物拾取、受击、加速线等由 main.gd 触发。

const PICKUP_BURST_TEX: Texture2D = preload("res://assets/art/vfx/vfx_food_pickup_burst_gold_001.png")
const COLLISION_FLASH_TEX: Texture2D = preload("res://assets/art/vfx/vfx_collision_flash_001.png")
const FEATHER_TEX: Texture2D = preload("res://assets/art/vfx/vfx_feather_particles_001.png")
const SPEED_LINES_TEX: Texture2D = preload("res://assets/art/vfx/vfx_speed_lines_001.png")

var _canvas: CanvasLayer
var _speed_lines: TextureRect


func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "VfxCanvas"
	_canvas.layer = 9
	add_child(_canvas)
	_build_speed_lines()


func play_pickup(world_pos: Vector2) -> void:
	_spawn_world_burst(PICKUP_BURST_TEX, world_pos, 0.42, 0.45, Color(1, 0.95, 0.7))


func play_hit(world_pos: Vector2) -> void:
	_spawn_world_burst(COLLISION_FLASH_TEX, world_pos, 1.0, 0.3, Color(1, 0.85, 0.6))
	_spawn_world_burst(FEATHER_TEX, world_pos, 0.9, 0.7, Color(1, 1, 1))


func play_flap(world_pos: Vector2) -> void:
	# 振翅惊吓：青白色快速扩散环。
	_spawn_world_burst(COLLISION_FLASH_TEX, world_pos, 1.3, 0.35, Color(0.7, 0.95, 1.0))


func set_speed_lines_active(value: bool) -> void:
	if _speed_lines == null:
		return
	if value and not _speed_lines.visible:
		_speed_lines.visible = true
		_speed_lines.modulate.a = 0.0
		var tween := _speed_lines.create_tween()
		tween.tween_property(_speed_lines, "modulate:a", 0.55, 0.18)
	elif not value and _speed_lines.visible:
		var tween := _speed_lines.create_tween()
		tween.tween_property(_speed_lines, "modulate:a", 0.0, 0.18)
		tween.tween_callback(func() -> void: _speed_lines.visible = false)


func reset() -> void:
	if _speed_lines != null:
		_speed_lines.visible = false


func _spawn_world_burst(texture: Texture2D, world_pos: Vector2, base_scale: float, lifetime: float, tint: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = world_pos
	sprite.scale = Vector2.ONE * base_scale
	sprite.modulate = tint
	sprite.z_index = 30
	add_child(sprite)

	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ONE * base_scale * 1.5, lifetime)
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)
	tween.chain().tween_callback(sprite.queue_free)


func _build_speed_lines() -> void:
	_speed_lines = TextureRect.new()
	_speed_lines.texture = SPEED_LINES_TEX
	_speed_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speed_lines.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_speed_lines.stretch_mode = TextureRect.STRETCH_SCALE
	_speed_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speed_lines.visible = false
	_canvas.add_child(_speed_lines)
