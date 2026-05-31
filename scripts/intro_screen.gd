extends CanvasLayer
class_name HomewardIntroScreen

signal start_requested

const ORIGINAL_VIDEO_PATH: String = "res://assets/intro/homeward_intro.mp4"
const PLAYABLE_VIDEO_PATH: String = "res://assets/intro/homeward_intro.ogv"
const CLICK_PROMPT_TEXT: String = "点击屏幕开始你的归途"

@onready var video_player: VideoStreamPlayer = $IntroRoot/VideoPlayer
@onready var title_image: TextureRect = $IntroRoot/TitleImage
@onready var click_prompt: Label = $IntroRoot/ClickPrompt

var _title_visible: bool = false
var _started: bool = false
var _video_was_playing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_process(false)
	click_prompt.text = CLICK_PROMPT_TEXT
	if not video_player.finished.is_connected(_on_video_finished):
		video_player.finished.connect(_on_video_finished)


func begin() -> void:
	_started = false
	_title_visible = false
	_video_was_playing = false
	visible = true
	title_image.visible = false
	click_prompt.visible = false

	var playable_stream := _load_playable_video_stream()
	if playable_stream == null:
		show_title()
		return

	video_player.stream = playable_stream
	video_player.visible = true
	video_player.play()
	set_process(true)


func _process(_delta: float) -> void:
	# 兜底：部分 .ogv 末尾是静止标题卡，finished 信号可能不触发，靠轮询检测结束。
	if _title_visible or _started:
		return
	if video_player.is_playing():
		_video_was_playing = true
	elif _video_was_playing:
		show_title()


func show_title() -> void:
	set_process(false)
	video_player.stop()
	video_player.visible = false
	title_image.visible = true
	click_prompt.visible = true
	_title_visible = true


func _input(event: InputEvent) -> void:
	# 视频播放期间点击可跳过开场，标题卡上点击则开始游戏——任何时刻都不卡住。
	if _started:
		return
	if _is_confirm_event(event):
		_request_start()


func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return event.is_action_pressed("ui_accept")


func _on_video_finished() -> void:
	show_title()


func _request_start() -> void:
	_started = true
	_title_visible = false
	set_process(false)
	visible = false
	video_player.stop()
	get_viewport().set_input_as_handled()
	start_requested.emit()


func _load_playable_video_stream() -> VideoStream:
	if ResourceLoader.exists(PLAYABLE_VIDEO_PATH):
		return load(PLAYABLE_VIDEO_PATH) as VideoStream

	return load(ORIGINAL_VIDEO_PATH) as VideoStream
