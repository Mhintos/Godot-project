extends Node2D

@export_file("*.tscn") var inspection_scene_path: String = "res://scene/ui/inspection_2d.tscn"
@export var intro_textures: Array[Texture2D] = []

@onready var background: TextureRect = $Background
@onready var skip_button: TextureButton = $CanvasLayer/SkipButton
@onready var intro_sfx: AudioStreamPlayer = $IntroSFX

var current_page: int = 0
var is_transitioning: bool = false

func _ready() -> void:
	if skip_button and not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)
	if skip_button and not skip_button.mouse_entered.is_connected(_on_skip_button_mouse_entered):
		skip_button.mouse_entered.connect(_on_skip_button_mouse_entered)

	if intro_sfx and intro_sfx.stream and not intro_sfx.playing:
		intro_sfx.play()

	_show_page()

func _show_page() -> void:
	if intro_textures.is_empty():
		push_error("No intro textures assigned.")
		return

	current_page = clamp(current_page, 0, intro_textures.size() - 1)

	if background:
		background.texture = intro_textures[current_page]

	if skip_button:
		skip_button.visible = current_page < intro_textures.size() - 1

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return

	if intro_textures.is_empty():
		return

	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:

		if skip_button and skip_button.visible and skip_button.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return

		UISFXManager.play_click()

		if current_page < intro_textures.size() - 1:
			current_page += 1
			_show_page()
		else:
			is_transitioning = true
			_go_to_inspection()

func _on_skip_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	UISFXManager.play_click()
	_go_to_inspection()

func _on_skip_button_mouse_entered() -> void:
	UISFXManager.play_hover()

func _go_to_inspection() -> void:
	if intro_sfx and intro_sfx.playing:
		intro_sfx.stop()

	get_tree().change_scene_to_file(inspection_scene_path)
