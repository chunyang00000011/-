extends Node2D
class_name HomewardPredatorSystem

## 天敌管理器：按高度调制概率生成天敌，转发命中/警告信号。
## 前 30s 禁用。生成的天敌走自己的四阶段状态机。

signal predator_hit(hunger_loss: float)
signal predator_warning(active: bool)
signal predator_dodged
signal predator_near_miss

const SAFE_START_TIME: float = 15.0
const CHECK_INTERVAL: float = 1.6

var _running: bool = false
var _check_timer: float = 0.0
var _elapsed: float = 0.0
var _base_chance: float = 0.0
var _player: Node2D
var _active_warnings: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if not _running:
		return

	_elapsed += delta
	if _elapsed < SAFE_START_TIME:
		return

	_check_timer += delta
	if _check_timer < CHECK_INTERVAL:
		return
	_check_timer = 0.0

	var chance: float = _base_chance * _height_multiplier()
	if _rng.randf() < chance:
		_spawn_predator()


func set_running(value: bool) -> void:
	_running = value


func set_player(player: Node2D) -> void:
	_player = player


func set_base_chance(value: float) -> void:
	_base_chance = clampf(value, 0.0, 1.0)


func reset() -> void:
	for child in get_children():
		child.queue_free()
	_running = true
	_check_timer = 0.0
	_elapsed = 0.0
	_active_warnings = 0
	predator_warning.emit(false)


func _height_multiplier() -> float:
	if _player == null:
		return 1.0
	var h: float = _player.height_m
	if h < 30.0:
		return 0.5
	if h <= 60.0:
		return 1.0
	return 1.5


func _spawn_predator() -> void:
	var predator := HomewardPredator.new()
	predator.name = "Predator"
	add_child(predator)
	predator.setup(_player, _rng.randf() < 0.4)
	predator.hit.connect(_on_predator_hit)
	predator.warning_changed.connect(_on_predator_warning_changed)
	predator.dodged.connect(_on_predator_dodged)
	predator.near_miss.connect(_on_predator_near_miss)


func scare_predators(from_pos: Vector2, radius: float) -> void:
	## 振翅惊吓：打断范围内处于蓄力阶段的天敌。
	for child in get_children():
		if child is HomewardPredator:
			var p := child as HomewardPredator
			if p.global_position.distance_to(from_pos) <= radius:
				p.abort_attack()


func _on_predator_dodged() -> void:
	predator_dodged.emit()


func _on_predator_near_miss() -> void:
	predator_near_miss.emit()


func _on_predator_hit(loss: float) -> void:
	predator_hit.emit(loss)


func _on_predator_warning_changed(active: bool) -> void:
	if active:
		_active_warnings += 1
	else:
		_active_warnings = maxi(0, _active_warnings - 1)
	predator_warning.emit(_active_warnings > 0)
