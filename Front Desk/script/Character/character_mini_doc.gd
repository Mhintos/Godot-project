extends Area2D

@export var doc_id: String = ""
@export var full_document_scene: PackedScene

var table_layer: Node = null
var table_slot: Node2D = null

@export var bob_height: float = 2.0
@export var bob_time: float = 0.5

enum State {
	WITH_CHARACTER,
	ON_TABLE
}

var state := State.WITH_CHARACTER

var _moving := false
var _base_y := 0.0
var _bob_tween: Tween = null
var _move_tween: Tween = null

var inspection_controller: Node = null
var document_manager: Node = null

var can_interact := true

func _ready() -> void:
	add_to_group("mini_docs")
	if not can_interact:
		return
	inspection_controller = get_tree().get_first_node_in_group("inspection_controller")
	document_manager = get_tree().get_first_node_in_group("document_manager")

	z_index = 100
	_base_y = position.y
	_start_bob()

func _start_bob() -> void:
	_stop_bob_tween()

	_bob_tween = create_tween()
	_bob_tween.set_loops()
	_bob_tween.tween_property(self, "position:y", _base_y - bob_height, bob_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(self, "position:y", _base_y, bob_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func send_to_table(target_layer: Node, target_global_pos: Vector2, slide_time: float = 0.35) -> void:
	if _moving:
		return

	if target_layer == null:
		push_error("character_mini_doc.gd: target table layer is null.")
		return

	_moving = true
	_stop_all_tweens()

	var inspection = inspection_controller
	if inspection and inspection.has_method("play_sliding_paper_sfx"):
		inspection.play_sliding_paper_sfx()

	var start_global := global_position
	var old_parent := get_parent()

	if old_parent:
		old_parent.remove_child(self)

	target_layer.add_child(self)
	global_position = start_global

	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", target_global_pos, slide_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_move_tween.tween_callback(_finish_to_table)

func _finish_to_table() -> void:
	state = State.ON_TABLE
	_moving = false
	_move_tween = null

func set_interactable(value: bool) -> void: 
	can_interact = value
	input_pickable = value

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().call_group("inspection_controller", "_on_first_mini_doc_interacted")

	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	if _moving:
		return

	var inspection = inspection_controller

	if state == State.WITH_CHARACTER:
		if table_layer == null:
			push_error("character_mini_doc.gd: table_layer not assigned.")
			return

		if table_slot == null:
			push_error("character_mini_doc.gd: table_slot not assigned.")
			return

		if inspection and inspection.has_method("start_scare_meter"):
			inspection.start_scare_meter()

		send_to_table(table_layer, table_slot.global_position)
		return

	if state == State.ON_TABLE:
		if full_document_scene == null:
			push_error("character_mini_doc.gd: full_document_scene is null for doc_id: " + doc_id)
			return

		if inspection and inspection.has_method("play_sliding_paper_sfx"):
			inspection.play_sliding_paper_sfx()

		var manager: Node = document_manager
		if manager and manager.has_method("open_document"):
			manager.open_document(doc_id, full_document_scene)
		else:
			push_error("character_mini_doc.gd: document_manager not found or missing open_document().")

func _stop_bob_tween() -> void:
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()
	_bob_tween = null

func _stop_move_tween() -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = null

func _stop_all_tweens() -> void:
	_stop_bob_tween()
	_stop_move_tween()

func _exit_tree() -> void:
	_stop_all_tweens()
