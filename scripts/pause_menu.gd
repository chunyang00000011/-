extends CanvasLayer
class_name HomewardPauseMenu

## 暂停菜单：ESC 暂停游戏，提供继续 / 重新开始 / 音量 / 返回标题。
## process_mode = ALWAYS 以便在 get_tree().paused 时仍响应。

signal resume_requested
signal restart_requested
signal quit_to_title_requested

const PANEL_TEX: Texture2D = preload("res://assets/art/ui/menus/ui_pause_and_game_over_panels_001.png")

var _root: Control
var _version_label: Label
var _music_slider: HSlider
var _sfx_slider: HSlider
var _active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_build_menu()
	visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_menu"):
		return
	if visible:
		_on_resume()
		get_viewport().set_input_as_handled()
	elif _active:
		open()
		get_viewport().set_input_as_handled()


func set_active(value: bool) -> void:
	_active = value
	if not value and visible:
		close()


func open() -> void:
	_sync_sliders()
	visible = true
	get_tree().paused = true
	_play_sfx("pause_open")


func close() -> void:
	visible = false
	get_tree().paused = false


func _on_resume() -> void:
	_play_sfx("pause_close")
	close()
	resume_requested.emit()


func _on_restart() -> void:
	_play_sfx("menu_confirm")
	close()
	restart_requested.emit()


func _on_quit_to_title() -> void:
	_play_sfx("menu_confirm")
	close()
	quit_to_title_requested.emit()


func _on_button_hover() -> void:
	_play_sfx("menu_hover")


func _on_music_volume_changed(value: float) -> void:
	var audio: Node = _audio()
	if audio != null:
		audio.set_music_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	var audio: Node = _audio()
	if audio != null:
		audio.set_sfx_volume(value)


func _audio() -> Node:
	return get_node_or_null("/root/AudioManager")


func _play_sfx(key: String) -> void:
	var audio: Node = _audio()
	if audio != null:
		audio.play_sfx(key)


func _sync_sliders() -> void:
	var audio: Node = _audio()
	if audio == null:
		return
	if _music_slider != null:
		_music_slider.set_value_no_signal(audio.get_music_volume())
	if _sfx_slider != null:
		_sfx_slider.set_value_no_signal(audio.get_sfx_volume())


func _build_menu() -> void:
	_root = Control.new()
	_root.name = "PauseRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.06, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var panel := TextureRect.new()
	panel.texture = PANEL_TEX
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260.0, -240.0)
	panel.custom_minimum_size = Vector2(520.0, 460.0)
	panel.size = Vector2(520.0, 460.0)
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_root.add_child(panel)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-160.0, -180.0)
	box.custom_minimum_size = Vector2(320.0, 0.0)
	box.add_theme_constant_override("separation", 16)
	_root.add_child(box)

	var title := Label.new()
	title.text = "暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	box.add_child(title)

	box.add_child(_make_button("继续", _on_resume))
	box.add_child(_make_button("重新开始", _on_restart))
	_music_slider = _add_volume_row(box, "音乐", _on_music_volume_changed)
	_sfx_slider = _add_volume_row(box, "音效", _on_sfx_volume_changed)
	box.add_child(_make_button("返回标题", _on_quit_to_title))

	_version_label = Label.new()
	_version_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_version_label.position = Vector2(-170.0, -34.0)
	_version_label.add_theme_font_size_override("font_size", 16)
	_version_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.86, 0.8))
	_version_label.text = "版本 %s" % _game_version()
	_root.add_child(_version_label)


func _make_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320.0, 48.0)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(handler)
	button.mouse_entered.connect(_on_button_hover)
	return button


func _add_volume_row(parent: VBoxContainer, label_text: String, handler: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(70.0, 0.0)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = 0.8
	slider.custom_minimum_size = Vector2(220.0, 30.0)
	slider.value_changed.connect(handler)
	row.add_child(slider)

	parent.add_child(row)
	return slider


func _game_version() -> String:
	var v: String = String(ProjectSettings.get_setting("application/config/version", ""))
	if v == "":
		return "0.4.0"
	return v
