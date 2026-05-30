extends Node2D
class_name HomewardSpawner

signal food_collected(hunger_gain: float)
signal obstacle_hit(hunger_loss: float)

const TREE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/art/environment/obstacles/obstacle_tree_tall_001.png"),
	preload("res://assets/art/environment/obstacles/obstacle_tree_food_points_001.png"),
]
const BUSH_TEXTURES: Array[Texture2D] = [
	preload("res://assets/art/environment/obstacles/obstacle_bush_dense_001.png"),
	preload("res://assets/art/environment/obstacles/obstacle_bush_sparse_001.png"),
]

@export var food_interval: float = 1.5
@export var obstacle_interval: float = 4.6

var scroll_speed: float = 150.0
var _running: bool = true
var _food_timer: float = 0.4
var _obstacle_timer: float = 1.8
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	for child in get_children():
		if child.has_method("set_scroll_speed"):
			child.set_scroll_speed(scroll_speed)

	if not _running:
		return

	_food_timer -= delta
	_obstacle_timer -= delta

	if _food_timer <= 0.0:
		_spawn_food()
		_food_timer = food_interval + _rng.randf_range(-0.25, 0.35)

	if _obstacle_timer <= 0.0:
		_spawn_obstacle()
		_obstacle_timer = obstacle_interval + _rng.randf_range(-0.45, 0.55)


func set_running(value: bool) -> void:
	_running = value


func reset() -> void:
	for child in get_children():
		child.queue_free()
	_food_timer = 0.4
	_obstacle_timer = 1.8
	_running = true


func _spawn_food() -> void:
	var height_m: float = _rng.randf_range(8.0, 70.0)
	var gain: float = 8.0
	var food_color: Color = Color(0.95, 0.82, 0.32)

	if height_m > 42.0:
		gain = 12.0
		food_color = Color(1.0, 0.92, 0.55)
	elif height_m > 22.0:
		gain = 10.0
		food_color = Color(0.95, 0.26, 0.22)

	var food := HomewardCollectibleFood.new()
	food.name = "Food"
	add_child(food)
	food.setup(_spawn_position_for_height(height_m, 90.0), gain, food_color, 15.0)
	food.collected.connect(_on_food_collected)


func _spawn_obstacle() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_x: float = viewport_size.x + 180.0

	var obstacle := HomewardObstacle.new()
	obstacle.name = "Obstacle"
	add_child(obstacle)

	if _rng.randf() < 0.7:
		var texture: Texture2D = TREE_TEXTURES[_rng.randi_range(0, TREE_TEXTURES.size() - 1)]
		obstacle.setup(Vector2(spawn_x, _screen_y_for_height(35.0)), texture, 0.72, 10.0, Vector2(130.0, 360.0))
	else:
		var texture: Texture2D = BUSH_TEXTURES[_rng.randi_range(0, BUSH_TEXTURES.size() - 1)]
		var loss: float = 5.0 if texture == BUSH_TEXTURES[0] else 3.0
		obstacle.setup(_ground_obstacle_position(spawn_x, 0.38, texture), texture, 0.38, loss, Vector2(145.0, 70.0))

	obstacle.hit.connect(_on_obstacle_hit)


func _spawn_position_for_height(height_m: float, extra_x: float) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	return Vector2(viewport_size.x + extra_x, _screen_y_for_height(height_m))


func _screen_y_for_height(height_m: float) -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)

	var top_y: float = viewport_size.y * 0.18
	var bottom_y: float = viewport_size.y * 0.82
	return lerpf(bottom_y, top_y, clampf(height_m / 100.0, 0.0, 1.0))


func _ground_obstacle_position(spawn_x: float, visual_scale: float, texture: Texture2D) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)

	var ground_y: float = viewport_size.y * 0.84
	var half_texture_height: float = float(texture.get_height()) * visual_scale * 0.5
	return Vector2(spawn_x, ground_y - half_texture_height)


func _on_food_collected(gain: float) -> void:
	food_collected.emit(gain)


func _on_obstacle_hit(loss: float) -> void:
	obstacle_hit.emit(loss)
