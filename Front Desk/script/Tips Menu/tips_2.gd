extends Node2D

@export_file("*.tscn") var tips1_scene_path: String = "res://scene/tips/tips_1.tscn"

@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX
@onready var back_button: TextureButton = $CanvasLayer/BackButton

var is_transitioning: bool = false
const BUTTON_CLICK_DELAY := 0.12

func _ready() -> void:
	if back_button and not back_button.mouse_entered.is_connected(_on_button_hovered):
		back_button.mouse_entered.connect(_on_button_hovered)

	if back_button and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

func _on_button_hovered() -> void:
	if is_transitioning:
		return

	if hover_sfx and hover_sfx.stream:
		if hover_sfx.playing:
			hover_sfx.stop()
		hover_sfx.play()

func _on_back_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_set_buttons_disabled(true)

	if click_sfx and click_sfx.stream:
		if click_sfx.playing:
			click_sfx.stop()
		click_sfx.play()

	await get_tree().create_timer(BUTTON_CLICK_DELAY).timeout
	get_tree().change_scene_to_file(tips1_scene_path)

func _set_buttons_disabled(value: bool) -> void:
	if back_button:
		back_button.disabled = value
