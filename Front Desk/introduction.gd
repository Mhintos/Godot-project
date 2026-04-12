extends Node2D

@export_file("*.tscn") var inspection_scene_path: String = "res://scene/ui/inspection_2d.tscn"

@export var intro_textures: Array[Texture2D] = []

@onready var background: TextureRect = $Background
@onready var skip_button: TextureButton = $CanvasLayer/SkipButton
@onready var back_button: TextureButton = $CanvasLayer/BackButton
@onready var next_button: TextureButton = $CanvasLayer/NextButton

@onready var intro_sfx: AudioStreamPlayer = $IntroSFX

var current_page: int = 0
var is_transitioning: bool = false

func _ready() -> void:
	if skip_button and not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)
	if skip_button and not skip_button.mouse_entered.is_connected(_on_button_hovered):
		skip_button.mouse_entered.connect(_on_button_hovered)

	if back_button and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	if back_button and not back_button.mouse_entered.is_connected(_on_button_hovered):
		back_button.mouse_entered.connect(_on_button_hovered)

	if next_button and not next_button.pressed.is_connected(_on_next_button_pressed):
		next_button.pressed.connect(_on_next_button_pressed)
	if next_button and not next_button.mouse_entered.is_connected(_on_button_hovered):
		next_button.mouse_entered.connect(_on_button_hovered)

	if intro_sfx and intro_sfx.stream and not intro_sfx.playing:
		intro_sfx.play()

	_show_page()

func _on_button_hovered() -> void:
	UISFXManager.play_hover()

func _on_skip_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	UISFXManager.play_click()
	_go_to_inspection()

func _on_back_button_pressed() -> void:
	if is_transitioning:
		return

	if current_page <= 0:
		return

	UISFXManager.play_click()
	current_page -= 1
	_show_page()

func _on_next_button_pressed() -> void:
	if is_transitioning:
		return

	UISFXManager.play_click()

	if current_page < intro_textures.size() - 1:
		current_page += 1
		_show_page()
	else:
		is_transitioning = true
		_go_to_inspection()

func _show_page() -> void:
	if intro_textures.is_empty():
		return

	current_page = clamp(current_page, 0, intro_textures.size() - 1)

	if background:
		background.texture = intro_textures[current_page]

	if back_button:
		back_button.visible = current_page > 0

	if next_button:
		next_button.visible = true

	if skip_button:
		skip_button.visible = current_page < intro_textures.size() - 1

func _go_to_inspection() -> void:
	if intro_sfx and intro_sfx.playing:
		intro_sfx.stop()

	get_tree().change_scene_to_file(inspection_scene_path)
