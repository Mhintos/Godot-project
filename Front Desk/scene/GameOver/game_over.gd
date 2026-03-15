extends Node2D

@export var main_menu_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"

@onready var home_button = $CanvasLayer/HomeButton
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

func _ready() -> void:
	home_button.mouse_entered.connect(_on_home_button_hovered)

func _on_home_button_hovered() -> void:
	if hover_sfx.stream:
		if hover_sfx.playing:
			hover_sfx.stop()
		hover_sfx.play()

func _on_home_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file(main_menu_scene_path)
