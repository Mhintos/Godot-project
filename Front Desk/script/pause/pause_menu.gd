extends Node2D

@export_file("*.tscn") var main_menu_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"
@export_file("*.tscn") var settings_scene_path: String = "res://scene/Settings/Settings.tscn"

@onready var resume_button: TextureButton = $CanvasLayer/ResumeButton
@onready var main_menu_button: TextureButton = $CanvasLayer/MainMenuButton
@onready var settings_button: TextureButton = $CanvasLayer/SettingsButton
@onready var quit_button: TextureButton = $CanvasLayer/QuitButton

@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX
@onready var pause_music: AudioStreamPlayer = $PauseMusic

var is_transitioning: bool = false

func _ready() -> void:
	_connect_button_signals()

	if pause_music and pause_music.stream and not pause_music.playing:
		pause_music.play()

func _connect_button_signals() -> void:
	_connect_button(resume_button, _on_resume_button_pressed)
	_connect_button(main_menu_button, _on_main_menu_button_pressed)
	_connect_button(settings_button, _on_settings_button_pressed)
	_connect_button(quit_button, _on_quit_button_pressed)

func _connect_button(button: TextureButton, pressed_callable: Callable) -> void:
	if not button:
		return

	if not button.mouse_entered.is_connected(_on_button_hovered):
		button.mouse_entered.connect(_on_button_hovered)

	if not button.pressed.is_connected(pressed_callable):
		button.pressed.connect(pressed_callable)

func _on_button_hovered() -> void:
	if is_transitioning:
		return

	if hover_sfx and hover_sfx.stream:
		hover_sfx.stop()
		hover_sfx.play()

func _on_resume_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().paused = false
	queue_free()

func _on_main_menu_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene_path)

func _on_settings_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().paused = false
	get_tree().change_scene_to_file(settings_scene_path)

func _on_quit_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().quit()

func _set_buttons_disabled(value: bool) -> void:
	if resume_button:
		resume_button.disabled = value
	if main_menu_button:
		main_menu_button.disabled = value
	if settings_button:
		settings_button.disabled = value
	if quit_button:
		quit_button.disabled = value
