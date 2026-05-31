extends Node
class_name HomewardWeatherSystem

## 雨天 + 羽毛湿度系统。
## 自管状态机（晴 → 预警 → 毛毛雨 → 大雨 → 暴雨 → 放晴）与全屏覆盖层。
## main.gd 查询 get_wetness_multiplier() 用于饱食度公式。

signal weather_phase_changed(phase: String)

const PHASE_CLEAR: String = "clear"
const PHASE_WARNING: String = "warning"
const PHASE_DRIZZLE: String = "drizzle"
const PHASE_RAIN: String = "rain"
const PHASE_STORM: String = "storm"

const CHECK_INTERVAL: float = 8.0
const BASE_CHANCE: float = 0.12
const WARNING_LEAD: float = 2.0

const DRY_RATE: float = 3.0

const CLOUD_TEXTURE: Texture2D = preload("res://assets/art/environment/overlays/weather_grey_cloud_warning_overlay_001.png")
const DRIZZLE_TEXTURE: Texture2D = preload("res://assets/art/weather/weather_drizzle_lines_001.png")
const RAIN_TEXTURE: Texture2D = preload("res://assets/art/weather/weather_rain_lines_001.png")
const STORM_MIST_TEXTURE: Texture2D = preload("res://assets/art/weather/weather_storm_mist_001.png")
const DARKEN_TEXTURE: Texture2D = preload("res://assets/art/vfx/vfx_screen_darken_fade_001.png")

var wetness: float = 0.0

var _running: bool = false
var _phase: String = PHASE_CLEAR
var _check_timer: float = 0.0
var _warning_timer: float = 0.0
var _rain_elapsed: float = 0.0
var _rain_duration: float = 10.0
var _rng := RandomNumberGenerator.new()

var _canvas: CanvasLayer
var _cloud_rect: TextureRect
var _drizzle_rect: TextureRect
var _rain_rect: TextureRect
var _mist_rect: TextureRect
var _darken_rect: TextureRect


func _ready() -> void:
	_rng.randomize()
	_build_overlays()
	_apply_phase_visuals()


func _process(delta: float) -> void:
	if not _running:
		return

	match _phase:
		PHASE_CLEAR:
			_tick_clear(delta)
		PHASE_WARNING:
			_tick_warning(delta)
		PHASE_DRIZZLE, PHASE_RAIN, PHASE_STORM:
			_tick_raining(delta)

	if _phase == PHASE_CLEAR:
		wetness = maxf(0.0, wetness - DRY_RATE * delta)


func set_running(value: bool) -> void:
	_running = value


func reset() -> void:
	_running = true
	_phase = PHASE_CLEAR
	_check_timer = 0.0
	_warning_timer = 0.0
	_rain_elapsed = 0.0
	wetness = 0.0
	_apply_phase_visuals()


func set_rain_duration(value: float) -> void:
	_rain_duration = maxf(1.0, value)


func is_raining() -> bool:
	return _phase == PHASE_DRIZZLE or _phase == PHASE_RAIN or _phase == PHASE_STORM


func get_wetness_multiplier() -> float:
	if wetness <= 20.0:
		return 1.0
	if wetness <= 50.0:
		return 1.2
	if wetness <= 80.0:
		return 1.5
	return 2.0


func _tick_clear(delta: float) -> void:
	_check_timer += delta
	if _check_timer < CHECK_INTERVAL:
		return
	_check_timer = 0.0
	if _rng.randf() < BASE_CHANCE:
		_enter_phase(PHASE_WARNING)
		_warning_timer = 0.0


func _tick_warning(delta: float) -> void:
	_warning_timer += delta
	if _warning_timer >= WARNING_LEAD:
		_rain_elapsed = 0.0
		_enter_phase(PHASE_DRIZZLE)


func _tick_raining(delta: float) -> void:
	_rain_elapsed += delta

	var rate: float = 3.0
	var target_phase: String = PHASE_DRIZZLE
	if _rain_elapsed >= 9.0:
		rate = 10.0
		target_phase = PHASE_STORM
	elif _rain_elapsed >= 5.0:
		rate = 6.0
		target_phase = PHASE_RAIN

	wetness = minf(100.0, wetness + rate * delta)

	if target_phase != _phase:
		_enter_phase(target_phase)

	if _rain_elapsed >= _rain_duration:
		_enter_phase(PHASE_CLEAR)
		_check_timer = 0.0


func _enter_phase(phase: String) -> void:
	if phase == _phase:
		return
	_phase = phase
	_apply_phase_visuals()
	weather_phase_changed.emit(phase)


func _build_overlays() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "WeatherCanvas"
	_canvas.layer = 6
	add_child(_canvas)

	_cloud_rect = _make_full_rect(CLOUD_TEXTURE)
	_drizzle_rect = _make_full_rect(DRIZZLE_TEXTURE)
	_rain_rect = _make_full_rect(RAIN_TEXTURE)
	_mist_rect = _make_full_rect(STORM_MIST_TEXTURE)
	_darken_rect = _make_full_rect(DARKEN_TEXTURE)


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
	if _cloud_rect == null:
		return
	_cloud_rect.visible = _phase == PHASE_WARNING
	_drizzle_rect.visible = _phase == PHASE_DRIZZLE
	_rain_rect.visible = _phase == PHASE_RAIN or _phase == PHASE_STORM
	_mist_rect.visible = _phase == PHASE_STORM
	_darken_rect.visible = _phase == PHASE_STORM
