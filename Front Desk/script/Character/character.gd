extends Node2D

signal reached_stop
signal play_footstep

enum ExpectedDecision {
	APPROVE,
	DENY,
	TRUE_FORM
}

@export var identity_key: String = ""
@export var forged_enabled: bool = false
@export var forged_mini_doc_scenes: Array[PackedScene] = []

var run_is_forged: bool = false
var _normal_mini_doc_scenes_cache: Array[PackedScene] = []
var _normal_expected_decision_cache: ExpectedDecision = ExpectedDecision.APPROVE
var runtime_mini_doc_scenes: Array[PackedScene] = []

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
@export var is_disguised: bool = false
@export var anomaly_uses_blinds: bool = false
@export var custom_scare_duration: float = -1.0

@export var expected_decision: ExpectedDecision = ExpectedDecision.APPROVE

@export var dialogue_texts: Array[String] = []
@export var dialogue_sides: Array[String] = []
@export var approve_texts: Array[String] = []
@export var approve_sides: Array[String] = []
@export var deny_texts: Array[String] = []
@export var deny_sides: Array[String] = []

@onready var spawn_marker: Marker2D = get_node_or_null(spawn_marker_path)
@onready var stop_marker: Marker2D = get_node_or_null(stop_marker_path)
@onready var exit_left_marker: Marker2D = get_node_or_null(exit_left_marker_path)
@onready var exit_right_marker: Marker2D = get_node_or_null(exit_right_marker_path)

@onready var mini_doc_anchor_1: Node2D = get_node_or_null(mini_doc_anchor_path)
@onready var mini_doc_anchor_2: Node2D = get_node_or_null(mini_doc_anchor2_path)
@onready var mini_table_layer: Node = get_node_or_null(mini_table_layer_path)
@onready var mini_id_slot: Marker2D = get_node_or_null(mini_id_slot_path)
@onready var mini_permit_slot: Marker2D = get_node_or_null(mini_permit_slot_path)

var _exiting := false
var _move_tween: Tween = null
var _idle_tween: Tween = null
var _documents_spawned := false

func apply_run_variant(is_forged_run: bool) -> void:
	if _normal_mini_doc_scenes_cache.is_empty():
		_normal_mini_doc_scenes_cache = mini_doc_scenes.duplicate()
		_normal_expected_decision_cache = expected_decision

	run_is_forged = is_forged_run

	# Always start from the normal set
	runtime_mini_doc_scenes = _normal_mini_doc_scenes_cache.duplicate()

	if run_is_forged:
		if not forged_enabled:
			push_warning("Character '%s' was marked forged, but forged_enabled is false." % name)
			expected_decision = _normal_expected_decision_cache
			run_is_forged = false
			return

		if forged_mini_doc_scenes.size() != 2:
			push_error("Character '%s' forged_mini_doc_scenes must contain exactly 2 entries: ID and Permit." % name)
			expected_decision = _normal_expected_decision_cache
			run_is_forged = false
			return

		for i in range(min(runtime_mini_doc_scenes.size(), forged_mini_doc_scenes.size())):
			if forged_mini_doc_scenes[i] != null:
				runtime_mini_doc_scenes[i] = forged_mini_doc_scenes[i]

		expected_decision = ExpectedDecision.DENY
	else:
		expected_decision = _normal_expected_decision_cache

func _ready() -> void:
	modulate.a = 1.0
	z_index = 1

	if spawn_marker_path.is_empty():
		push_error("Character.gd: spawn_marker_path is empty (set it in inspection_2d.gd BEFORE add_child).")
		return
	if spawn_marker == null:
		push_error("Character.gd: spawn marker not found: " + str(spawn_marker_path))
		return

	if stop_marker_path.is_empty():
		push_error("Character.gd: stop_marker_path is empty.")
		return
	if stop_marker == null:
		push_error("Character.gd: stop marker not found: " + str(stop_marker_path))
		return

	global_position = spawn_marker.global_position
	enter()

func enter() -> void:
	if stop_marker == null:
		push_error("Character.gd: enter() failed because stop_marker is null.")
		return

	_stop_all_tweens()
	emit_signal("play_footstep")

	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", stop_marker.global_position, enter_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	_move_tween.tween_property(self, "global_position:y", stop_marker.global_position.y + 6, 0.08)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	_move_tween.tween_property(self, "global_position:y", stop_marker.global_position.y, 0.10)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	_move_tween.tween_callback(_start_idle)
	_move_tween.tween_callback(func(): reached_stop.emit())

func _start_idle() -> void:
	if _idle_tween and _idle_tween.is_running():
		_idle_tween.kill()

func get_dialogue_messages() -> Array:
	var messages = []
	for i in range(dialogue_texts.size()):
		var side = "left"
		if i < dialogue_sides.size() and dialogue_sides[i] == "right":
			side = "right"
		messages.append({"text": dialogue_texts[i], "side": side})
	return messages

func get_approve_messages() -> Array:
	var messages = []
	for i in range(approve_texts.size()):
		var side = "left"
		if i < approve_sides.size() and approve_sides[i] == "right":
			side = "right"
		messages.append({"text": approve_texts[i], "side": side})
	return messages

func get_deny_messages() -> Array:
	var messages = []
	for i in range(deny_texts.size()):
		var side = "left"
		if i < deny_sides.size() and deny_sides[i] == "right":
			side = "right"
		messages.append({"text": deny_texts[i], "side": side})
	return messages

func exit_right(on_done: Callable = Callable()) -> void:
	_exit_to_marker(
		exit_right_marker,
		"Character.gd: exit_right_marker_path is empty.",
		"Character.gd: exit marker not found: " + str(exit_right_marker_path),
		on_done
	)

func exit_left(on_done: Callable = Callable()) -> void:
	_exit_to_marker(
		exit_left_marker,
		"Character.gd: exit_left_marker_path is empty.",
		"Character.gd: left exit marker not found: " + str(exit_left_marker_path),
		on_done
	)

func _exit_to_marker(marker: Marker2D, empty_error: String, missing_error: String, on_done: Callable = Callable()) -> void:
	if _exiting:
		return
	_exiting = true

	_stop_all_tweens()
	_clear_mini_docs()

	if marker == null:
		if empty_error.contains("exit_right") and exit_right_marker_path.is_empty():
			push_error(empty_error)
		elif empty_error.contains("exit_left") and exit_left_marker_path.is_empty():
			push_error(empty_error)
		else:
			push_error(missing_error)
		_exiting = false
		return

	modulate.a = 1.0
	emit_signal("play_footstep")

	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", marker.global_position, exit_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	_move_tween.tween_callback(func():
		if on_done.is_valid():
			on_done.call()
		queue_free()
	)

func spawn_documents() -> void:
	if not _documents_spawned:
		_spawn_mini_docs()
		_documents_spawned = true

func _spawn_mini_docs() -> void:
	if is_true_form:
		return

	if runtime_mini_doc_scenes.is_empty():
		runtime_mini_doc_scenes = _normal_mini_doc_scenes_cache.duplicate()

	if runtime_mini_doc_scenes.is_empty():
		return

	if mini_doc_anchor_1 == null or mini_doc_anchor_2 == null:
		push_error("Character.gd: mini doc anchors not found. Check mini_doc_anchor_path / mini_doc_anchor2_path.")
		return

	if mini_table_layer == null:
		push_error("Character.gd: mini_table_layer_path not found.")
		return

	_clear_mini_docs()

	if runtime_mini_doc_scenes.size() >= 1 and runtime_mini_doc_scenes[0] != null:
		var mini_1 = runtime_mini_doc_scenes[0].instantiate()
		mini_doc_anchor_1.add_child(mini_1)
		mini_1.position = Vector2.ZERO
		mini_1.table_layer = mini_table_layer
		mini_1.table_slot = mini_id_slot

	if runtime_mini_doc_scenes.size() >= 2 and runtime_mini_doc_scenes[1] != null:
		var mini_2 = runtime_mini_doc_scenes[1].instantiate()
		mini_doc_anchor_2.add_child(mini_2)
		mini_2.position = Vector2.ZERO
		mini_2.table_layer = mini_table_layer
		mini_2.table_slot = mini_permit_slot

func _clear_mini_docs() -> void:
	if mini_doc_anchor_1:
		for child in mini_doc_anchor_1.get_children():
			child.queue_free()

	if mini_doc_anchor_2:
		for child in mini_doc_anchor_2.get_children():
			child.queue_free()

func _stop_all_tweens() -> void:
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

	if _idle_tween and _idle_tween.is_running():
		_idle_tween.kill()

func get_expected_result() -> int:
	if is_true_form:
		return ExpectedDecision.TRUE_FORM

	if is_disguised and anomaly_uses_blinds:
		return ExpectedDecision.TRUE_FORM

	return expected_decision
	
func get_character_id() -> String:
	return identity_key
