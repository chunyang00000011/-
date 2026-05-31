extends Area2D
class_name HomewardCollectibleFood

signal collected(hunger_gain: float, food_id: String, world_pos: Vector2)

@export var hunger_gain: float = 8.0
@export var radius: float = 16.0
@export var color: Color = Color(1.0, 0.78, 0.22)

var food_type: StringName
var height_m: float = 0.0
var scroll_speed: float = 150.0
var _collected: bool = false
var _age: float = 0.0
var _sprite: Sprite2D
var _glow: Sprite2D
var _glow_base_scale: float = 1.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	monitoring = true
	monitorable = true
	_setup_collision()
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position.x -= scroll_speed * delta
	_age += delta
	if _glow != null:
		var pulse: float = 0.75 + 0.25 * sin(_age * 5.0)
		_glow.modulate.a = pulse
		_glow.scale = Vector2.ONE * (0.9 + 0.12 * pulse) * _glow_base_scale

	if position.x < -120.0:
		queue_free()


func setup(spawn_position: Vector2, config: Dictionary) -> void:
	position = spawn_position
	food_type = StringName(config["id"])
	height_m = float(config["height_m"])
	hunger_gain = float(config["gain"])
	color = config["color"] as Color
	radius = float(config.get("radius", 16.0))
	_setup_visuals(config)
	_setup_collision()


func set_scroll_speed(value: float) -> void:
	scroll_speed = maxf(0.0, value)


func _setup_visuals(config: Dictionary) -> void:
	var glow_path: String = String(config.get("glow_texture_path", ""))
	if glow_path != "" and ResourceLoader.exists(glow_path):
		if _glow == null:
			_glow = Sprite2D.new()
			_glow.name = "Glow"
			_glow.z_index = -1
			add_child(_glow)
		var glow_tex: Texture2D = load(glow_path) as Texture2D
		_glow.texture = glow_tex
		_glow_base_scale = (radius * 4.0) / maxf(1.0, float(glow_tex.get_width()))
		_glow.scale = Vector2.ONE * _glow_base_scale
		_glow.modulate = Color(color.r, color.g, color.b, 0.8)

	var texture_path: String = String(config.get("texture_path", ""))
	if texture_path != "" and ResourceLoader.exists(texture_path):
		if _sprite == null:
			_sprite = Sprite2D.new()
			_sprite.name = "Sprite"
			add_child(_sprite)
		var tex: Texture2D = load(texture_path) as Texture2D
		_sprite.texture = tex
		var scale_value: float = float(config.get("visual_scale", 0.4))
		_sprite.scale = Vector2(scale_value, scale_value)
		set_meta("has_sprite", true)
	else:
		set_meta("has_sprite", false)


func _draw() -> void:
	# 无贴图时的兜底圆点。
	if bool(get_meta("has_sprite", false)):
		return
	draw_circle(Vector2.ZERO, radius * 1.9, Color(color.r, color.g, color.b, 0.16))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2(-radius * 0.28, -radius * 0.3), radius * 0.28, Color(1.0, 1.0, 1.0, 0.72))


func _setup_collision() -> void:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)

	var circle := CircleShape2D.new()
	circle.radius = radius
	shape_node.shape = circle


func _on_area_entered(area: Area2D) -> void:
	if _collected or not area.is_in_group("player"):
		return

	_collected = true
	collected.emit(hunger_gain, String(food_type), global_position)
	queue_free()
