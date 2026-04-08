extends Node2D

@export var main_menu_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"

@export var ending_texture_path: NodePath
@export var home_button_path: NodePath

@export var ending_you_texture: Texture2D
@export var ending_they_got_in_texture: Texture2D
@export var ending_routine_shift_texture: Texture2D
@export var ending_truth_below_texture: Texture2D
@export var game_over_consumed_texture: Texture2D

@export var normal_home_button_normal_texture: Texture2D
@export var normal_home_button_hover_texture: Texture2D
@export var normal_home_button_pressed_texture: Texture2D

@export var game_over_home_button_normal_texture: Texture2D
@export var game_over_home_button_hover_texture: Texture2D
@export var game_over_home_button_pressed_texture: Texture2D

@onready var ending_texture: TextureRect = get_node(ending_texture_path)
@onready var home_button: TextureButton = get_node(home_button_path)

@onready var background_sfx: AudioStreamPlayer = $BackgroundSFX
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

func _ready() -> void:
	apply_result_texture()
	apply_home_button_texture_set()

	home_button.pressed.connect(_on_home_button_pressed)
	home_button.mouse_entered.connect(_on_home_button_mouse_entered)

	if background_sfx and background_sfx.stream and not background_sfx.playing:
		background_sfx.play()

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

func apply_home_button_texture_set() -> void:
	if home_button == null:
		push_error("HomeButton node not found.")
		return

	if GameResult.ending_id == GameResult.ENDING_GAME_OVER_CONSUMED:
		home_button.texture_normal = game_over_home_button_normal_texture
		home_button.texture_hover = game_over_home_button_hover_texture
		home_button.texture_pressed = game_over_home_button_pressed_texture
		home_button.texture_disabled = game_over_home_button_normal_texture
	else:
		home_button.texture_normal = normal_home_button_normal_texture
		home_button.texture_hover = normal_home_button_hover_texture
		home_button.texture_pressed = normal_home_button_pressed_texture
		home_button.texture_disabled = normal_home_button_normal_texture

func _on_home_button_pressed() -> void:
	if click_sfx and click_sfx.stream:
		click_sfx.play()

	GameResult.clear_result()
	get_tree().change_scene_to_file(main_menu_scene_path)

func _on_home_button_mouse_entered() -> void:
	if hover_sfx and hover_sfx.stream:
		hover_sfx.play()
