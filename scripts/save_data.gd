extends Node

## 存档管理器（autoload）：历史最佳距离 + 终身累计统计 + 已解锁成就。

const SAVE_PATH: String = "user://homeward_save.cfg"
const SECTION_PROGRESS: String = "progress"
const SECTION_STATS: String = "stats"
const SECTION_ACHIEVEMENTS: String = "achievements"
const KEY_BEST_DISTANCE: String = "best_distance"
const KEY_UNLOCKED: String = "unlocked"

const STAT_KEYS: Array[String] = [
	"runs",
	"food_total",
	"insects",
	"predators_dodged",
	"near_miss",
	"nights_survived",
	"rain_seconds",
]

var _best_distance: float = 0.0
var _stats: Dictionary = {}
var _unlocked: Dictionary = {}


func _ready() -> void:
	_load()


func get_best_distance() -> float:
	return _best_distance


func update_best_distance(distance_m: float) -> bool:
	## 若刷新记录则保存并返回 true。
	if distance_m <= _best_distance:
		return false
	_best_distance = distance_m
	_save()
	return true


func add_stat(key: String, amount: float = 1.0) -> void:
	## 累加终身统计。不立即落盘，由 flush() 批量保存。
	_stats[key] = float(_stats.get(key, 0.0)) + amount


func get_stat(key: String) -> float:
	return float(_stats.get(key, 0.0))


func flush() -> void:
	## 批量落盘（每局结束调用一次，避免每帧写盘）。
	_save()


func is_unlocked(id: String) -> bool:
	return _unlocked.has(id)


func unlock(id: String) -> bool:
	## 首次解锁返回 true 并即时落盘；已解锁返回 false。
	if _unlocked.has(id):
		return false
	_unlocked[id] = true
	_save()
	return true


func get_unlocked() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for id in _unlocked.keys():
		out.append(String(id))
	return out


func _load() -> void:
	for key in STAT_KEYS:
		_stats[key] = 0.0
	_unlocked.clear()

	var config := ConfigFile.new()
	var err: int = config.load(SAVE_PATH)
	if err != OK:
		_best_distance = 0.0
		return

	_best_distance = float(config.get_value(SECTION_PROGRESS, KEY_BEST_DISTANCE, 0.0))
	for key in STAT_KEYS:
		_stats[key] = float(config.get_value(SECTION_STATS, key, 0.0))
	var unlocked_list: PackedStringArray = config.get_value(SECTION_ACHIEVEMENTS, KEY_UNLOCKED, PackedStringArray())
	for id in unlocked_list:
		_unlocked[String(id)] = true


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION_PROGRESS, KEY_BEST_DISTANCE, _best_distance)
	for key in STAT_KEYS:
		config.set_value(SECTION_STATS, key, float(_stats.get(key, 0.0)))
	config.set_value(SECTION_ACHIEVEMENTS, KEY_UNLOCKED, get_unlocked())
	config.save(SAVE_PATH)
