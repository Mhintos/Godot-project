extends Node2D

@export_file("*.tscn") var tips_1_scene_path: String = "res://scene/Tips Menu/tips_page_1.tscn"
@export_file("*.tscn") var tips_3_scene_path: String = "res://scene/Tips Menu/tips_page_3.tscn"

@onready var back_button: TextureButton = $CanvasLayer/BackButton
@onready var next_button: TextureButton = $CanvasLayer/NextButton
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

func _ready() -> void:
	if back_button and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	if back_button and not back_button.mouse_entered.is_connected(_on_button_hovered):
		back_button.mouse_entered.connect(_on_button_hovered)

	if next_button and not next_button.pressed.is_connected(_on_next_button_pressed):
		next_button.pressed.connect(_on_next_button_pressed)
	if next_button and not next_button.mouse_entered.is_connected(_on_button_hovered):
		next_button.mouse_entered.connect(_on_button_hovered)

func _on_button_hovered() -> void:
	if hover_sfx:
		hover_sfx.play()

func _on_back_button_pressed() -> void:
	if click_sfx:
		click_sfx.play()
	get_tree().change_scene_to_file(tips_1_scene_path)

func _on_next_button_pressed() -> void:
	if click_sfx:
		click_sfx.play()
	get_tree().change_scene_to_file(tips_3_scene_path)
