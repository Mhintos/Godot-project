extends Area2D

@export var doc_id: String = ""
@export var full_document_scene: PackedScene

@export var table_layer_path: NodePath
@export var table_slot_path: NodePath

@export var bob_height: float = 2.0
@export var bob_time: float = 0.5

enum State { WITH_CHARACTER, ON_TABLE }
var state := State.WITH_CHARACTER

var _moving := false
var _base_y := 0.0
var _bob_tween: Tween


func _ready() -> void:
	_base_y = position.y
	_start_bob()


func _start_bob() -> void:
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()

	_bob_tween = create_tween()
	_bob_tween.set_loops()
	_bob_tween.tween_property(self, "position:y", _base_y - bob_height, bob_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(self, "position:y", _base_y, bob_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)


func send_to_table(table_layer: Node, target_global_pos: Vector2, slide_time: float = 0.35) -> void:
	if _moving:
		return
	_moving = true

	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()

	var start_global := global_position

	get_parent().remove_child(self)
	table_layer.add_child(self)
	global_position = start_global

	var t := create_tween()
	t.tween_property(self, "global_position", target_global_pos, slide_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	t.tween_callback(_finish_to_table)


func _finish_to_table() -> void:
	state = State.ON_TABLE
	_moving = false


func _input_event(viewport, event, shape_idx) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	# FIRST CLICK: slide to table
	if state == State.WITH_CHARACTER:
		var table_layer: Node = get_node(table_layer_path)
		var slot: Node2D = get_node(table_slot_path)
		send_to_table(table_layer, slot.global_position)
		return

	# SECOND CLICK: open full document
	if state == State.ON_TABLE:
		var manager = get_tree().get_first_node_in_group("document_manager")
		if manager:
			manager.open_document(doc_id, full_document_scene)
