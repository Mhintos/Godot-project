extends Node2D

@export_file("*.tscn") var main_menu_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"

@export var ending_you_textures: Array[Texture2D] = []
@export var ending_they_got_in_textures: Array[Texture2D] = []
@export var ending_routine_shift_textures: Array[Texture2D] = []
@export var ending_truth_below_textures: Array[Texture2D] = []
@export var game_over_consumed_textures: Array[Texture2D] = []

@export var first_page_next_position: Vector2 = Vector2(542.016, 526.0)
@export var last_page_main_menu_position: Vector2 = Vector2(1062.0, 37.0)

@onready var background: TextureRect = $EndingTexture
@onready var next_button: TextureButton = $CanvasLayer/NextButton
@onready var main_menu_button: TextureButton = $CanvasLayer/MainMenuButton

var current_page: int = 0
var is_transitioning: bool = false
var current_textures: Array[Texture2D] = []

func _ready() -> void:
	current_textures = _get_textures_for_current_ending()

	if next_button and not next_button.pressed.is_connected(_on_next_button_pressed):
		next_button.pressed.connect(_on_next_button_pressed)
	if next_button and not next_button.mouse_entered.is_connected(_on_button_hovered):
		next_button.mouse_entered.connect(_on_button_hovered)

	if main_menu_button and not main_menu_button.pressed.is_connected(_on_main_menu_button_pressed):
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	if main_menu_button and not main_menu_button.mouse_entered.is_connected(_on_button_hovered):
		main_menu_button.mouse_entered.connect(_on_button_hovered)

	MenuMusic.play_ending_flow_music()
	_show_page()

func _get_textures_for_current_ending() -> Array[Texture2D]:
	match GameResult.ending_id:
		GameResult.ENDING_YOU:
			return ending_you_textures
		GameResult.ENDING_THEY_GOT_IN:
			return ending_they_got_in_textures
		GameResult.ENDING_ROUTINE_SHIFT:
			return ending_routine_shift_textures
		GameResult.ENDING_TRUTH_BELOW:
			return ending_truth_below_textures
		GameResult.ENDING_GAME_OVER_CONSUMED:
			return game_over_consumed_textures
		_:
			return ending_routine_shift_textures

func _on_button_hovered() -> void:
	UISFXManager.play_hover()

func _on_next_button_pressed() -> void:
	if is_transitioning:
		return

	if current_page != 0:
		return

	UISFXManager.play_click()

	if current_page < current_textures.size() - 1:
		current_page += 1
		_show_page()
	else:
		is_transitioning = true
		_go_to_main_menu()

func _on_main_menu_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	UISFXManager.play_click()
	_go_to_main_menu()

func _show_page() -> void:
	if current_textures.is_empty():
		push_error("No ending story textures assigned for current ending.")
		return

	current_page = clamp(current_page, 0, current_textures.size() - 1)

	if background:
		background.texture = current_textures[current_page]

	var is_first_page := current_page == 0
	var is_last_page := current_page == current_textures.size() - 1

	if next_button:
		next_button.visible = is_first_page
		if is_first_page:
			next_button.position = first_page_next_position

	if main_menu_button:
		main_menu_button.visible = is_last_page
		if is_last_page:
			main_menu_button.position = last_page_main_menu_position

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return

	if current_textures.is_empty():
		return

	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:

		if next_button and next_button.visible and next_button.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return

		if main_menu_button and main_menu_button.visible and main_menu_button.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return

		if current_page == 0:
			return

		if current_page >= current_textures.size() - 1:
			return

		UISFXManager.play_click()
		current_page += 1
		_show_page()

func _go_to_main_menu() -> void:
	GameResult.clear_result()
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(main_menu_scene_path)
