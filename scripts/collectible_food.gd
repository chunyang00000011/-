extends Area2D
class_name HomewardCollectibleFood

signal collected(hunger_gain: float)

@export var hunger_gain: float = 8.0
@export var radius: float = 16.0
@export var color: Color = Color(1.0, 0.78, 0.22)

var scroll_speed: float = 150.0
var _collected: bool = false
var _age: float = 0.0


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
	queue_redraw()

	if position.x < -80.0:
		queue_free()


func setup(spawn_position: Vector2, gain: float, food_color: Color, food_radius: float = 16.0) -> void:
	position = spawn_position
	hunger_gain = gain
	color = food_color
	radius = food_radius
	_setup_collision()
	queue_redraw()


func set_scroll_speed(value: float) -> void:
	scroll_speed = maxf(0.0, value)


func _draw() -> void:
	var pulse: float = 1.0 + sin(_age * 6.0) * 0.12
	draw_circle(Vector2.ZERO, radius * 1.9 * pulse, Color(color.r, color.g, color.b, 0.16))
	draw_circle(Vector2.ZERO, radius * pulse, color)
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
	collected.emit(hunger_gain)
	queue_free()
