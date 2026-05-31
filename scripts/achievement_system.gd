extends Node
class_name HomewardAchievementSystem

## 成就系统：终身累计 + 事件触发型成就。
## 计数型读 SaveData 累计值判定；事件型由 main 在事件发生时 notify_event 触发。
## 解锁后通过 achievement_unlocked 信号通知 HUD 弹 toast。

signal achievement_unlocked(id: String, title: String, description: String)

## 成就定义。kind="count" 读 SaveData.get_stat(stat) >= threshold；
## kind="best" 读 SaveData.get_best_distance() >= threshold；
## kind="event" 由 notify_event(event) 触发。
const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "yi_niao", "title": "我是益鸟", "desc": "累计吃掉 10 只虫子。生态卫士，名副其实。", "kind": "count", "stat": "insects", "threshold": 10.0},
	{"id": "cheng_le", "title": "有点撑了", "desc": "累计进食 20 次。打个饱嗝，继续赶路。", "kind": "count", "stat": "food_total", "threshold": 20.0},
	{"id": "biao_fei", "title": "膘肥体壮", "desc": "饱食度首次喂到 100。圆滚滚也能飞。", "kind": "event", "event": "hunger_full"},
	{"id": "bu_shang_dang", "title": "我不上当", "desc": "整夜没碰冷光假食，安全撑到黎明。", "kind": "event", "event": "clean_night"},
	{"id": "min_jie", "title": "身手敏捷", "desc": "累计躲过 20 次天敌冲刺。猛禽都摇头。", "kind": "count", "stat": "predators_dodged", "threshold": 20.0},
	{"id": "xian_xiang", "title": "险象环生", "desc": "累计擦身而过 10 次。心脏够强。", "kind": "count", "stat": "near_miss", "threshold": 10.0},
	{"id": "luo_tang", "title": "落汤鸟", "desc": "累计在雨中飞行 60 秒。湿身但坚强。", "kind": "count", "stat": "rain_seconds", "threshold": 60.0},
	{"id": "ye_xing", "title": "夜行者", "desc": "累计经历 5 次夜航并撑到天亮。", "kind": "count", "stat": "nights_survived", "threshold": 5.0},
	{"id": "wan_li", "title": "万里归途", "desc": "历史最佳飞行距离突破 5000 米。", "kind": "best", "threshold": 5000.0},
	{"id": "chang_lai", "title": "常来常往", "desc": "累计游玩 20 局。这就是热爱。", "kind": "count", "stat": "runs", "threshold": 20.0},
]


func _save() -> Node:
	return get_node_or_null("/root/SaveData")


func get_definitions() -> Array[Dictionary]:
	return ACHIEVEMENTS


func check_unlocks() -> void:
	## 遍历计数/最佳型成就，满足且未解锁则解锁。
	var save: Node = _save()
	if save == null:
		return
	for a in ACHIEVEMENTS:
		var id: String = String(a["id"])
		if save.is_unlocked(id):
			continue
		var kind: String = String(a["kind"])
		var reached: bool = false
		if kind == "count":
			reached = save.get_stat(String(a["stat"])) >= float(a["threshold"])
		elif kind == "best":
			reached = save.get_best_distance() >= float(a["threshold"])
		if reached:
			_do_unlock(a)


func notify_event(event: String) -> void:
	## 事件触发型成就入口。
	var save: Node = _save()
	if save == null:
		return
	for a in ACHIEVEMENTS:
		if String(a["kind"]) != "event":
			continue
		if String(a.get("event", "")) != event:
			continue
		if save.is_unlocked(String(a["id"])):
			continue
		_do_unlock(a)


func _do_unlock(a: Dictionary) -> void:
	var save: Node = _save()
	if save == null:
		return
	if save.unlock(String(a["id"])):
		achievement_unlocked.emit(String(a["id"]), String(a["title"]), String(a["desc"]))
