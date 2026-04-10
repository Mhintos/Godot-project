extends Node2D

@export_file("*.tscn") var game_scene_path: String = "res://scene/Introduction/Introduction.tscn"
@export_file("*.tscn") var settings_scene_path: String = "res://scene/Settings_Menu/Settings.tscn"
@export_file("*.tscn") var tips_scene_path: String = "res://scene/tips/tips_page_1.tscn"

@onready var start_button: TextureButton = $CanvasLayer/StartButton
@onready var quit_button: TextureButton = $CanvasLayer/QuitButton
@onready var settings_button: TextureButton = $CanvasLayer/SettingsButton
@onready var tips_button: TextureButton = $CanvasLayer/TipsButton

var is_transitioning: bool = false

func _ready() -> void:
	_connect_button(start_button, _on_start_button_pressed)
	_connect_button(quit_button, _on_quit_button_pressed)
	_connect_button(settings_button, _on_settings_button_pressed)
	_connect_button(tips_button, _on_tips_button_pressed)
	
	MenuMusic.play_main_menu_music()


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

	UISFXManager.play_hover()

func _on_start_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	UISFXManager.play_menu_click()
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(game_scene_path)

func _on_quit_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	UISFXManager.play_menu_click()
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	UISFXManager.play_menu_click()
	get_tree().change_scene_to_file(settings_scene_path)

func _on_tips_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	UISFXManager.play_menu_click()
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
