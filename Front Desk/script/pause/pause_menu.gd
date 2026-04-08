extends Node2D

# Buttons
@onready var resume_button: TextureButton = $CanvasLayer/ResumeButton
@onready var main_menu_button: TextureButton = $CanvasLayer/MainMenuButton
@onready var settings_button: TextureButton = $CanvasLayer/SettingsButton
@onready var quit_button: TextureButton = $CanvasLayer/QuitButton

# SFX
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

func _ready() -> void:
	# Connect buttons safely
	var buttons = [
		[resume_button, "_on_resume_button_pressed"],
		[main_menu_button, "_on_main_menu_button_pressed"],
		[settings_button, "_on_settings_button_pressed"],
		[quit_button, "_on_quit_button_pressed"]
	]

	for pair in buttons:
		var btn = pair[0]
		var func_name = pair[1]
		if btn.pressed.is_connected(func_name):
			btn.pressed.disconnect(func_name)
		btn.pressed.connect(func_name)

	# Connect hover SFX for all buttons
	for btn in [resume_button, main_menu_button, settings_button, quit_button]:
		btn.mouse_entered.connect(_on_button_hovered)

# Hover SFX
func _on_button_hovered() -> void:
	if hover_sfx.stream:
		if hover_sfx.playing:
			hover_sfx.stop()
		hover_sfx.play()

# Button functions
func _on_resume_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
	get_tree().paused = false
	queue_free() # remove pause menu

func _on_main_menu_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/Main Menu/Mainmenu.tscn")

func _on_settings_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/Settings/Settings.tscn")

func _on_quit_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
	get_tree().quit()
