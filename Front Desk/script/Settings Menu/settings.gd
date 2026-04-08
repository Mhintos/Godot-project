extends Node2D

@export_file("*.tscn") var main_menu_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"
@export_file("*.tscn") var pause_scene_path: String = "res://scene/Pause Menu/pause_menu.tscn"

@onready var volume_slider: HSlider = $CanvasLayer/VolumeSlider
@onready var back_button: TextureButton = $CanvasLayer/BackButton

@onready var settings_music: AudioStreamPlayer = $SettingsMusic
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

var is_transitioning: bool = false

const MASTER_BUS_INDEX: int = 0
const MIN_LINEAR_VOLUME: float = 0.001
const BUTTON_CLICK_DELAY := 0.12

func _ready() -> void:
	if _is_opened_from_pause():
		process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	if volume_slider:
		var db: float = AudioServer.get_bus_volume_db(MASTER_BUS_INDEX)
		volume_slider.value = db_to_linear(db)

		if not volume_slider.value_changed.is_connected(_on_volume_slider_value_changed):
			volume_slider.value_changed.connect(_on_volume_slider_value_changed)

	if back_button:
		if not back_button.mouse_entered.is_connected(_on_back_button_hovered):
			back_button.mouse_entered.connect(_on_back_button_hovered)

		if not back_button.pressed.is_connected(_on_back_button_pressed):
			back_button.pressed.connect(_on_back_button_pressed)

	if not _is_opened_from_pause():
		if settings_music and settings_music.stream:
			MenuMusic.play_music(settings_music.stream, settings_music.volume_db)

func _on_volume_slider_value_changed(value: float) -> void:
	var safe_value: float = clampf(value, MIN_LINEAR_VOLUME, 1.0)
	AudioServer.set_bus_volume_db(MASTER_BUS_INDEX, linear_to_db(safe_value))

func _on_back_button_hovered() -> void:
	if is_transitioning:
		return

	if hover_sfx and hover_sfx.stream:
		if hover_sfx.playing:
			hover_sfx.stop()
		hover_sfx.play()

func _on_back_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_controls_disabled(true)

	if click_sfx and click_sfx.stream:
		if click_sfx.playing:
			click_sfx.stop()
		click_sfx.play()

	await get_tree().create_timer(BUTTON_CLICK_DELAY).timeout

	if _is_opened_from_pause():
		_return_to_pause_overlay()
		return

	get_tree().change_scene_to_file(main_menu_scene_path)

func _return_to_pause_overlay() -> void:
	var overlay := get_parent()
	if overlay == null:
		push_error("Settings opened from pause but no overlay parent was found.")
		return

	var pause_scene: PackedScene = load(pause_scene_path)
	if pause_scene == null:
		push_error("Pause scene could not be loaded: " + pause_scene_path)
		return

	var pause_instance = pause_scene.instantiate()
	overlay.add_child(pause_instance)
	queue_free()

func _is_opened_from_pause() -> bool:
	var parent_node := get_parent()
	return parent_node != null and parent_node.name == "PauseOverlayLayer"

func _set_controls_disabled(value: bool) -> void:
	if back_button:
		back_button.disabled = value

	if volume_slider:
		volume_slider.editable = not value
