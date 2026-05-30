extends Node2D
class_name HomewardScrollingWorld

const BACKGROUND_TEXTURE: Texture2D = preload("res://assets/art/environment/backgrounds_loopable/bg_scene_grassland_forest_day_001_loop_001.png")

@export var vertical_offset_px: float = 70.0

var _sprites: Array[Sprite2D] = []
var _background_width: float = 0.0
var _base_y: float = 0.0
var _scroll_speed: float = 0.0
var _height_ratio: float = 0.5


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_create_backgrounds()
	_layout()


func _process(delta: float) -> void:
	if _sprites.size() < 2:
		return

	var movement: float = _scroll_speed * delta
	for sprite in _sprites:
		sprite.position.x -= movement

	if _sprites[0].position.x <= -_background_width:
		_sprites[0].position.x = _sprites[1].position.x + _background_width
	if _sprites[1].position.x <= -_background_width:
		_sprites[1].position.x = _sprites[0].position.x + _background_width


func set_scroll_speed(value: float) -> void:
	_scroll_speed = maxf(0.0, value)


func set_height_ratio(value: float) -> void:
	_height_ratio = clampf(value, 0.0, 1.0)
	_apply_vertical_offset()


func reset() -> void:
	if _sprites.size() >= 2:
		_sprites[0].position.x = 0.0
		_sprites[1].position.x = _background_width
	set_height_ratio(0.5)


func _create_backgrounds() -> void:
	for child in get_children():
		child.queue_free()
	_sprites.clear()

	for index in range(2):
		var sprite := Sprite2D.new()
		sprite.name = "Background%d" % index
		sprite.texture = BACKGROUND_TEXTURE
		sprite.centered = false
		sprite.z_index = -20
		add_child(sprite)
		_sprites.append(sprite)


func _layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)

	var width_scale: float = viewport_size.x / float(BACKGROUND_TEXTURE.get_width())
	var height_scale: float = (viewport_size.y + vertical_offset_px * 2.0) / float(BACKGROUND_TEXTURE.get_height())
	var bg_scale: float = maxf(width_scale, height_scale)
	var scaled_height: float = float(BACKGROUND_TEXTURE.get_height()) * bg_scale
	_background_width = float(BACKGROUND_TEXTURE.get_width()) * bg_scale
	_base_y = (viewport_size.y - scaled_height) * 0.5

	for index in range(_sprites.size()):
		var sprite: Sprite2D = _sprites[index]
		sprite.scale = Vector2(bg_scale, bg_scale)
		sprite.position.x = float(index) * _background_width

	_apply_vertical_offset()


func _apply_vertical_offset() -> void:
	var offset_y: float = (_height_ratio - 0.5) * 2.0 * vertical_offset_px
	for sprite in _sprites:
		sprite.position.y = _base_y + offset_y
