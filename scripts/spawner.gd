extends Node2D
class_name HomewardSpawner

signal food_collected(hunger_gain: float, food_id: String, world_pos: Vector2)
signal obstacle_hit(hunger_loss: float, obstacle_kind: String, world_pos: Vector2)

const HEIGHT_LAYER_LOW: String = "low"
const HEIGHT_LAYER_MID: String = "mid"
const HEIGHT_LAYER_HIGH: String = "high"
const MIN_OBSTACLE_FOOD_GAP_PX: float = 240.0

const OBSTACLE_CHECK_INTERVAL: float = 3.0
const BUSH_CHANCE: float = 0.15

const TREE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/art/environment/obstacles/obstacle_tree_tall_001.png"),
	preload("res://assets/art/environment/obstacles/obstacle_tree_food_points_001.png"),
]
const BUSH_TEXTURES: Array[Texture2D] = [
	preload("res://assets/art/environment/obstacles/obstacle_bush_dense_001.png"),
	preload("res://assets/art/environment/obstacles/obstacle_bush_sparse_001.png"),
]
# 树木底部锚定地面，高度通过随机缩放体现：矮树轻松飞越，高树需爬升到接近最高空。
# max_scale 已封顶，确保小鸟升到 100m 时一定能飞越最高的树。
const TREE_OBSTACLE_CONFIGS: Array[Dictionary] = [
	{
		"texture_index": 0,
		"min_scale": 0.42,
		"max_scale": 0.68,
		"loss": 10.0,
	},
	{
		"texture_index": 1,
		"min_scale": 0.42,
		"max_scale": 0.66,
		"loss": 10.0,
	},
]
const BUSH_OBSTACLE_CONFIGS: Array[Dictionary] = [
	{
		"texture_index": 0,
		"min_height": 0.0,
		"max_height": 35.0,
		"visual_scale": 0.4,
		"loss": 5.0,
		"hitbox": Vector2(155.0, 82.0),
	},
	{
		"texture_index": 1,
		"min_height": 0.0,
		"max_height": 35.0,
		"visual_scale": 0.4,
		"loss": 3.0,
		"hitbox": Vector2(155.0, 82.0),
	},
]
const FOOD_TYPES: Array[Dictionary] = [
	{
		"id": "ground_insect",
		"layer": HEIGHT_LAYER_LOW,
		"min_height": 0.0,
		"max_height": 15.0,
		"gain": 8.0,
		"texture_path": "res://assets/art/food/food_ground_insect_001.png",
		"color": Color(0.95, 0.82, 0.32),
		"radius": 14.0,
		"visual_scale": 0.45,
	},
	{
		"id": "seed_cluster",
		"layer": HEIGHT_LAYER_LOW,
		"min_height": 0.0,
		"max_height": 15.0,
		"gain": 8.0,
		"texture_path": "res://assets/art/food/food_seed_cluster_001.png",
		"color": Color(0.95, 0.82, 0.32),
		"radius": 14.0,
		"visual_scale": 0.45,
	},
	{
		"id": "bush_berries",
		"layer": HEIGHT_LAYER_MID,
		"min_height": 15.0,
		"max_height": 35.0,
		"gain": 10.0,
		"texture_path": "res://assets/art/food/food_bush_berries_001.png",
		"color": Color(0.95, 0.26, 0.22),
		"radius": 15.0,
		"visual_scale": 0.42,
	},
	{
		"id": "canopy_larva",
		"layer": HEIGHT_LAYER_HIGH,
		"min_height": 35.0,
		"max_height": 70.0,
		"gain": 12.0,
		"texture_path": "res://assets/art/food/food_canopy_larva_001.png",
		"color": Color(1.0, 0.92, 0.55),
		"radius": 15.0,
		"visual_scale": 0.32,
	},
	{
		"id": "canopy_fruit",
		"layer": HEIGHT_LAYER_HIGH,
		"min_height": 35.0,
		"max_height": 70.0,
		"gain": 12.0,
		"texture_path": "res://assets/art/food/food_canopy_fruit_cluster_001.png",
		"color": Color(1.0, 0.92, 0.55),
		"radius": 16.0,
		"visual_scale": 0.25,
	},
]

@export var food_interval: float = 1.1
@export var tree_chance: float = 0.25

var scroll_speed: float = 150.0
var _running: bool = false
var _hide_regular_food: bool = false
var _food_timer: float = 0.25
var _tree_timer: float = OBSTACLE_CHECK_INTERVAL
var _bush_timer: float = OBSTACLE_CHECK_INTERVAL + 1.4
var _last_resource_spawn_x: float = -9999.0
var _last_obstacle_spawn_x: float = -9999.0
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
	_tree_timer -= delta
	_bush_timer -= delta

	if _food_timer <= 0.0:
		if not _hide_regular_food:
			_spawn_food()
		_food_timer = food_interval + _rng.randf_range(-0.2, 0.3)

	if _tree_timer <= 0.0:
		if _rng.randf() < tree_chance:
			_spawn_tree()
		_tree_timer = OBSTACLE_CHECK_INTERVAL

	if _bush_timer <= 0.0:
		if _rng.randf() < BUSH_CHANCE:
			_spawn_bush()
		_bush_timer = OBSTACLE_CHECK_INTERVAL


func set_running(value: bool) -> void:
	_running = value


func set_difficulty(food_interval_value: float, tree_chance_value: float) -> void:
	food_interval = maxf(0.1, food_interval_value)
	tree_chance = clampf(tree_chance_value, 0.0, 1.0)


func set_hide_regular_food(value: bool) -> void:
	_hide_regular_food = value


func reset() -> void:
	for child in get_children():
		child.queue_free()
	_food_timer = 0.25
	_tree_timer = OBSTACLE_CHECK_INTERVAL
	_bush_timer = OBSTACLE_CHECK_INTERVAL + 1.4
	_last_resource_spawn_x = -9999.0
	_last_obstacle_spawn_x = -9999.0
	_hide_regular_food = false
	_running = true


func height_layer_for(height_m: float) -> String:
	if height_m <= 30.0:
		return HEIGHT_LAYER_LOW
	if height_m <= 60.0:
		return HEIGHT_LAYER_MID
	return HEIGHT_LAYER_HIGH


func spawn_light_food(config: Dictionary) -> void:
	## 由 NightSystem 在黑夜期请求生成暖光/冷光食物。
	if not _running:
		return
	var local: Dictionary = config.duplicate()
	if not local.has("height_m"):
		local["height_m"] = float(local["min_height"])
	var height_m: float = float(local["height_m"])
	var spawn_x: float = _spawn_x_for_channel(_last_resource_spawn_x, 90.0)
	var food := HomewardCollectibleFood.new()
	food.name = "LightFood_%s" % String(local["id"])
	add_child(food)
	food.setup(Vector2(spawn_x, _screen_y_for_height(height_m)), local)
	_last_resource_spawn_x = food.position.x
	food.collected.connect(_on_food_collected)


func _spawn_food() -> void:
	var food_config: Dictionary = _random_food_config()
	var height_m: float = _rng.randf_range(float(food_config["min_height"]), float(food_config["max_height"]))
	food_config = food_config.duplicate()
	food_config["height_m"] = height_m
	var spawn_x: float = _spawn_x_for_channel(_last_resource_spawn_x, 90.0)

	var food := HomewardCollectibleFood.new()
	food.name = "Food_%s" % String(food_config["id"])
	add_child(food)
	food.setup(Vector2(spawn_x, _screen_y_for_height(height_m)), food_config)
	_last_resource_spawn_x = food.position.x
	food.collected.connect(_on_food_collected)


func _random_food_config() -> Dictionary:
	var roll: float = _rng.randf()
	if roll < 0.45:
		return _random_food_for_layer(HEIGHT_LAYER_LOW)
	if roll < 0.75:
		return _random_food_for_layer(HEIGHT_LAYER_MID)
	return _random_food_for_layer(HEIGHT_LAYER_HIGH)


func _random_food_for_layer(layer: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for config in FOOD_TYPES:
		if String(config["layer"]) == layer:
			candidates.append(config)

	if candidates.is_empty():
		return FOOD_TYPES[0]

	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _spawn_tree() -> void:
	var spawn_x: float = _spawn_x_for_channel(_last_obstacle_spawn_x, 180.0)
	var obstacle := HomewardObstacle.new()
	obstacle.name = "Tree"
	add_child(obstacle)

	var config: Dictionary = TREE_OBSTACLE_CONFIGS[_rng.randi_range(0, TREE_OBSTACLE_CONFIGS.size() - 1)]
	var texture: Texture2D = TREE_TEXTURES[int(config["texture_index"])]
	var visual_scale: float = _rng.randf_range(float(config["min_scale"]), float(config["max_scale"]))
	# 碰撞框对齐可见树体：宽度取树冠核心（约半宽），高度覆盖树干+树冠主体。
	var hitbox := Vector2(
		float(texture.get_width()) * visual_scale * 0.5,
		float(texture.get_height()) * visual_scale * 0.86
	)
	obstacle.setup(_ground_obstacle_position(spawn_x, visual_scale, texture), texture, visual_scale, float(config["loss"]), hitbox, "tree")

	_last_obstacle_spawn_x = obstacle.position.x
	obstacle.hit.connect(_on_obstacle_hit)


func _spawn_bush() -> void:
	var spawn_x: float = _spawn_x_for_channel(_last_obstacle_spawn_x, 180.0)
	var obstacle := HomewardObstacle.new()
	obstacle.name = "Bush"
	add_child(obstacle)

	var config: Dictionary = BUSH_OBSTACLE_CONFIGS[_rng.randi_range(0, BUSH_OBSTACLE_CONFIGS.size() - 1)]
	var texture: Texture2D = BUSH_TEXTURES[int(config["texture_index"])]
	obstacle.setup(_ground_obstacle_position(spawn_x, float(config["visual_scale"]), texture), texture, float(config["visual_scale"]), float(config["loss"]), config["hitbox"] as Vector2, "bush")

	_last_obstacle_spawn_x = obstacle.position.x
	obstacle.hit.connect(_on_obstacle_hit)


func _spawn_x_for_channel(last_spawn_x: float, base_extra_x: float) -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_x: float = viewport_size.x + base_extra_x
	if absf(spawn_x - last_spawn_x) < MIN_OBSTACLE_FOOD_GAP_PX:
		spawn_x = last_spawn_x + MIN_OBSTACLE_FOOD_GAP_PX
	if absf(spawn_x - _last_resource_spawn_x) < MIN_OBSTACLE_FOOD_GAP_PX:
		spawn_x = _last_resource_spawn_x + MIN_OBSTACLE_FOOD_GAP_PX
	if absf(spawn_x - _last_obstacle_spawn_x) < MIN_OBSTACLE_FOOD_GAP_PX:
		spawn_x = _last_obstacle_spawn_x + MIN_OBSTACLE_FOOD_GAP_PX
	return spawn_x


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

	var ground_y: float = viewport_size.y * 0.90
	var half_texture_height: float = float(texture.get_height()) * visual_scale * 0.5
	return Vector2(spawn_x, ground_y - half_texture_height)


func _on_food_collected(gain: float, food_id: String, world_pos: Vector2) -> void:
	food_collected.emit(gain, food_id, world_pos)


func _on_obstacle_hit(loss: float, obstacle_kind: String, world_pos: Vector2) -> void:
	obstacle_hit.emit(loss, obstacle_kind, world_pos)
