extends CanvasLayer
class_name HomewardHUD

const HUNGER_METER_TEX: Texture2D = preload("res://assets/art/ui/hud/ui_hunger_meter_001.png")
const HEIGHT_METER_TEX: Texture2D = preload("res://assets/art/ui/hud/ui_height_meter_001.png")
const WETNESS_METER_TEX: Texture2D = preload("res://assets/art/ui/hud/ui_wetness_meter_001.png")
const DISTANCE_SIGN_TEX: Texture2D = preload("res://assets/art/ui/hud/ui_distance_sign_001.png")
const NIGHT_TIMER_TEX: Texture2D = preload("res://assets/art/ui/hud/ui_night_timer_001.png")
const WARNING_ARROW_TEX: Texture2D = preload("res://assets/art/ui/hud/ui_warning_arrow_001.png")
const PANEL_TEX: Texture2D = preload("res://assets/art/ui/menus/ui_pause_and_game_over_panels_001.png")

const NIGHT_TIMER_FRAMES: int = 6
const WARNING_ARROW_FRAMES: int = 4
const ICON_FPS: float = 8.0

var _root: Control
var _hunger_bar: ProgressBar
var _wetness_bar: ProgressBar
var _wetness_box: Control
var _height_label: Label
var _distance_label: Label
var _time_label: Label
var _night_box: Control
var _night_label: Label
var _night_icon_atlas: AtlasTexture
var _warning_arrow: TextureRect
var _warning_arrow_atlas: AtlasTexture
var _icon_anim_time: float = 0.0
var _floating_layer: Control

var _game_over_panel: Control
var _game_over_label: Label
var _achievement_list: VBoxContainer
var _toast_layer: Control
var _toast_queue: Array[Dictionary] = []
var _toast_active: bool = false


func _ready() -> void:
	_build_hud()
	hide_game_over()
	set_wetness_visible(false)
	set_night_visible(false)
	set_warning_visible(false)


func _process(delta: float) -> void:
	# 仅在可见时推进帧动画，避免无谓开销。
	var night_on: bool = _night_box != null and _night_box.visible
	var warn_on: bool = _warning_arrow != null and _warning_arrow.visible
	if not night_on and not warn_on:
		return
	_icon_anim_time += delta
	var frame: int = int(_icon_anim_time * ICON_FPS)
	if night_on and _night_icon_atlas != null:
		_set_atlas_frame(_night_icon_atlas, frame, NIGHT_TIMER_FRAMES)
	if warn_on and _warning_arrow_atlas != null:
		_set_atlas_frame(_warning_arrow_atlas, frame, WARNING_ARROW_FRAMES)


func _set_atlas_frame(atlas: AtlasTexture, frame: int, frame_count: int) -> void:
	var fw: float = atlas.atlas.get_width() / float(frame_count)
	var fh: float = atlas.atlas.get_height()
	var idx: int = frame % frame_count
	atlas.region = Rect2(idx * fw, 0.0, fw, fh)


func update_stats(hunger: float, height_m: float, distance_m: float, flight_time: float) -> void:
	_hunger_bar.value = clampf(hunger, 0.0, 100.0)
	_height_label.text = "高度 %03dm" % int(round(height_m))
	_distance_label.text = "%dm" % int(round(distance_m))
	_time_label.text = "时间 %ds" % int(round(flight_time))


func update_wetness(wetness: float) -> void:
	_wetness_bar.value = clampf(wetness, 0.0, 100.0)
	set_wetness_visible(wetness > 0.5)


func set_wetness_visible(value: bool) -> void:
	if _wetness_box != null:
		_wetness_box.visible = value


func set_night_visible(value: bool) -> void:
	if _night_box != null:
		_night_box.visible = value


func update_night_countdown(phase_label: String) -> void:
	if _night_label != null:
		_night_label.text = phase_label


func set_warning_visible(value: bool) -> void:
	if _warning_arrow != null:
		_warning_arrow.visible = value


func show_floating_delta(amount: float, world_pos: Vector2) -> void:
	if _floating_layer == null:
		return
	var label := Label.new()
	var sign_text: String = "+" if amount >= 0.0 else ""
	label.text = "%s%d" % [sign_text, int(round(amount))]
	label.add_theme_font_size_override("font_size", 30)
	var col: Color = Color(0.45, 1.0, 0.55) if amount >= 0.0 else Color(1.0, 0.45, 0.4)
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = world_pos
	_floating_layer.add_child(label)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", world_pos.y - 70.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)


func show_near_miss(world_pos: Vector2) -> void:
	if _floating_layer == null:
		return
	var label := Label.new()
	label.text = "好险!"
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = world_pos + Vector2(-30.0, -40.0)
	_floating_layer.add_child(label)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 56.0, 1.0)
	tween.tween_property(label, "scale", Vector2(1.25, 1.25), 0.18)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


func show_game_over(distance_m: float, flight_time: float, food_count: int, max_height: float, best_distance: float) -> void:
	_game_over_panel.visible = true
	_game_over_label.text = "归途结束\n\n飞行距离 %dm   飞行时间 %ds\n收集食物 %d   最高 %dm\n历史最佳 %dm\n按 R 重新开始" % [
		int(round(distance_m)),
		int(round(flight_time)),
		food_count,
		int(round(max_height)),
		int(round(best_distance)),
	]
	_populate_achievement_list()


func _populate_achievement_list() -> void:
	if _achievement_list == null:
		return
	for child in _achievement_list.get_children():
		child.queue_free()

	var save: Node = get_node_or_null("/root/SaveData")
	for a in HomewardAchievementSystem.ACHIEVEMENTS:
		var id: String = String(a["id"])
		var unlocked: bool = save != null and save.is_unlocked(id)
		var row := Label.new()
		if unlocked:
			row.text = "🏅 %s — %s" % [String(a["title"]), String(a["desc"])]
			row.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
		else:
			row.text = "🔒 ??? — 未解锁"
			row.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72))
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		row.add_theme_constant_override("shadow_offset_x", 1)
		row.add_theme_constant_override("shadow_offset_y", 1)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size = Vector2(420.0, 0.0)
		_achievement_list.add_child(row)


func hide_game_over() -> void:
	if _game_over_panel != null:
		_game_over_panel.visible = false


func _build_hud() -> void:
	_root = Control.new()
	_root.name = "HUDRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_hunger_panel()
	_build_height_label()
	_build_wetness_panel()
	_build_distance_sign()
	_build_night_box()
	_build_warning_arrow()
	_build_floating_layer()
	_build_game_over_panel()
	_build_toast_layer()


func _build_hunger_panel() -> void:
	var icon := TextureRect.new()
	icon.texture = HUNGER_METER_TEX
	icon.position = Vector2(22.0, 18.0)
	icon.custom_minimum_size = Vector2(220.0, 56.0)
	icon.size = Vector2(220.0, 56.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_root.add_child(icon)

	_hunger_bar = ProgressBar.new()
	_hunger_bar.max_value = 100.0
	_hunger_bar.show_percentage = false
	_hunger_bar.position = Vector2(22.0, 78.0)
	_hunger_bar.custom_minimum_size = Vector2(240.0, 20.0)
	_hunger_bar.size = Vector2(240.0, 20.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.62, 0.25)
	fill.set_corner_radius_all(6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.12, 0.14, 0.7)
	bg.set_corner_radius_all(6)
	_hunger_bar.add_theme_stylebox_override("fill", fill)
	_hunger_bar.add_theme_stylebox_override("background", bg)
	_root.add_child(_hunger_bar)


func _build_height_label() -> void:
	_height_label = Label.new()
	_height_label.position = Vector2(24.0, 104.0)
	_height_label.add_theme_font_size_override("font_size", 22)
	_height_label.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	_height_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_height_label.add_theme_constant_override("shadow_offset_x", 2)
	_height_label.add_theme_constant_override("shadow_offset_y", 2)
	_root.add_child(_height_label)


func _build_wetness_panel() -> void:
	_wetness_box = Control.new()
	_wetness_box.position = Vector2(24.0, 140.0)
	_root.add_child(_wetness_box)

	var label := Label.new()
	label.text = "湿度"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	_wetness_box.add_child(label)

	_wetness_bar = ProgressBar.new()
	_wetness_bar.max_value = 100.0
	_wetness_bar.show_percentage = false
	_wetness_bar.position = Vector2(0.0, 26.0)
	_wetness_bar.custom_minimum_size = Vector2(200.0, 16.0)
	_wetness_bar.size = Vector2(200.0, 16.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.66, 0.95)
	fill.set_corner_radius_all(5)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.12, 0.14, 0.7)
	bg.set_corner_radius_all(5)
	_wetness_bar.add_theme_stylebox_override("fill", fill)
	_wetness_bar.add_theme_stylebox_override("background", bg)
	_wetness_box.add_child(_wetness_bar)


func _build_distance_sign() -> void:
	var sign := TextureRect.new()
	sign.texture = DISTANCE_SIGN_TEX
	sign.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	sign.position = Vector2(-250.0, 16.0)
	sign.custom_minimum_size = Vector2(228.0, 102.0)
	sign.size = Vector2(228.0, 102.0)
	sign.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sign.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_root.add_child(sign)

	_distance_label = Label.new()
	_distance_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_distance_label.position = Vector2(-220.0, 48.0)
	_distance_label.custom_minimum_size = Vector2(170.0, 0.0)
	_distance_label.add_theme_font_size_override("font_size", 32)
	_distance_label.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
	_distance_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_distance_label.add_theme_constant_override("shadow_offset_x", 2)
	_distance_label.add_theme_constant_override("shadow_offset_y", 2)
	_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_distance_label)

	_time_label = Label.new()
	_time_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_time_label.position = Vector2(-220.0, 120.0)
	_time_label.custom_minimum_size = Vector2(170.0, 0.0)
	_time_label.add_theme_font_size_override("font_size", 20)
	_time_label.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
	_time_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_time_label.add_theme_constant_override("shadow_offset_x", 2)
	_time_label.add_theme_constant_override("shadow_offset_y", 2)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_time_label)


func _build_night_box() -> void:
	_night_box = Control.new()
	_night_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_night_box.position = Vector2(-90.0, 14.0)
	_root.add_child(_night_box)

	var icon := TextureRect.new()
	_night_icon_atlas = _make_sheet_atlas(NIGHT_TIMER_TEX, NIGHT_TIMER_FRAMES)
	icon.texture = _night_icon_atlas
	icon.custom_minimum_size = Vector2(72.0, 72.0)
	icon.size = Vector2(72.0, 72.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_night_box.add_child(icon)

	_night_label = Label.new()
	_night_label.position = Vector2(80.0, 22.0)
	_night_label.add_theme_font_size_override("font_size", 22)
	_night_label.add_theme_color_override("font_color", Color(0.85, 0.88, 1.0))
	_night_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_night_label.add_theme_constant_override("shadow_offset_x", 2)
	_night_label.add_theme_constant_override("shadow_offset_y", 2)
	_night_box.add_child(_night_label)


func _build_warning_arrow() -> void:
	_warning_arrow = TextureRect.new()
	_warning_arrow_atlas = _make_sheet_atlas(WARNING_ARROW_TEX, WARNING_ARROW_FRAMES)
	_warning_arrow.texture = _warning_arrow_atlas
	_warning_arrow.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_warning_arrow.position = Vector2(-130.0, -42.0)
	_warning_arrow.custom_minimum_size = Vector2(104.0, 84.0)
	_warning_arrow.size = Vector2(104.0, 84.0)
	_warning_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_warning_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_root.add_child(_warning_arrow)


func _make_sheet_atlas(sheet: Texture2D, frame_count: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var fw: float = sheet.get_width() / float(frame_count)
	atlas.region = Rect2(0.0, 0.0, fw, sheet.get_height())
	return atlas


func _build_floating_layer() -> void:
	_floating_layer = Control.new()
	_floating_layer.name = "FloatingLayer"
	_floating_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_floating_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_floating_layer)


func _build_toast_layer() -> void:
	_toast_layer = Control.new()
	_toast_layer.name = "ToastLayer"
	_toast_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast_layer)


func show_achievement_toast(title: String, description: String) -> void:
	_toast_queue.append({"title": title, "desc": description})
	if not _toast_active:
		_play_next_toast()


func _play_next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_active = false
		return
	_toast_active = true
	var data: Dictionary = _toast_queue.pop_front()

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.886, 0.816, 0.667, 0.96)
	style.border_color = Color(0.376, 0.267, 0.165)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	card.add_theme_stylebox_override("panel", style)
	card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	card.position = Vector2(-190.0, -120.0)
	card.custom_minimum_size = Vector2(380.0, 0.0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var title_label := Label.new()
	title_label.text = "🏅 成就解锁：%s" % String(data["title"])
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.29, 0.227, 0.157))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	var desc_label := Label.new()
	desc_label.text = String(data["desc"])
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.4, 0.32, 0.22))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc_label)

	var enter_y: float = 24.0
	var tween := card.create_tween()
	tween.tween_property(card, "position:y", enter_y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.2)
	tween.tween_property(card, "modulate:a", 0.0, 0.5)
	tween.tween_callback(card.queue_free)
	tween.tween_callback(_play_next_toast)


func _build_game_over_panel() -> void:
	_game_over_panel = Control.new()
	_game_over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_game_over_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.07, 0.09, 0.68)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_over_panel.add_child(dim)

	var panel := TextureRect.new()
	panel.texture = PANEL_TEX
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-280.0, -240.0)
	panel.custom_minimum_size = Vector2(560.0, 400.0)
	panel.size = Vector2(560.0, 400.0)
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_game_over_panel.add_child(panel)

	_game_over_label = Label.new()
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_game_over_label.add_theme_font_size_override("font_size", 24)
	_game_over_label.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	_game_over_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_game_over_label.add_theme_constant_override("shadow_offset_x", 2)
	_game_over_label.add_theme_constant_override("shadow_offset_y", 2)
	_game_over_label.set_anchors_preset(Control.PRESET_CENTER)
	_game_over_label.position = Vector2(-200.0, -230.0)
	_game_over_label.custom_minimum_size = Vector2(400.0, 0.0)
	_game_over_panel.add_child(_game_over_label)

	var ach_title := Label.new()
	ach_title.text = "成就"
	ach_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ach_title.add_theme_font_size_override("font_size", 22)
	ach_title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	ach_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	ach_title.set_anchors_preset(Control.PRESET_CENTER)
	ach_title.position = Vector2(-200.0, 8.0)
	ach_title.custom_minimum_size = Vector2(400.0, 0.0)
	_game_over_panel.add_child(ach_title)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_CENTER)
	scroll.position = Vector2(-220.0, 40.0)
	scroll.custom_minimum_size = Vector2(440.0, 150.0)
	scroll.size = Vector2(440.0, 150.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_game_over_panel.add_child(scroll)

	_achievement_list = VBoxContainer.new()
	_achievement_list.add_theme_constant_override("separation", 4)
	_achievement_list.custom_minimum_size = Vector2(420.0, 0.0)
	scroll.add_child(_achievement_list)
