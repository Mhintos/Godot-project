extends Node2D

@export var next_scene_path: String = "res://scene/Endings/ending_story.tscn"

@export var processed_value_path: NodePath
@export var mistakes_value_path: NodePath
@export var forged_missed_value_path: NodePath
@export var disguised_stopped_value_path: NodePath
@export var true_forms_stopped_value_path: NodePath
@export var next_button_path: NodePath

@onready var processed_value: Label = get_node_or_null(processed_value_path)
@onready var mistakes_value: Label = get_node_or_null(mistakes_value_path)
@onready var forged_missed_value: Label = get_node_or_null(forged_missed_value_path)
@onready var disguised_stopped_value: Label = get_node_or_null(disguised_stopped_value_path)
@onready var true_forms_stopped_value: Label = get_node_or_null(true_forms_stopped_value_path)
@onready var next_button: TextureButton = get_node_or_null(next_button_path)

func _ready() -> void:
	if processed_value == null:
		push_error("ProcessedValue node not found.")
		return

	if mistakes_value == null:
		push_error("MistakesValue node not found.")
		return

	if forged_missed_value == null:
		push_error("ForgedMissedValue node not found.")
		return

	if disguised_stopped_value == null:
		push_error("DisguisedStoppedValue node not found.")
		return

	if true_forms_stopped_value == null:
		push_error("TrueFormsStoppedValue node not found.")
		return

	if next_button == null:
		push_error("NextButton node not found.")
		return

	processed_value.text = str(GameResult.total_characters_processed)
	mistakes_value.text = str(GameResult.mistakes_made)
	forged_missed_value.text = str(GameResult.forged_documents_missed)
	disguised_stopped_value.text = str(GameResult.disguised_anomalies_stopped)
	true_forms_stopped_value.text = str(GameResult.true_forms_stopped)

	if not next_button.pressed.is_connected(_on_next_button_pressed):
		next_button.pressed.connect(_on_next_button_pressed)

	if not next_button.mouse_entered.is_connected(_on_next_button_mouse_entered):
		next_button.mouse_entered.connect(_on_next_button_mouse_entered)

	MenuMusic.play_ending_flow_music()

func _on_next_button_pressed() -> void:
	UISFXManager.play_click()
	get_tree().change_scene_to_file(next_scene_path)

func _on_next_button_mouse_entered() -> void:
	UISFXManager.play_hover()
