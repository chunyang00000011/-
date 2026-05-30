extends CanvasLayer
class_name HomewardHUD

var _hunger_bar: ProgressBar
var _height_label: Label
var _distance_label: Label
var _time_label: Label
var _game_over_panel: ColorRect
var _game_over_label: Label


func _ready() -> void:
	_build_hud()
	hide_game_over()


func update_stats(hunger: float, height_m: float, distance_m: float, flight_time: float) -> void:
	_hunger_bar.value = clampf(hunger, 0.0, 100.0)
	_height_label.text = "Height %03dm" % int(round(height_m))
	_distance_label.text = "Distance %dm" % int(round(distance_m))
	_time_label.text = "Time %ds" % int(round(flight_time))


func show_game_over(distance_m: float, flight_time: float) -> void:
	_game_over_panel.visible = true
	_game_over_label.text = "Game Over\nDistance %dm\nTime %ds\nPress R to retry" % [
		int(round(distance_m)),
		int(round(flight_time)),
	]


func hide_game_over() -> void:
	if _game_over_panel != null:
		_game_over_panel.visible = false


func _build_hud() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var panel := PanelContainer.new()
	panel.position = Vector2(22.0, 18.0)
	panel.custom_minimum_size = Vector2(330.0, 126.0)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var hunger_label := Label.new()
	hunger_label.text = "Hunger"
	box.add_child(hunger_label)

	_hunger_bar = ProgressBar.new()
	_hunger_bar.max_value = 100.0
	_hunger_bar.show_percentage = false
	_hunger_bar.custom_minimum_size = Vector2(280.0, 18.0)
	box.add_child(_hunger_bar)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 18)
	box.add_child(stats_row)

	_height_label = Label.new()
	_distance_label = Label.new()
	_time_label = Label.new()
	stats_row.add_child(_height_label)
	stats_row.add_child(_distance_label)
	stats_row.add_child(_time_label)

	_game_over_panel = ColorRect.new()
	_game_over_panel.color = Color(0.05, 0.07, 0.09, 0.68)
	_game_over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_game_over_panel)

	_game_over_label = Label.new()
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_game_over_label.add_theme_font_size_override("font_size", 34)
	_game_over_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_panel.add_child(_game_over_label)
