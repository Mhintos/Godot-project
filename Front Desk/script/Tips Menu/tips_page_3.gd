extends Node2D

@export_file("*.tscn") var tips_2_scene_path: String = "res://scene/Tips Menu/tips_page_2.tscn"
@export_file("*.tscn") var tips_4_scene_path: String = "res://scene/Tips Menu/tips_page_4.tscn"

@onready var back_button: TextureButton = $CanvasLayer/BackButton
@onready var next_button: TextureButton = $CanvasLayer/NextButton

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
	UISFXManager.play_hover()

func _on_back_button_pressed() -> void:
	UISFXManager.play_click()

	var tree := get_tree()
	if tree == null:
		return

	tree.change_scene_to_file(tips_2_scene_path)

func _on_next_button_pressed() -> void:
	UISFXManager.play_click()

	var tree := get_tree()
	if tree == null:
		return

	tree.change_scene_to_file(tips_4_scene_path)
