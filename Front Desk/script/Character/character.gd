extends Node2D

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

@export var mini_id_scene: PackedScene
@export var mini_permit_scene: PackedScene

var _exiting := false
var _idle_tween: Tween = null


func _ready() -> void:
	modulate.a = 1.0

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



func _start_idle() -> void:
	print("START IDLE")
	_spawn_mini_docs()

	# if idle tween already exists, kill it
	if _idle_tween and _idle_tween.is_running():
		_idle_tween.kill()

	var base_y := global_position.y
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	_idle_tween.tween_property(self, "global_position:y", base_y - 2, 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "global_position:y", base_y, 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)


func exit_right(on_done: Callable = Callable()) -> void:
	if _exiting:
		return
	_exiting = true

	# stop idle so it doesn't fight the exit movement
	if _idle_tween and _idle_tween.is_running():
		_idle_tween.kill()

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
	t.set_parallel(true)

	t.tween_property(self, "global_position", exit_marker.global_position, exit_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	t.tween_property(self, "modulate:a", 0.0, exit_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	t.set_parallel(false)
	t.tween_callback(func():
		if on_done.is_valid():
			on_done.call()
		queue_free()
	)

func exit_left(on_done: Callable = Callable()) -> void:
	if _exiting:
		return
	_exiting = true

	var exit_marker: Marker2D = get_node(exit_left_marker_path)

	# no fade by default for deny (feels snappy)
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
	print("mini_id_scene:", mini_id_scene)
	print("mini_permit_scene:", mini_permit_scene)
	print("anchor paths:", mini_doc_anchor_path, mini_doc_anchor2_path)

	# ---- Anchors guard (these are usually inside the character scene) ----
	var anchor_id := get_node_or_null(mini_doc_anchor_path) as Node2D
	var anchor_permit := get_node_or_null(mini_doc_anchor2_path) as Node2D
	if anchor_id == null or anchor_permit == null:
		push_error("Character.gd: mini doc anchors not found. Check mini_doc_anchor_path / mini_doc_anchor2_path.")
		return

	# ---- Table/slots guard (these are usually in the main scene) ----
	var table_layer := get_node_or_null(mini_table_layer_path)
	var id_slot := get_node_or_null(mini_id_slot_path) as Marker2D
	var permit_slot := get_node_or_null(mini_permit_slot_path) as Marker2D
	if table_layer == null or id_slot == null or permit_slot == null:
		push_error("Character.gd: table_layer or slots not found. Check mini_table_layer_path / slot paths.")
		return

	# Clear old mini docs
	for child in anchor_id.get_children():
		child.queue_free()
	for child in anchor_permit.get_children():
		child.queue_free()

# ── ID MINI ───────────────────────────
	var id_mini = mini_id_scene.instantiate()
	anchor_id.add_child(id_mini)

# anchor-based placement
	id_mini.position = Vector2.ZERO

	id_mini.table_layer_path = table_layer.get_path()
	id_mini.table_slot_path = id_slot.get_path()


# ── PERMIT MINI ───────────────────────
	var permit_mini = mini_permit_scene.instantiate()
	anchor_permit.add_child(permit_mini)

# anchor-based placement
	permit_mini.position = Vector2.ZERO

	permit_mini.table_layer_path = table_layer.get_path()
	permit_mini.table_slot_path = permit_slot.get_path()
