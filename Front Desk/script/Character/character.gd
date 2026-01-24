extends Node2D

@export var spawn_marker_path: NodePath
@export var stop_marker_path: NodePath
@export var enter_time: float = 0.6

@export var mini_doc_anchor_path: NodePath
@export var mini_doc_anchor2_path: NodePath
@export var mini_table_layer_path: NodePath
@export var mini_id_slot_path: NodePath
@export var mini_permit_slot_path: NodePath

@export var mini_id_scene: PackedScene
@export var mini_permit_scene: PackedScene


func _ready() -> void:
	var spawn: Marker2D = get_node(spawn_marker_path)
	global_position = spawn.global_position
	enter()


func enter() -> void:
	var stop: Marker2D = get_node(stop_marker_path)

	var t := create_tween()
	t.tween_property(self, "global_position", stop.global_position, enter_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	t.tween_callback(_start_idle)


func _start_idle() -> void:
	_spawn_mini_docs()

	var base_y := global_position.y
	var idle := create_tween()
	idle.set_loops()
	idle.tween_property(self, "global_position:y", base_y - 2, 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	idle.tween_property(self, "global_position:y", base_y, 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)


func _spawn_mini_docs() -> void:
	var anchor_id: Node2D = get_node(mini_doc_anchor_path)
	var anchor_permit: Node2D = get_node(mini_doc_anchor2_path)

	var table_layer: Node = get_node(mini_table_layer_path)
	var id_slot: Marker2D = get_node(mini_id_slot_path)
	var permit_slot: Marker2D = get_node(mini_permit_slot_path)

	# Clear old mini docs
	for child in anchor_id.get_children():
		child.queue_free()
	for child in anchor_permit.get_children():
		child.queue_free()

	# ── ID MINI ───────────────────────────
	var id_mini = mini_id_scene.instantiate()
	anchor_id.add_child(id_mini)
	id_mini.position = Vector2.ZERO

	id_mini.table_layer_path = table_layer.get_path()
	id_mini.table_slot_path = id_slot.get_path()

	# ── PERMIT MINI ───────────────────────
	var permit_mini = mini_permit_scene.instantiate()
	anchor_permit.add_child(permit_mini)
	permit_mini.position = Vector2.ZERO

	permit_mini.table_layer_path = table_layer.get_path()
	permit_mini.table_slot_path = permit_slot.get_path()
