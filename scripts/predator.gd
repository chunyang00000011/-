extends Area2D
class_name HomewardPredator

## 单只天敌：出现 → 蓄力 → 冲刺 → 判定 四阶段状态机。
## 蓄力分两段：前 40% 轨迹跟随小鸟；后 60% 冻结方向与轨迹，给出可躲的固定红线。

signal hit(hunger_loss: float)
signal warning_changed(active: bool)
signal dodged
signal near_miss

const PHASE_APPEAR: String = "appear"
const PHASE_AIM: String = "aim"
const PHASE_DASH: String = "dash"
const PHASE_DONE: String = "done"
const PHASE_FLEE: String = "flee"

const APPEAR_TIME: float = 1.0
const AIM_TIME: float = 0.6
const AIM_LOCK_RATIO: float = 0.4
const DASH_TIME: float = 0.5
const HIT_LOSS: float = 12.0
const DASH_SPEED: float = 1700.0
const HITBOX_RADIUS: float = 38.0
const NEAR_MISS_RADIUS: float = 88.0

const HOVER_TEXTURE: Texture2D = preload("res://assets/art/characters/predators/predator_hawk_hover_001.png")
const AIM_TEXTURE: Texture2D = preload("res://assets/art/characters/predators/predator_hawk_aim_001.png")
const DASH_TEXTURE: Texture2D = preload("res://assets/art/characters/predators/predator_hawk_dash_001.png")
const TRAJECTORY_TEXTURE: Texture2D = preload("res://assets/art/characters/predators/predator_attack_trajectory_001.png")

const TRAJECTORY_AIM_COLOR := Color(1.0, 0.25, 0.2, 0.5)
const TRAJECTORY_LOCKED_COLOR := Color(1.0, 0.32, 0.22, 0.92)

var _phase: String = PHASE_APPEAR
var _timer: float = 0.0
var _player: Node2D
var _appear_from: Vector2 = Vector2.ZERO
var _hover_target: Vector2 = Vector2.ZERO
var _dash_dir: Vector2 = Vector2.LEFT
var _has_hit: bool = false
var _warned: bool = false
var _locked: bool = false
var _min_dash_dist: float = 1e9

var _sprite: Sprite2D
var _trajectory: Sprite2D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = false
	_build_visuals()
	_build_collision()
	area_entered.connect(_on_area_entered)


func setup(player: Node2D, from_top: bool) -> void:
	_player = player
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)

	var bird_pos: Vector2 = _player.position if _player != null else Vector2(viewport_size.x * 0.43, viewport_size.y * 0.5)
	_hover_target = bird_pos + Vector2(260.0, -110.0)

	if from_top:
		_appear_from = Vector2(bird_pos.x + 320.0, -160.0)
	else:
		_appear_from = Vector2(viewport_size.x + 220.0, bird_pos.y - 80.0)

	position = _appear_from


func _process(delta: float) -> void:
	_timer += delta

	match _phase:
		PHASE_APPEAR:
			_tick_appear()
		PHASE_AIM:
			_tick_aim()
		PHASE_DASH:
			_tick_dash(delta)
		PHASE_DONE:
			_tick_done(delta)
		PHASE_FLEE:
			_tick_flee(delta)


func _tick_appear() -> void:
	var t: float = clampf(_timer / APPEAR_TIME, 0.0, 1.0)
	position = _appear_from.lerp(_hover_target, ease(t, -1.8))
	if _timer >= APPEAR_TIME:
		_set_phase(PHASE_AIM)


func _tick_aim() -> void:
	if not _warned:
		_warned = true
		warning_changed.emit(true)

	if not _locked:
		# 前 40%：轨迹实时跟随小鸟。
		var target: Vector2 = _player.position if _player != null else position + Vector2(-400.0, 0.0)
		_point_trajectory_at(target)
		if _timer >= AIM_TIME * AIM_LOCK_RATIO:
			# 锁定方向并冻结轨迹：此后给出固定可躲的红线。
			_dash_dir = (target - position).normalized()
			if _dash_dir == Vector2.ZERO:
				_dash_dir = Vector2.LEFT
			_locked = true
			_trajectory.modulate = TRAJECTORY_LOCKED_COLOR
			_trajectory.scale.y = 1.4

	if _timer >= AIM_TIME:
		_set_phase(PHASE_DASH)


func _tick_dash(delta: float) -> void:
	position += _dash_dir * DASH_SPEED * delta
	if _player != null:
		_min_dash_dist = minf(_min_dash_dist, position.distance_to(_player.position))
	if _timer >= DASH_TIME:
		_set_phase(PHASE_DONE)


func _tick_done(delta: float) -> void:
	# 冲刺结束后沿原方向飞出画面。
	position += _dash_dir * DASH_SPEED * 0.5 * delta
	if position.x < -360.0 or position.y < -360.0 or position.y > get_viewport_rect().size.y + 360.0:
		queue_free()


func _tick_flee(delta: float) -> void:
	# 被振翅惊吓：向右上方逃离画面。
	position += Vector2(1.0, -1.2).normalized() * DASH_SPEED * 0.6 * delta
	if position.x > get_viewport_rect().size.x + 360.0 or position.y < -360.0:
		queue_free()


func abort_attack() -> void:
	## 振翅惊吓：仅对蓄力阶段有效，中止攻击并逃离。冲刺已锁死，无法打断。
	if _phase != PHASE_AIM:
		return
	if _warned:
		_warned = false
		warning_changed.emit(false)
	_set_phase(PHASE_FLEE)


func _set_phase(phase: String) -> void:
	# 离开冲刺/判定阶段时结算躲避与擦身。
	if phase == PHASE_DONE and _phase == PHASE_DASH and not _has_hit:
		dodged.emit()
		if _min_dash_dist <= NEAR_MISS_RADIUS:
			near_miss.emit()

	_phase = phase
	_timer = 0.0
	_apply_phase_visuals()
	if phase == PHASE_DASH and _warned:
		_warned = false
		warning_changed.emit(false)


func _apply_phase_visuals() -> void:
	if _sprite == null:
		return
	match _phase:
		PHASE_APPEAR:
			_sprite.texture = HOVER_TEXTURE
			_trajectory.visible = false
		PHASE_AIM:
			_sprite.texture = AIM_TEXTURE
			_trajectory.visible = true
			_trajectory.modulate = TRAJECTORY_AIM_COLOR
			_trajectory.scale.y = 1.0
		PHASE_DASH, PHASE_DONE:
			_sprite.texture = DASH_TEXTURE
			_trajectory.visible = false
		PHASE_FLEE:
			_sprite.texture = DASH_TEXTURE
			_trajectory.visible = false


func _point_trajectory_at(target: Vector2) -> void:
	var to_target: Vector2 = target - position
	_trajectory.rotation = to_target.angle()
	var dist: float = to_target.length()
	var tex_w: float = float(TRAJECTORY_TEXTURE.get_width())
	if tex_w > 0.0:
		_trajectory.scale.x = clampf(dist / tex_w, 0.2, 2.5)


func _build_visuals() -> void:
	_trajectory = Sprite2D.new()
	_trajectory.name = "Trajectory"
	_trajectory.texture = TRAJECTORY_TEXTURE
	_trajectory.centered = true
	_trajectory.offset = Vector2(float(TRAJECTORY_TEXTURE.get_width()) * 0.5, 0.0)
	_trajectory.modulate = TRAJECTORY_AIM_COLOR
	_trajectory.z_index = -1
	_trajectory.visible = false
	add_child(_trajectory)

	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = HOVER_TEXTURE
	_sprite.scale = Vector2(0.6, 0.6)
	add_child(_sprite)


func _build_collision() -> void:
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = HITBOX_RADIUS
	shape_node.shape = circle
	add_child(shape_node)


func _on_area_entered(area: Area2D) -> void:
	if _has_hit or _phase != PHASE_DASH:
		return
	if not area.is_in_group("player"):
		return
	_has_hit = true
	hit.emit(HIT_LOSS)
