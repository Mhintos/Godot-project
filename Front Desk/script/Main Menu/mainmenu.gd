extends Node2D

@export_file("*.tscn") var game_scene_path: String = "res://scene/ui/inspection_2d.tscn"
@export_file("*.tscn") var settings_scene_path: String = "res://scene/Settings/Settings.tscn"
@export_file("*.tscn") var tips_scene_path: String = "res://scene/tips/tips_1.tscn"

@onready var start_button: TextureButton = $CanvasLayer/StartButton
@onready var quit_button: TextureButton = $CanvasLayer/QuitButton
@onready var settings_button: TextureButton = $CanvasLayer/SettingsButton
@onready var tips_button: TextureButton = $CanvasLayer/TipsButton

@onready var main_menu_music: AudioStreamPlayer = $MainMenuMusic
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

var is_transitioning: bool = false

func _ready() -> void:
	_connect_button(start_button, _on_start_button_pressed)
	_connect_button(quit_button, _on_quit_button_pressed)
	_connect_button(settings_button, _on_settings_button_pressed)
	_connect_button(tips_button, _on_tips_button_pressed)

	_play_main_menu_music()

func _connect_button(button: TextureButton, pressed_callable: Callable) -> void:
	if not button:
		return

	if not button.mouse_entered.is_connected(_on_button_hovered):
		button.mouse_entered.connect(_on_button_hovered)

	if not button.pressed.is_connected(pressed_callable):
		button.pressed.connect(pressed_callable)

func _play_main_menu_music() -> void:
	if not main_menu_music or not main_menu_music.stream:
		return

	var stream := main_menu_music.stream
	if stream is AudioStreamOggVorbis:
		stream.loop = true

	if not main_menu_music.playing:
		main_menu_music.play()

func _on_button_hovered() -> void:
	if is_transitioning:
		return

	if hover_sfx and hover_sfx.stream:
		hover_sfx.stop()
		hover_sfx.play()

func _on_start_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file(game_scene_path)

func _on_quit_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().quit()

func _on_settings_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file(settings_scene_path)

func _on_tips_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file(tips_scene_path)

func _set_buttons_disabled(value: bool) -> void:
	if start_button:
		start_button.disabled = value
	if quit_button:
		quit_button.disabled = value
	if settings_button:
		settings_button.disabled = value
	if tips_button:
		tips_button.disabled = value
