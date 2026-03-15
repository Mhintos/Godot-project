extends Node2D
signal reached_stop

@export var exit_left_marker_path: NodePath
@export var spawn_marker_path: NodePath
@export var stop_marker_path: NodePath
@export var exit_right_marker_path: NodePath

@export var enter_time: float = 0.6
@export var exit_time: float = 0.6

@export var mini_doc_anchor_path: NodePath
@export var mini_doc_anchor2_path: NodePath
@export var mini_table_layer_path: NodePath
@export var mini_id_slot_path: NodePath
@export var mini_permit_slot_path: NodePath

@export var mini_doc_scenes: Array[PackedScene] = []
@export var is_true_form: bool = false

var _exiting := false
var _idle_tween: Tween = null


func _ready() -> void:
	modulate.a = 1.0
	z_index = 1

	# ---- Spawn marker guard ----
	if spawn_marker_path.is_empty():
		push_error("Character.gd: spawn_marker_path is empty (set it in inspection_2d.gd BEFORE add_child).")
		return
	var spawn := get_node_or_null(spawn_marker_path) as Marker2D
	if spawn == null:
		push_error("Character.gd: spawn marker not found: " + str(spawn_marker_path))
		return

	# ---- Stop marker guard ----
	if stop_marker_path.is_empty():
		push_error("Character.gd: stop_marker_path is empty.")
		return
	var stop := get_node_or_null(stop_marker_path) as Marker2D
	if stop == null:
		push_error("Character.gd: stop marker not found: " + str(stop_marker_path))
		return

	# Set initial position then enter using the stop marker we already resolved
	global_position = spawn.global_position
	enter()


func enter() -> void:
	var stop: Marker2D = get_node(stop_marker_path)

	var t := create_tween()
	t.tween_property(self, "global_position", stop.global_position, enter_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# tiny settle bounce (optional polish)
	t.tween_property(self, "global_position:y", stop.global_position.y + 6, 0.08)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "global_position:y", stop.global_position.y, 0.10)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	t.tween_callback(_start_idle)
	t.tween_callback(func(): emit_signal("reached_stop"))


func _start_idle() -> void:
	print("START IDLE")
	_spawn_mini_docs()

	if _idle_tween and _idle_tween.is_running():
		_idle_tween.kill()

func _clear_mini_docs() -> void:
	var anchor_id := get_node_or_null(mini_doc_anchor_path) as Node2D
	var anchor_permit := get_node_or_null(mini_doc_anchor2_path) as Node2D

	if anchor_id:
		for child in anchor_id.get_children():
			child.queue_free()

	if anchor_permit:
		for child in anchor_permit.get_children():
			child.queue_free()


func exit_right(on_done: Callable = Callable()) -> void:
	if _exiting:
		return
	_exiting = true

	# stop idle so it doesn't fight the exit movement
	if _idle_tween and _idle_tween.is_running():
		_idle_tween.kill()

	# remove hovering mini docs before exiting
	_clear_mini_docs()

	# ---- Exit marker guard ----
	if exit_right_marker_path.is_empty():
		push_error("Character.gd: exit_right_marker_path is empty.")
		_exiting = false
		return
	var exit_marker := get_node_or_null(exit_right_marker_path) as Marker2D
	if exit_marker == null:
		push_error("Character.gd: exit marker not found: " + str(exit_right_marker_path))
		_exiting = false
		return

	modulate.a = 1.0

	var t := create_tween()
	t.tween_property(self, "global_position", exit_marker.global_position, exit_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	t.tween_callback(func():
		if on_done.is_valid():
			on_done.call()
		queue_free()
	)


func exit_left(on_done: Callable = Callable()) -> void:
	if _exiting:
		return
	_exiting = true

	if _idle_tween and _idle_tween.is_running():
		_idle_tween.kill()

	_clear_mini_docs()

	if exit_left_marker_path.is_empty():
		push_error("Character.gd: exit_left_marker_path is empty.")
		_exiting = false
		return

	var exit_marker := get_node_or_null(exit_left_marker_path) as Marker2D
	if exit_marker == null:
		push_error("Character.gd: left exit marker not found: " + str(exit_left_marker_path))
		_exiting = false
		return

	modulate.a = 1.0

	var t := create_tween()
	t.tween_property(self, "global_position", exit_marker.global_position, exit_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	t.tween_callback(func():
		if on_done.is_valid():
			on_done.call()
		queue_free()
	)


func _spawn_mini_docs() -> void:
	print("Spawning minis...")
	print("mini_doc_scenes:", mini_doc_scenes)

	if is_true_form:
		print("True form detected. No mini docs will spawn.")
		return

	if mini_doc_scenes.is_empty():
		print("No mini documents assigned.")
		return

	var anchor_1 := get_node_or_null(mini_doc_anchor_path) as Node2D
	var anchor_2 := get_node_or_null(mini_doc_anchor2_path) as Node2D
	if anchor_1 == null or anchor_2 == null:
		push_error("Character.gd: mini doc anchors not found. Check mini_doc_anchor_path / mini_doc_anchor2_path.")
		return

	var table_layer := get_node_or_null(mini_table_layer_path)
	var slot_1 := get_node_or_null(mini_id_slot_path) as Marker2D
	var slot_2 := get_node_or_null(mini_permit_slot_path) as Marker2D
	if table_layer == null:
		push_error("Character.gd: mini_table_layer_path not found.")
		return

	for child in anchor_1.get_children():
		child.queue_free()

	for child in anchor_2.get_children():
		child.queue_free()

	if mini_doc_scenes.size() >= 1 and mini_doc_scenes[0] != null:
		var mini_1 = mini_doc_scenes[0].instantiate()
		anchor_1.add_child(mini_1)
		mini_1.position = Vector2.ZERO
		mini_1.table_layer_path = table_layer.get_path()

		if slot_1 != null:
			mini_1.table_slot_path = slot_1.get_path()

	if mini_doc_scenes.size() >= 2 and mini_doc_scenes[1] != null:
		var mini_2 = mini_doc_scenes[1].instantiate()
		anchor_2.add_child(mini_2)
		mini_2.position = Vector2.ZERO
		mini_2.table_layer_path = table_layer.get_path()

		if slot_2 != null:
			mini_2.table_slot_path = slot_2.get_path()
