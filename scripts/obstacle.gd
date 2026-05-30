extends Area2D
class_name HomewardObstacle

signal hit(hunger_loss: float)

@export var hunger_loss: float = 5.0
@export var collision_size: Vector2 = Vector2(170.0, 120.0)

var scroll_speed: float = 150.0
var _has_hit: bool = false
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	monitorable = true
	_setup_collision()
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position.x -= scroll_speed * delta
	if _has_hit:
		modulate = modulate.lerp(Color(1.0, 1.0, 1.0, 0.55), 0.08)

	if position.x < -420.0:
		queue_free()


func setup(spawn_position: Vector2, texture: Texture2D, visual_scale: float, loss: float, hitbox_size: Vector2) -> void:
	position = spawn_position
	hunger_loss = loss
	collision_size = hitbox_size
	_setup_sprite(texture, visual_scale)
	_setup_collision()


func set_scroll_speed(value: float) -> void:
	scroll_speed = maxf(0.0, value)


func _setup_sprite(texture: Texture2D, visual_scale: float) -> void:
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite"
		add_child(_sprite)

	_sprite.texture = texture
	_sprite.scale = Vector2(visual_scale, visual_scale)


func _setup_collision() -> void:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)

	var rectangle := RectangleShape2D.new()
	rectangle.size = collision_size
	shape_node.shape = rectangle


func _on_area_entered(area: Area2D) -> void:
	if _has_hit or not area.is_in_group("player"):
		return

	_has_hit = true
	hit.emit(hunger_loss)
