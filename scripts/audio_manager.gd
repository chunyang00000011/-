extends Node

## 全局音频管理器（autoload）。
## 运行时创建 Music / SFX 总线，播放 BGM，按 key 播放事件音效（带随机变体 + 微调音高），
## 并管理风声 / 雨声等循环氛围层（按天气阶段交叉淡入淡出）。

const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"

const BGM_PATH: String = "res://assets/audio/music/homeward_birds_wind_ambient.ogg"

## 每个事件 key 对应一组可选音频，播放时随机取一条并微调音高，避免重复疲劳。
const SFX_VARIANTS := {
	# 运行状态
	"run_start": ["res://assets/audio/sfx/gameplay/state/run_start_01.wav"],
	"game_over": ["res://assets/audio/sfx/gameplay/state/game_over_soft_01.wav"],
	"falling": ["res://assets/audio/sfx/gameplay/state/falling_warning_01.wav"],
	"recover": ["res://assets/audio/sfx/gameplay/state/recover_food_ground_01.wav"],

	# 食物拾取
	"food_ground_insect": [
		"res://assets/audio/sfx/gameplay/food/ground_insect_pickup_01.wav",
		"res://assets/audio/sfx/gameplay/food/ground_insect_pickup_02.wav",
	],
	"food_seed_cluster": [
		"res://assets/audio/sfx/gameplay/food/seed_pickup_01.wav",
		"res://assets/audio/sfx/gameplay/food/seed_pickup_02.wav",
	],
	"food_bush_berries": [
		"res://assets/audio/sfx/gameplay/food/bush_berry_pickup_01.wav",
		"res://assets/audio/sfx/gameplay/food/bush_berry_pickup_02.wav",
	],
	"food_canopy_larva": [
		"res://assets/audio/sfx/gameplay/food/canopy_larva_pickup_01.wav",
		"res://assets/audio/sfx/gameplay/food/canopy_larva_pickup_02.wav",
	],
	"food_canopy_fruit": [
		"res://assets/audio/sfx/gameplay/food/canopy_fruit_pickup_01.wav",
		"res://assets/audio/sfx/gameplay/food/canopy_fruit_pickup_02.wav",
	],
	"food_night_warm_light": [
		"res://assets/audio/sfx/gameplay/food/night_warm_light_pickup_01.wav",
		"res://assets/audio/sfx/gameplay/food/night_warm_light_pickup_02.wav",
	],
	"food_night_cold_light": [
		"res://assets/audio/sfx/gameplay/food/cold_false_light_penalty_01.wav",
		"res://assets/audio/sfx/gameplay/food/cold_false_light_penalty_02.wav",
	],
	"food_generic": ["res://assets/audio/sfx/gameplay/food/ground_insect_pickup_01.wav"],

	# 障碍物
	"tree_hit": [
		"res://assets/audio/sfx/gameplay/obstacle/tree_hit_soft_01.wav",
		"res://assets/audio/sfx/gameplay/obstacle/tree_hit_soft_02.wav",
		"res://assets/audio/sfx/gameplay/obstacle/tree_hit_soft_03.wav",
	],
	"bush_hit": [
		"res://assets/audio/sfx/gameplay/obstacle/dense_bush_hit_01.wav",
		"res://assets/audio/sfx/gameplay/obstacle/dense_bush_hit_02.wav",
	],
	"bush_pass": [
		"res://assets/audio/sfx/gameplay/obstacle/sparse_bush_pass_01.wav",
		"res://assets/audio/sfx/gameplay/obstacle/sparse_bush_pass_02.wav",
	],

	# 玩家飞行
	"wing_flap": [
		"res://assets/audio/sfx/gameplay/player/wing_flap_soft_01.wav",
		"res://assets/audio/sfx/gameplay/player/wing_flap_soft_02.wav",
		"res://assets/audio/sfx/gameplay/player/wing_flap_soft_03.wav",
		"res://assets/audio/sfx/gameplay/player/wing_flap_soft_04.wav",
	],
	"wing_climb": ["res://assets/audio/sfx/gameplay/player/wing_climb_effort_01.wav"],
	"wing_descend": ["res://assets/audio/sfx/gameplay/player/wing_descend_glide_01.wav"],
	"accelerate": [
		"res://assets/audio/sfx/gameplay/player/accelerate_air_push_01.wav",
		"res://assets/audio/sfx/gameplay/player/accelerate_air_push_02.wav",
	],
	"feather_loss": [
		"res://assets/audio/sfx/gameplay/player/feather_loss_soft_01.wav",
		"res://assets/audio/sfx/gameplay/player/feather_loss_soft_02.wav",
	],

	# 天敌
	"predator_warning": [
		"res://assets/audio/sfx/gameplay/predator/warning_far_01.wav",
		"res://assets/audio/sfx/gameplay/predator/warning_far_02.wav",
	],
	"predator_aim": [
		"res://assets/audio/sfx/gameplay/predator/aim_lock_01.wav",
		"res://assets/audio/sfx/gameplay/predator/aim_lock_02.wav",
	],
	"predator_dash": [
		"res://assets/audio/sfx/gameplay/predator/dash_fast_01.wav",
		"res://assets/audio/sfx/gameplay/predator/dash_fast_02.wav",
	],
	"predator_near_miss": ["res://assets/audio/sfx/gameplay/predator/near_miss_01.wav"],
	"predator_hit": ["res://assets/audio/sfx/gameplay/predator/hit_bird_01.wav"],

	# 天气
	"rain_warning": ["res://assets/audio/sfx/gameplay/weather/rain_warning_cloud_01.wav"],
	"droplet": [
		"res://assets/audio/sfx/gameplay/weather/droplet_on_feather_01.wav",
		"res://assets/audio/sfx/gameplay/weather/droplet_on_feather_02.wav",
		"res://assets/audio/sfx/gameplay/weather/droplet_on_feather_03.wav",
	],

	# 夜航
	"night_dusk": ["res://assets/audio/sfx/gameplay/night/dusk_fade_in_01.wav"],
	"night_arrive": ["res://assets/audio/sfx/gameplay/night/night_arrive_01.wav"],
	"night_dawn": ["res://assets/audio/sfx/gameplay/night/dawn_return_01.wav"],
	"warm_light_spawn": ["res://assets/audio/sfx/gameplay/night/warm_guiding_light_spawn_01.wav"],
	"cold_light_spawn": ["res://assets/audio/sfx/gameplay/night/cold_light_flicker_01.wav"],

	# UI / 反馈
	"menu_confirm": ["res://assets/audio/sfx/gameplay/ui/menu_confirm_01.wav"],
	"menu_hover": [
		"res://assets/audio/sfx/gameplay/ui/menu_hover_01.wav",
		"res://assets/audio/sfx/gameplay/ui/menu_hover_02.wav",
		"res://assets/audio/sfx/gameplay/ui/menu_hover_03.wav",
	],
	"pause_open": ["res://assets/audio/sfx/gameplay/ui/pause_open_01.wav"],
	"pause_close": ["res://assets/audio/sfx/gameplay/ui/pause_close_01.wav"],
	"height_band": ["res://assets/audio/sfx/gameplay/ui/height_band_change_01.wav"],
	"best_distance": ["res://assets/audio/sfx/gameplay/ui/best_distance_mark_01.wav"],
	"warning_arrow": ["res://assets/audio/sfx/gameplay/ui/warning_arrow_01.wav"],
}

## 循环氛围层：风声常驻，雨声三档随天气阶段切换。
const LOOP_PATHS := {
	"wind": "res://assets/audio/sfx/ambient/wind_whoosh_loop.ogg",
	"rain_drizzle": "res://assets/audio/sfx/gameplay/weather/drizzle_loop_soft_01.wav",
	"rain_medium": "res://assets/audio/sfx/gameplay/weather/rain_medium_loop_01.wav",
	"rain_storm": "res://assets/audio/sfx/gameplay/weather/storm_mist_loop_01.wav",
}

const SFX_VOICES: int = 10

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _loop_players := {}
var _loop_active := {}
var _loop_tweens := {}
var _stream_cache := {}
var _music_volume: float = 0.8
var _sfx_volume: float = 0.9
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_setup_buses()
	_setup_players()
	_setup_loop_players()
	set_music_volume(_music_volume)
	set_sfx_volume(_sfx_volume)


func play_music() -> void:
	if _music_player == null:
		return
	var stream: AudioStream = _get_stream(BGM_PATH)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music_player.stream = stream
	if not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()


func play_sfx(key: String) -> void:
	var path: String = _pick_variant(key)
	if path == "":
		return
	var stream: AudioStream = _get_stream(path)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.pitch_scale = _rng.randf_range(0.95, 1.05)
	player.play()


func play_food_sfx(food_id: String) -> void:
	var key: String = "food_%s" % food_id
	if SFX_VARIANTS.has(key):
		play_sfx(key)
	else:
		play_sfx("food_generic")


func set_wind_active(active: bool) -> void:
	if active:
		start_loop("wind", 0.32, 1.6)
	else:
		stop_loop("wind", 1.2)


func set_weather_phase(phase: String) -> void:
	## 根据天气阶段交叉淡入对应雨声层，其余淡出。
	match phase:
		"drizzle":
			start_loop("rain_drizzle", 0.5, 1.2)
			stop_loop("rain_medium", 1.2)
			stop_loop("rain_storm", 1.2)
		"rain":
			start_loop("rain_medium", 0.62, 1.0)
			stop_loop("rain_drizzle", 1.0)
			stop_loop("rain_storm", 1.0)
		"storm":
			start_loop("rain_storm", 0.72, 1.0)
			stop_loop("rain_drizzle", 1.0)
			stop_loop("rain_medium", 1.5)
		_:
			# clear / warning：雨停。
			stop_loop("rain_drizzle", 1.4)
			stop_loop("rain_medium", 1.4)
			stop_loop("rain_storm", 1.4)


func start_loop(key: String, target_linear: float = 0.5, fade: float = 1.0) -> void:
	var player: AudioStreamPlayer = _loop_players.get(key)
	if player == null:
		return
	_loop_active[key] = true
	if not player.playing:
		player.volume_db = -80.0
		player.play()
	_fade_loop(key, target_linear, fade, false)


func stop_loop(key: String, fade: float = 1.0) -> void:
	var player: AudioStreamPlayer = _loop_players.get(key)
	if player == null or not bool(_loop_active.get(key, false)):
		return
	_loop_active[key] = false
	_fade_loop(key, 0.0, fade, true)


func stop_all_loops(fade: float = 0.8) -> void:
	for key in _loop_players.keys():
		stop_loop(key, fade)


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(MUSIC_BUS, _music_volume)


func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(SFX_BUS, _sfx_volume)


func _pick_variant(key: String) -> String:
	var variants: Array = SFX_VARIANTS.get(key, [])
	if variants.is_empty():
		return ""
	if variants.size() == 1:
		return String(variants[0])
	return String(variants[_rng.randi_range(0, variants.size() - 1)])


func _fade_loop(key: String, target_linear: float, fade: float, stop_after: bool) -> void:
	var player: AudioStreamPlayer = _loop_players.get(key)
	if player == null:
		return
	var existing: Tween = _loop_tweens.get(key)
	if existing != null and existing.is_valid():
		existing.kill()
	var target_db: float = linear_to_db(maxf(0.0001, target_linear))
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, maxf(0.01, fade))
	if stop_after:
		tween.tween_callback(player.stop)
	_loop_tweens[key] = tween


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear <= 0.001:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


func _setup_buses() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS) < 0:
		AudioServer.add_bus()
		var idx: int = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, MUSIC_BUS)
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index(SFX_BUS) < 0:
		AudioServer.add_bus()
		var idx: int = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, SFX_BUS)
		AudioServer.set_bus_send(idx, "Master")


func _setup_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

	for i in range(SFX_VOICES):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)


func _setup_loop_players() -> void:
	for key in LOOP_PATHS:
		var player := AudioStreamPlayer.new()
		player.name = "Loop_%s" % key
		player.bus = SFX_BUS
		player.volume_db = -80.0
		var stream: AudioStream = _get_stream(String(LOOP_PATHS[key]))
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		player.stream = stream
		# 兜底循环：部分 wav 未在导入设置里开启 loop，靠 finished 信号重播。
		player.finished.connect(_on_loop_finished.bind(key))
		add_child(player)
		_loop_players[key] = player
		_loop_active[key] = false


func _on_loop_finished(key: String) -> void:
	var player: AudioStreamPlayer = _loop_players.get(key)
	if player != null and bool(_loop_active.get(key, false)):
		player.play()


func _get_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	_stream_cache[path] = stream
	return stream
