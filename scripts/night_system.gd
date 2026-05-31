extends Node
class_name HomewardNightSystem

## 夜航系统：周期性事件（非随机）。
## 黄昏 → 黑夜 → 黎明三阶段，管理夜色覆盖层。
## 黑夜期请求生成暖光/冷光食物，并通知 Spawner 隐藏常规食物。

signal night_phase_changed(phase: String)
signal light_food_requested(food_config: Dictionary)

const PHASE_DAY: String = "day"
const PHASE_DUSK: String = "dusk"
const PHASE_NIGHT: String = "night"
const PHASE_DAWN: String = "dawn"

const FIRST_TRIGGER: float = 120.0
const PERIOD_MIN: float = 80.0
const DUSK_TIME: float = 5.0
const NIGHT_TIME: float = 7.0
const DAWN_TIME: float = 3.0
const TOTAL_TIME: float = DUSK_TIME + NIGHT_TIME + DAWN_TIME

const LIGHT_CHECK_INTERVAL: float = 3.0

const DUSK_TEXTURE: Texture2D = preload("res://assets/art/environment/overlays/overlay_dusk_tint_001.png")
const NIGHT_TEXTURE: Texture2D = preload("res://assets/art/environment/overlays/overlay_night_tint_001.png")
const STARS_TEXTURE: Texture2D = preload("res://assets/art/environment/overlays/overlay_stars_distant_lights_001.png")
const DAWN_TEXTURE: Texture2D = preload("res://assets/art/environment/overlays/overlay_dawn_transition_001.png")
const NIGHT_VISION_SHADER: Shader = preload("res://assets/shaders/night_vision.gdshader")

## 夜视光圈（柔和渐变）：圈内可见、圈外压暗，圆心跟随小鸟。
## 半径以校正 UV 为单位（1 单位 ≈ 720px）：黄昏大、黑夜小、黎明放大消失。
const NV_DUSK_OUTER: float = 0.72
const NV_DUSK_DARK: float = 0.35
const NV_NIGHT_OUTER: float = 0.42
const NV_NIGHT_DARK: float = 0.82
const NV_DAWN_OUTER: float = 1.3
const NV_LERP_SPEED: float = 6.0

const WARM_FOOD := {
	"id": "night_warm_light",
	"min_height": 70.0,
	"max_height": 90.0,
	"gain": 5.0,
	"texture_path": "res://assets/art/food/food_night_warm_light_insects_001.png",
	"color": Color(1.0, 0.82, 0.42),
	"radius": 17.0,
	"visual_scale": 0.4,
	"glow_texture_path": "res://assets/art/vfx/vfx_warm_light_glow_001.png",
}
const COLD_FOOD := {
	"id": "night_cold_light",
	"min_height": 10.0,
	"max_height": 30.0,
	"gain": -5.0,
	"texture_path": "res://assets/art/food/food_cold_false_light_001.png",
	"color": Color(0.66, 0.82, 1.0),
	"radius": 16.0,
	"visual_scale": 0.4,
	"glow_texture_path": "res://assets/art/vfx/vfx_cold_light_flicker_001.png",
}

var _running: bool = false
var _phase: String = PHASE_DAY
var _period: float = FIRST_TRIGGER
var _day_timer: float = 0.0
var _phase_timer: float = 0.0
var _light_timer: float = 0.0
var _first_done: bool = false
var _rng := RandomNumberGenerator.new()

var _canvas: CanvasLayer
var _dusk_rect: TextureRect
var _night_rect: TextureRect
var _stars_rect: TextureRect
var _dawn_rect: TextureRect
var _vision_rect: ColorRect
var _vision_mat: ShaderMaterial
var _player: Node2D
var _nv_outer: float = NV_DUSK_OUTER
var _nv_dark: float = 0.0
var _nv_outer_target: float = NV_DUSK_OUTER
var _nv_dark_target: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build_overlays()
	_apply_phase_visuals()


func _process(delta: float) -> void:
	_update_night_vision(delta)

	if not _running:
		return

	if _phase == PHASE_DAY:
		_day_timer += delta
		var trigger: float = FIRST_TRIGGER if not _first_done else _period
		if _day_timer >= trigger:
			_first_done = true
			_enter_phase(PHASE_DUSK)
		return

	_phase_timer += delta

	match _phase:
		PHASE_DUSK:
			if _phase_timer >= DUSK_TIME:
				_enter_phase(PHASE_NIGHT)
		PHASE_NIGHT:
			_tick_night_lights(delta)
			if _phase_timer >= NIGHT_TIME:
				_enter_phase(PHASE_DAWN)
		PHASE_DAWN:
			if _phase_timer >= DAWN_TIME:
				_enter_phase(PHASE_DAY)
				_day_timer = 0.0


func set_running(value: bool) -> void:
	_running = value


func set_player(player: Node2D) -> void:
	_player = player


func reset() -> void:
	_running = true
	_phase = PHASE_DAY
	_day_timer = 0.0
	_phase_timer = 0.0
	_light_timer = 0.0
	_first_done = false
	_nv_outer = NV_DUSK_OUTER
	_nv_dark = 0.0
	_nv_outer_target = NV_DUSK_OUTER
	_nv_dark_target = 0.0
	_apply_phase_visuals()


func set_period(value: float) -> void:
	_period = maxf(PERIOD_MIN, value)


func get_phase() -> String:
	return _phase


func is_night_hiding_food() -> bool:
	return _phase == PHASE_NIGHT


func is_night_event_active() -> bool:
	return _phase != PHASE_DAY


func get_night_countdown() -> float:
	## 距离下次夜航开始的剩余时间（仅白天有意义）。
	if _phase != PHASE_DAY:
		return 0.0
	var trigger: float = FIRST_TRIGGER if not _first_done else _period
	return maxf(0.0, trigger - _day_timer)


func _tick_night_lights(delta: float) -> void:
	_light_timer += delta
	if _light_timer < LIGHT_CHECK_INTERVAL:
		return
	_light_timer = 0.0

	if _rng.randf() < 0.65:
		_request_light(WARM_FOOD)
	if _rng.randf() < 0.35:
		_request_light(COLD_FOOD)


func _request_light(base_config: Dictionary) -> void:
	var config: Dictionary = base_config.duplicate()
	config["height_m"] = _rng.randf_range(float(config["min_height"]), float(config["max_height"]))
	light_food_requested.emit(config)


func _enter_phase(phase: String) -> void:
	if phase == _phase:
		return
	_phase = phase
	_phase_timer = 0.0
	if phase == PHASE_NIGHT:
		_light_timer = LIGHT_CHECK_INTERVAL
	_apply_phase_visuals()
	night_phase_changed.emit(phase)


func _build_overlays() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "NightCanvas"
	_canvas.layer = 7
	add_child(_canvas)

	_dusk_rect = _make_full_rect(DUSK_TEXTURE)
	_night_rect = _make_full_rect(NIGHT_TEXTURE)
	_stars_rect = _make_full_rect(STARS_TEXTURE)
	_dawn_rect = _make_full_rect(DAWN_TEXTURE)
	_build_vision_rect()


func _build_vision_rect() -> void:
	_vision_mat = ShaderMaterial.new()
	_vision_mat.shader = NIGHT_VISION_SHADER
	_vision_mat.set_shader_parameter("inner_radius", 0.16)
	_vision_mat.set_shader_parameter("outer_radius", NV_DUSK_OUTER)
	_vision_mat.set_shader_parameter("darkness", 0.0)
	_vision_mat.set_shader_parameter("light_center", Vector2(0.43, 0.5))

	_vision_rect = ColorRect.new()
	_vision_rect.name = "NightVision"
	_vision_rect.color = Color(0, 0, 0, 1)
	_vision_rect.material = _vision_mat
	_vision_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vision_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vision_rect.visible = false
	_canvas.add_child(_vision_rect)


func _make_full_rect(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	_canvas.add_child(rect)
	return rect


func _apply_phase_visuals() -> void:
	if _dusk_rect == null:
		return
	_dusk_rect.visible = _phase == PHASE_DUSK
	_night_rect.visible = _phase == PHASE_NIGHT
	_stars_rect.visible = _phase == PHASE_NIGHT
	_dawn_rect.visible = _phase == PHASE_DAWN

	match _phase:
		PHASE_DUSK:
			_nv_outer_target = NV_DUSK_OUTER
			_nv_dark_target = NV_DUSK_DARK
		PHASE_NIGHT:
			_nv_outer_target = NV_NIGHT_OUTER
			_nv_dark_target = NV_NIGHT_DARK
		PHASE_DAWN:
			# 黎明：光圈放大、压暗渐隐到 0。
			_nv_outer_target = NV_DAWN_OUTER
			_nv_dark_target = 0.0
		_:
			_nv_outer_target = NV_DUSK_OUTER
			_nv_dark_target = 0.0


func _update_night_vision(delta: float) -> void:
	if _vision_mat == null:
		return

	var active: bool = _phase != PHASE_DAY
	_vision_rect.visible = active or _nv_dark > 0.01
	if not _vision_rect.visible:
		return

	var t: float = clampf(delta * NV_LERP_SPEED, 0.0, 1.0)
	_nv_outer = lerpf(_nv_outer, _nv_outer_target, t)
	_nv_dark = lerpf(_nv_dark, _nv_dark_target, t)

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)
	_vision_mat.set_shader_parameter("aspect", viewport_size.x / viewport_size.y)

	if _player != null:
		var uv := Vector2(
			clampf(_player.global_position.x / viewport_size.x, 0.0, 1.0),
			clampf(_player.global_position.y / viewport_size.y, 0.0, 1.0)
		)
		_vision_mat.set_shader_parameter("light_center", uv)

	_vision_mat.set_shader_parameter("outer_radius", _nv_outer)
	_vision_mat.set_shader_parameter("inner_radius", maxf(0.05, _nv_outer * 0.38))
	_vision_mat.set_shader_parameter("darkness", _nv_dark)
