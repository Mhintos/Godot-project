extends Node2D

@export var main_menu_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"

@export var ending_texture_path: NodePath
@export var next_button_path: NodePath

@export var ending_you_texture: Texture2D
@export var ending_they_got_in_texture: Texture2D
@export var ending_routine_shift_texture: Texture2D
@export var ending_truth_below_texture: Texture2D
@export var game_over_consumed_texture: Texture2D

@export var normal_next_button_normal_texture: Texture2D
@export var normal_next_button_hover_texture: Texture2D
@export var normal_next_button_pressed_texture: Texture2D

@export var game_over_next_button_normal_texture: Texture2D
@export var game_over_next_button_hover_texture: Texture2D
@export var game_over_next_button_pressed_texture: Texture2D

@onready var ending_texture: TextureRect = get_node_or_null(ending_texture_path)
@onready var next_button: TextureButton = get_node_or_null(next_button_path)

func _ready() -> void:
	apply_result_texture()
	apply_next_button_texture_set()

	if next_button:
		if not next_button.pressed.is_connected(_on_next_button_pressed):
			next_button.pressed.connect(_on_next_button_pressed)

		if not next_button.mouse_entered.is_connected(_on_next_button_mouse_entered):
			next_button.mouse_entered.connect(_on_next_button_mouse_entered)
	else:
		push_error("NextButton node not found.")

	MenuMusic.play_ending_flow_music()

func apply_result_texture() -> void:
	if ending_texture == null:
		push_error("EndingTexture node not found.")
		return

	match GameResult.ending_id:
		GameResult.ENDING_YOU:
			ending_texture.texture = ending_you_texture

		GameResult.ENDING_THEY_GOT_IN:
			ending_texture.texture = ending_they_got_in_texture

		GameResult.ENDING_ROUTINE_SHIFT:
			ending_texture.texture = ending_routine_shift_texture

		GameResult.ENDING_TRUTH_BELOW:
			ending_texture.texture = ending_truth_below_texture

		GameResult.ENDING_GAME_OVER_CONSUMED:
			ending_texture.texture = game_over_consumed_texture

		_:
			ending_texture.texture = ending_routine_shift_texture
			push_warning("Unknown ending_id. Defaulting to Routine Shift.")

func apply_next_button_texture_set() -> void:
	if next_button == null:
		push_error("NextButton node not found.")
		return

	if GameResult.ending_id == GameResult.ENDING_GAME_OVER_CONSUMED:
		next_button.texture_normal = game_over_next_button_normal_texture
		next_button.texture_hover = game_over_next_button_hover_texture
		next_button.texture_pressed = game_over_next_button_pressed_texture
		next_button.texture_disabled = game_over_next_button_normal_texture
	else:
		next_button.texture_normal = normal_next_button_normal_texture
		next_button.texture_hover = normal_next_button_hover_texture
		next_button.texture_pressed = normal_next_button_pressed_texture
		next_button.texture_disabled = normal_next_button_normal_texture

func _on_next_button_pressed() -> void:
	UISFXManager.play_click()
	GameResult.clear_result()
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(main_menu_scene_path)

func _on_next_button_mouse_entered() -> void:
	UISFXManager.play_hover()
