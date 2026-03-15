extends Node2D

@export var game_scene_path: String = "res://scene/ui/inspection_2d.tscn"

@onready var start_button = $CanvasLayer/StartButton
@onready var quit_button = $CanvasLayer/QuitButton
@onready var main_menu_music: AudioStreamPlayer = $MainMenuMusic
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX


func _ready() -> void:
	start_button.mouse_entered.connect(_on_button_hovered)
	quit_button.mouse_entered.connect(_on_button_hovered)


func _on_button_hovered() -> void:
	if hover_sfx.stream:
		if hover_sfx.playing:
			hover_sfx.stop()
		hover_sfx.play()


func _on_start_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file(game_scene_path)


func _on_quit_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().quit()
