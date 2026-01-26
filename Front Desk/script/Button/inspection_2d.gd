extends Node2D

@export var mini_id_slot_path: NodePath
@export var mini_permit_slot_path: NodePath

@export var approve_button_path: NodePath
@export var deny_button_path: NodePath

@export var mini_table_layer_path: NodePath
@export var document_layer_path: NodePath

@export var character_spawn_marker_path: NodePath
@export var character_stop_marker_path: NodePath
@export var character_exit_right_marker_path: NodePath

@export var character_scenes: Array[PackedScene]

var _char_index := 0

var current_character: Node2D = null
var _locked := false


func _ready() -> void:
	var approve_btn: BaseButton = get_node(approve_button_path)
	var deny_btn: BaseButton = get_node(deny_button_path)

	approve_btn.pressed.connect(func(): _on_decision_pressed("approve"))
	deny_btn.pressed.connect(func(): _on_decision_pressed("deny"))

	spawn_character()  # ✅ FIRST spawn



func spawn_character() -> void:
	if character_scenes.is_empty():
		push_error("inspection_2d.gd: character_scenes is empty. Add Professor scenes in Inspector.")
		return

	# loop back to start (or remove this if you want it to stop)
	if _char_index >= character_scenes.size():
		_char_index = 0

	current_character = character_scenes[_char_index].instantiate()
	_char_index += 1

	# markers (siblings of character)
	current_character.spawn_marker_path = NodePath("../CharacterSpawn")
	current_character.stop_marker_path = NodePath("../CharacterStop")
	current_character.exit_right_marker_path = NodePath("../CharacterExitRight")

	# mini table + slots (siblings of character)
	current_character.mini_table_layer_path = NodePath("../MiniTableLayer")
	current_character.mini_id_slot_path = NodePath("../MiniSlot_ID")
	current_character.mini_permit_slot_path = NodePath("../MiniSlot_Permit")

	add_child(current_character)





func _on_decision_pressed(decision: String) -> void:
	if _locked:
		return
	_locked = true
	_disable_buttons(true)

	# clear docs
	_clear_layer(get_node(mini_table_layer_path))
	_clear_layer(get_node(document_layer_path))

	# make character exit right + fade
	if current_character and current_character.has_method("exit_right"):
		current_character.exit_right(func():
			current_character = null
			_locked = false
			_disable_buttons(false)
			# later: spawn next character here (spawn_character())
		)
	else:
		_locked = false
		_disable_buttons(false)


func _clear_layer(layer: Node) -> void:
	for c in layer.get_children():
		c.queue_free()


func _disable_buttons(disabled: bool) -> void:
	var approve_btn: BaseButton = get_node(approve_button_path)
	var deny_btn: BaseButton = get_node(deny_button_path)
	approve_btn.disabled = disabled
	deny_btn.disabled = disabled
