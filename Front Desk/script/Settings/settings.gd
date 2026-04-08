extends Node2D

@export_file("*.tscn") var return_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"

@onready var volume_slider: HSlider = $CanvasLayer/VolumeSlider
@onready var back_button: TextureButton = $CanvasLayer/BackButton

@onready var settings_music: AudioStreamPlayer = $SettingsMusic
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

var is_transitioning: bool = false
const MASTER_BUS_INDEX: int = 0
const MIN_LINEAR_VOLUME: float = 0.001

func _ready() -> void:
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

	if settings_music and settings_music.stream and not settings_music.playing:
		settings_music.play()

func _on_volume_slider_value_changed(value: float) -> void:
	var safe_value: float = clampf(value, MIN_LINEAR_VOLUME, 1.0)
	AudioServer.set_bus_volume_db(MASTER_BUS_INDEX, linear_to_db(safe_value))

func _on_back_button_hovered() -> void:
	if is_transitioning:
		return

	if hover_sfx and hover_sfx.stream:
		hover_sfx.stop()
		hover_sfx.play()

func _on_back_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_controls_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file(return_scene_path)

func _set_controls_disabled(value: bool) -> void:
	if back_button:
		back_button.disabled = value

	if volume_slider:
		volume_slider.editable = not value
