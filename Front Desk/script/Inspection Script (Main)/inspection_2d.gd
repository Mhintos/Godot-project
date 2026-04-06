extends Node2D

@export var scare_meter_path: NodePath
@export var scare_alarm_sfx_path: NodePath

@export var mini_id_slot_path: NodePath
@export var mini_permit_slot_path: NodePath

@export var approve_button_path: NodePath
@export var deny_button_path: NodePath

@export var mini_table_layer_path: NodePath
@export var document_layer_path: NodePath

@export var normal_character_scenes: Array[PackedScene]
@export var forged_character_scenes: Array[PackedScene]
@export var disguised_character_scenes: Array[PackedScene]
@export var true_form_character_scenes: Array[PackedScene]

@export var blood_minitable_path: NodePath
@export var blood_organizer_path: NodePath

@export var jumpscare_sprite_path: NodePath

@export var max_characters_per_shift: int = 4
@export var success_scene_path: String = "res://scene/Success/success.tscn"
@export var game_over_scene_path: String = "res://scene/GameOver/game_over.tscn"

<<<<<<< Updated upstream
=======
@export var warning2_overlay_path: NodePath

@onready var warning2_overlay: TextureRect = null

@onready var dialogue_ui = $DialogueUI/DialogueUI
@export var microphone_button: TextureButton = null

>>>>>>> Stashed changes
@onready var bg_layer_shake: Node = $"BG Layer"
@onready var blinds_layer_shake: Node = $"Blinds Layer"
@onready var character_layer_shake: Node = $"Character Layer"
@onready var documents_shake: Node = $"Documents"
@onready var bloody_ui_shake: Node = $"Bloody UI"
@onready var jumpscare_layer_shake: Node = $"JumpscareLayer"

@onready var scare_meter: AnimatedSprite2D = get_node_or_null(scare_meter_path)
@onready var scare_alarm_sfx: AudioStreamPlayer = get_node_or_null(scare_alarm_sfx_path)

@onready var true_form_timer: Timer = $TrueFormTimer
@onready var blinds_system: Node = get_node_or_null("Blinds Layer/BlindsSystem")

@onready var approve_btn: BaseButton = get_node(approve_button_path)
@onready var deny_btn: BaseButton = get_node(deny_button_path)

@onready var mini_table_layer: Node = get_node(mini_table_layer_path)
@onready var document_layer: Node = get_node(document_layer_path)

@onready var blood_minitable: CanvasItem = get_node_or_null(blood_minitable_path)
@onready var blood_organizer: CanvasItem = get_node_or_null(blood_organizer_path)
@onready var jumpscare_sprite: AnimatedSprite2D = get_node_or_null(jumpscare_sprite_path)

@onready var in_game_music: AudioStreamPlayer = $SFX/InGameMusic
@onready var footstep_sfx: AudioStreamPlayer = $SFX/FootstepSFX
@onready var sliding_paper_sfx: AudioStreamPlayer = $SFX/SlidingPaperSFX
@onready var page_turn_sfx: AudioStreamPlayer = $SFX/PageTurnSFX
@onready var mistake_sfx: AudioStreamPlayer = $SFX/MistakeSFX
@onready var true_form_presence_sfx: AudioStreamPlayer = $SFX/TrueFormPresenceSFX
@onready var screen_distort_sfx: AudioStreamPlayer = $SFX/ScreenDistortSFX
@onready var jumpscare_sfx: AudioStreamPlayer = $SFX/JumpscareSFX

var shift_queue: Array[PackedScene] = []

var _char_index := 0
var current_character: Node2D = null
var _locked := false
var true_form_active := false
var mistake_count := 0
var game_over := false
var processed_characters := 0

var screen_shake_time: float = 0.0
var screen_shake_strength: float = 0.0
var warning2_distortion_timer: float = 0.0
var flicker_time: float = 0.0
var flicker_strength: float = 0.0
var shake_layers: Array[Node] = []
var original_layer_positions := {}

var scare_started := false
var scare_fill_progress := 0.0
var scare_fill_speed_multiplier := 1.0
var scare_warning_stage := 0
var scare_alarm_triggered := false

var current_scare_duration := 30.0

var normal_scare_times := [30.0, 27.0, 24.0, 21.0]
const WARNING2_SPEED_MULTIPLIER := 1.5
const SCARE_ALARM_THRESHOLD := 0.85

var character_dialogue_messages: Array = []
var microphone_used := false
var current_approved_messages: Array = [] 
var current_denied_messages: Array = []    

const DEBUG_LOGS := false

func debug_log(msg) -> void:
	if DEBUG_LOGS:
		print(msg)

func _ready() -> void:
	add_to_group("inspection_controller")

	approve_btn.pressed.connect(func(): _on_decision_pressed("approve"))
	deny_btn.pressed.connect(func(): _on_decision_pressed("deny"))

	if blinds_system:
		blinds_system.blinds_closed_success.connect(_on_blinds_closed_success)
	else:
		push_error("BlindsSystem not found in _ready(). Check node path.")

	jumpscare_sprite.visible = false
	jumpscare_sprite.animation_finished.connect(_on_jumpscare_finished)

	if microphone_button:
		microphone_button.pressed.connect(_on_microphone_pressed)

	shake_layers = [
		bg_layer_shake,
		blinds_layer_shake,
		character_layer_shake,
		documents_shake,
		bloody_ui_shake,
		jumpscare_layer_shake
	]

	for layer in shake_layers:
		if layer == null:
			continue

		if layer is Node2D:
			original_layer_positions[layer] = layer.position
		elif layer is CanvasLayer:
			original_layer_positions[layer] = layer.offset

	reset_run_state()

	screen_shake_time = 0.0
	screen_shake_strength = 0.0
	warning2_distortion_timer = 0.0
	_apply_layer_shake_offset(Vector2.ZERO)

func generate_shift_queue() -> void:
	print("Generating shift queue...")
	print("Normal scenes count: ", normal_character_scenes.size())
	print("Disguised scenes count: ", disguised_character_scenes.size())
	print("True form scenes count: ", true_form_character_scenes.size())
	shift_queue.clear()

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	if normal_character_scenes.is_empty():
		push_error("No normal characters assigned in normal_character_scenes.")
		return

	var normal_pool: Array[PackedScene] = normal_character_scenes.duplicate()
	var disguised_pool: Array[PackedScene] = disguised_character_scenes.duplicate()
	var true_form_pool: Array[PackedScene] = true_form_character_scenes.duplicate()

	normal_pool.shuffle()
	disguised_pool.shuffle()
	true_form_pool.shuffle()

	# First character must always be normal and correct
	var first_character: PackedScene = normal_pool.pop_front()
	shift_queue.append(first_character)

	var remaining_pool: Array[PackedScene] = []

	# Add all remaining normals
	for scene in normal_pool:
		remaining_pool.append(scene)

	# Add all disguised characters
	for scene in disguised_pool:
		remaining_pool.append(scene)

	# Add all true form anomalies
	for scene in true_form_pool:
		remaining_pool.append(scene)

	remaining_pool.shuffle()

	for scene in remaining_pool:
		if shift_queue.size() >= max_characters_per_shift:
			break
		shift_queue.append(scene)

	debug_log("Generated shift queue size: " + str(shift_queue.size()))
	for i in range(shift_queue.size()):
		print("QUEUE[", i, "]: ", shift_queue[i].resource_path)

func spawn_character() -> void:
	print("spawn_character called, shift_queue size: ", shift_queue.size())
	if shift_queue.is_empty():
		push_error("Shift queue is empty. Generate the shift queue first.")
		return

	_lock_gameplay()

	microphone_used = false
	character_dialogue_messages = []

	_cleanup_current_character()
	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	if _char_index >= shift_queue.size():
		debug_log("No more characters left to spawn.")
		return

	current_character = shift_queue[_char_index].instantiate()
	_char_index += 1

	current_scare_duration = get_current_normal_scare_duration()
	reset_scare_meter()

	if _is_disguised_character(current_character):
		current_scare_duration = 8.0
	elif _is_true_form_character(current_character):
		current_scare_duration = 4.0

	if scare_warning_stage >= 2:
		scare_fill_speed_multiplier = WARNING2_SPEED_MULTIPLIER

	current_character.spawn_marker_path = NodePath("../Character Layer/CharacterSpawn")
	current_character.stop_marker_path = NodePath("../Character Layer/CharacterStop")
	current_character.exit_right_marker_path = NodePath("../Character Layer/CharacterExitRight")
	current_character.exit_left_marker_path = NodePath("../Character Layer/CharacterExitLeft")

	current_character.mini_table_layer_path = NodePath("../Documents/MiniTableLayer")
	current_character.mini_id_slot_path = NodePath("../Documents/MiniSlot_ID")
	current_character.mini_permit_slot_path = NodePath("../Documents/MiniSlot_Permit")

	add_child(current_character)

	if current_character.has_signal("play_footstep"):
		current_character.play_footstep.connect(play_footstep_sfx)

	if current_character.has_signal("reached_stop"):
		current_character.reached_stop.connect(_on_character_reached_stop)

func _on_first_mini_doc_interacted() -> void:
	if current_character == null:
		return

	if scare_started:
		return

	# True form has no doc-start trigger; it starts automatically at stop
	if _is_true_form_character(current_character):
		return

	start_scare_meter()

func _on_character_reached_stop() -> void:
	if current_character == null:
		return

	if current_character.has_method("get_dialogue_messages"):
		character_dialogue_messages = current_character.get_dialogue_messages()
	else:
		character_dialogue_messages = []
	_lock_gameplay()

	if microphone_button and character_dialogue_messages.size() > 0:
		microphone_button.visible = true
		var mic_sprite = microphone_button.get_node("MicSprite")
		if mic_sprite:
			mic_sprite.play("hint")
			await mic_sprite.animation_finished
			if mic_sprite.is_visible_in_tree() and mic_sprite.animation == "hint":
				mic_sprite.play("default")
	else:
		_unlock_gameplay()

	# True form anomaly
	if _is_true_form_character(current_character):
		true_form_active = true
		current_scare_duration = 4.0

		approve_btn.disabled = true
		deny_btn.disabled = true

		play_true_form_presence_sfx()
		play_screen_distort_sfx()

		# Start the scare meter automatically for true form
		scare_started = true
		scare_alarm_triggered = false

		debug_log("True form reached stop. 4-second anomaly state started.")
		return

	# Disguised anomaly
	if _is_disguised_character(current_character):
		true_form_active = true
		current_scare_duration = 8.0

		approve_btn.disabled = true
		deny_btn.disabled = true

		# No true form appearance SFX here
		# play_screen_distort_sfx() # optional only if you want visual tension

		debug_log("Disguised reached stop. 8-second anomaly state started.")
		return

func _on_microphone_pressed() -> void:
	var mic_sprite = microphone_button.get_node("MicSprite")
	play_sliding_paper_sfx()
	if mic_sprite:
		mic_sprite.stop()
	if not dialogue_ui or not current_character:
		return
	if microphone_used:
		return
	microphone_used = true

	# Spawn documents (paper sound already played in _on_character_reached_stop)
	if current_character.has_method("spawn_documents"):
		current_character.spawn_documents()

	# Start the initial dialogue
	if character_dialogue_messages.size() > 0:
		if dialogue_ui.conversation_finished.is_connected(_on_dialogue_finished):
				dialogue_ui.conversation_finished.disconnect(_on_dialogue_finished)
		dialogue_ui.conversation_finished.connect(_on_dialogue_finished)
		dialogue_ui.visible = true
		dialogue_ui.start_conversation(character_dialogue_messages)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	if dialogue_ui:
		dialogue_ui.conversation_finished.disconnect(_on_dialogue_finished)
		dialogue_ui.visible = false
	character_dialogue_messages = []
	_unlock_gameplay()

func _on_blinds_closed_success() -> void:
	if not true_form_active:
		return

	if current_character == null:
		return

	if _is_true_form_character(current_character) or _is_disguised_character(current_character):
		true_form_timer.stop()
		debug_log("Anomaly blocked successfully with blinds.")
		_reject_true_form()

func _reject_true_form() -> void:
	true_form_timer.stop()
	true_form_active = false
	reset_scare_meter()

	approve_btn.disabled = false
	deny_btn.disabled = false

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	if current_character and is_instance_valid(current_character):
		if current_character.has_method("exit_left"):
			current_character.call("exit_left", func():
				current_character = null
				if blinds_system:
					blinds_system.force_open()
				_finish_character_and_continue()
			)
			return

	current_character = null
	if blinds_system:
		blinds_system.force_open()
	_finish_character_and_continue()

func _on_true_form_timer_timeout() -> void:
	if not true_form_active:
		return

	if blinds_system and blinds_system.is_closed:
		debug_log("Anomaly blocked in time.")
		_reject_true_form()
	else:
		true_form_active = false
		debug_log("Time ran out - jumpscare")
		trigger_jumpscare()

func trigger_jumpscare() -> void:
	if game_over:
		return

	game_over = true
	true_form_active = false
	_lock_gameplay()
	true_form_timer.stop()
	reset_scare_meter()
	approve_btn.disabled = false
	deny_btn.disabled = false

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	_cleanup_current_character()

	if blinds_system:
		blinds_system.force_open()

	start_screen_shake(0.2, 16.0)
	play_jumpscare_sfx()

	jumpscare_sprite.visible = true

	if jumpscare_sprite.sprite_frames and jumpscare_sprite.sprite_frames.has_animation("play"):
		jumpscare_sprite.play("play")
	else:
		push_error("JumpscareSprite has no animation named 'play'.")

	debug_log("JUMPSCARE START")

func _on_jumpscare_finished() -> void:
	jumpscare_sprite.stop()
	debug_log("JUMPSCARE FINISHED")
	get_tree().change_scene_to_file(game_over_scene_path)

func _on_decision_pressed(decision: String) -> void:
	if _locked or game_over:
		return

	# Prevent decision buttons from resolving anomalies that should use blinds only
	if true_form_active:
		return

	_lock_gameplay()
	true_form_timer.stop()
	reset_scare_meter()

	if current_character == null:
		true_form_active = false
		if blinds_system:
			blinds_system.force_open()
		_unlock_gameplay()
		spawn_character()
		return

	var is_correct := _is_decision_correct(decision)

	if not is_correct:
		_register_mistake()

	if game_over or current_character == null or not is_instance_valid(current_character):
		return

	true_form_active = false

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)
<<<<<<< Updated upstream
=======
	
	var dialogue_messages: Array = []
	if decision == "approve":
		if current_character.has_method("get_approve_messages"):
			dialogue_messages = current_character.get_approve_messages()
	else: # deny
		if current_character.has_method("get_deny_messages"):
			dialogue_messages = current_character.get_deny_messages()
	
	if dialogue_ui and dialogue_messages.size() > 0:
		# Temporarily disconnect any previous connection
		if dialogue_ui.conversation_finished.is_connected(_on_decision_dialogue_finished):
			dialogue_ui.conversation_finished.disconnect(_on_decision_dialogue_finished)
	#	 Connect to a function that will proceed with exit
		dialogue_ui.conversation_finished.connect(_on_decision_dialogue_finished.bind(decision))
		dialogue_ui.visible = true
		dialogue_ui.start_conversation(dialogue_messages)
		# The rest of the exit will be triggered after the dialogue finishes
	else:
		_finish_decision(decision)
	
	var doc_manager = get_tree().get_first_node_in_group("document_manager")
	if doc_manager and doc_manager.has_method("clear_opened_docs"):
		doc_manager.clear_opened_docs()
>>>>>>> Stashed changes

func _on_decision_dialogue_finished(decision: String) -> void:
	if dialogue_ui:
		dialogue_ui.conversation_finished.disconnect(_on_decision_dialogue_finished)
		dialogue_ui.visible = false
	_finish_decision(decision)

func _finish_decision(decision: String) -> void:
	var exit_method := "exit_right" if decision == "approve" else "exit_left"
	if current_character and current_character.has_method(exit_method):
		current_character.call(exit_method, func():
			current_character = null
			if blinds_system:
				blinds_system.force_open()
			if not game_over:
				_finish_character_and_continue()
		)
	else:
		current_character = null
		if blinds_system:
			blinds_system.force_open()
		if not game_over:
			_finish_character_and_continue()

func _is_decision_correct(decision: String) -> bool:
	if current_character == null:
		return false

	var expected = current_character.get_expected_result()

	match expected:
		current_character.ExpectedDecision.APPROVE:
			return decision == "approve"
		current_character.ExpectedDecision.DENY:
			return decision == "deny"
		current_character.ExpectedDecision.TRUE_FORM:
			return false

	return false

func _is_true_form_character(character: Node) -> bool:
	if character == null:
		return false
	return bool(character.get("is_true_form"))

func _is_disguised_character(character: Node) -> bool:
	if character == null:
		return false
	return bool(character.get("is_disguised"))

func _register_mistake() -> void:
	mistake_count += 1
	play_mistake_sfx()
	debug_log("Mistake count: " + str(mistake_count))
	advance_warning_state_from_mistake()

func _show_bloody_ui() -> void:
	blood_minitable.visible = true
	blood_organizer.visible = true
	debug_log("SHOW BLOODY UI WARNING")

func _clear_layer(layer: Node) -> void:
	if layer == null or layer.get_child_count() == 0:
		return

	for child in layer.get_children():
		child.queue_free()

func _cleanup_current_character() -> void:
	if current_character and is_instance_valid(current_character):
		current_character.queue_free()
	current_character = null

func _disable_buttons(disabled: bool) -> void:
	approve_btn.disabled = disabled
	deny_btn.disabled = disabled

func _lock_gameplay() -> void:
	_locked = true
	_disable_buttons(true)

func _unlock_gameplay() -> void:
	_locked = false
	_disable_buttons(false)

func reset_run_state() -> void:
	print("reset_run_state called")
	if blood_minitable:
		blood_minitable.visible = false

	if blood_organizer:
		blood_organizer.visible = false

	if jumpscare_sprite:
		jumpscare_sprite.visible = false
		jumpscare_sprite.stop()
	reset_scare_meter()
	scare_warning_stage = 0
	current_scare_duration = 30.0
	warning2_distortion_timer = 0.0

	screen_shake_time = 0.0
	screen_shake_strength = 0.0

	mistake_count = 0
	game_over = false
	true_form_active = false
	_locked = false
	processed_characters = 0
	_char_index = 0
	shift_queue.clear()

	blood_minitable.visible = false
	blood_organizer.visible = false
	jumpscare_sprite.visible = false
	jumpscare_sprite.stop()

	true_form_timer.stop()
	_disable_buttons(false)

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)
	_cleanup_current_character()

	_apply_layer_shake_offset(Vector2.ZERO)

	if blinds_system:
		blinds_system.force_open()
	else:
		push_error("BlindsSystem not found. Check node path.")

	generate_shift_queue()
	print("Shift queue size after generation: ", shift_queue.size())
	spawn_character()

func _finish_character_and_continue() -> void:
	microphone_used = false
	processed_characters += 1
	debug_log("Processed characters: " + str(processed_characters) + "/" + str(max_characters_per_shift))

	if processed_characters >= max_characters_per_shift:
		get_tree().change_scene_to_file(success_scene_path)
		return

	reset_scare_meter()
	approve_btn.disabled = false
	deny_btn.disabled = false

	_unlock_gameplay()
	spawn_character()

func play_footstep_sfx() -> void:
	if footstep_sfx.stream:
		footstep_sfx.play()

func play_sliding_paper_sfx() -> void:
	if sliding_paper_sfx.stream:
		sliding_paper_sfx.play()

func play_page_turn_sfx() -> void:
	if page_turn_sfx.stream and not page_turn_sfx.playing:
		page_turn_sfx.play()

func play_mistake_sfx() -> void:
	if mistake_sfx.stream and not mistake_sfx.playing:
		mistake_sfx.play()

func play_true_form_presence_sfx() -> void:
	if true_form_presence_sfx.stream and not true_form_presence_sfx.playing:
		true_form_presence_sfx.play()

func play_screen_distort_sfx() -> void:
	if screen_distort_sfx.stream and not screen_distort_sfx.playing:
		screen_distort_sfx.play()

func play_jumpscare_sfx() -> void:
	if jumpscare_sfx.stream and not jumpscare_sfx.playing:
		jumpscare_sfx.play()

func start_scare_meter() -> void:
	if scare_started:
		return

	if current_character == null:
		return

	scare_started = true
	scare_alarm_triggered = false
	debug_log("Scare meter started.")

func reset_scare_meter() -> void:
	scare_started = false
	scare_fill_progress = 0.0
	scare_alarm_triggered = false
	screen_shake_time = 0.0
	screen_shake_strength = 0.0

	if scare_warning_stage >= 2:
		scare_fill_speed_multiplier = WARNING2_SPEED_MULTIPLIER
	else:
		scare_fill_speed_multiplier = 1.0

	_apply_layer_shake_offset(Vector2.ZERO)

	if scare_meter:
		scare_meter.stop()
		scare_meter.frame = 0

func get_current_normal_scare_duration() -> float:
	var index: int = clamp(processed_characters, 0, normal_scare_times.size() - 1)
	return normal_scare_times[index]

func update_scare_meter_visual() -> void:
	if scare_meter == null:
		return

	var clamped_progress: float = clamp(scare_fill_progress, 0.0, 1.0)
	var frame: int = int(floor(clamped_progress * 10.0))
	frame = clamp(frame, 0, 10)
	scare_meter.frame = frame

func process_scare_meter(delta: float) -> void:
	if not scare_started:
		return

	if game_over:
		return

	if current_character == null:
		return

	if current_scare_duration <= 0.0:
		return

	var fill_per_second := 1.0 / current_scare_duration
	scare_fill_progress += fill_per_second * scare_fill_speed_multiplier * delta

	update_scare_meter_visual()

	if scare_fill_progress >= SCARE_ALARM_THRESHOLD and not scare_alarm_triggered:
		scare_alarm_triggered = true
		play_scare_alarm_sfx()

		var alarm_strength: float = lerp(3.0, 7.0, scare_fill_progress)
		start_screen_shake(0.15, alarm_strength)
		start_flicker(0.08, 0.10)

	if scare_fill_progress >= 1.0:
		scare_fill_progress = 0.0
		scare_alarm_triggered = false

		# True form and disguised fail when their bar fully fills
		if _is_true_form_character(current_character) or _is_disguised_character(current_character):
			trigger_jumpscare()
			return

		advance_warning_state_from_meter()

func advance_warning_state_from_meter() -> void:
	scare_warning_stage += 1
	play_mistake_sfx()
	debug_log("Scare warning stage from meter: " + str(scare_warning_stage))

	if scare_warning_stage == 1:
		_show_bloody_ui()

	elif scare_warning_stage == 2:
		scare_fill_speed_multiplier = WARNING2_SPEED_MULTIPLIER
		warning2_distortion_timer = randf_range(2.4, 3.4)
		play_screen_distort_sfx()
		start_screen_shake(0.25, 8.0)
		start_flicker(0.10, 0.15)

	elif scare_warning_stage >= 3:
		trigger_jumpscare()

func advance_warning_state_from_mistake() -> void:
	scare_warning_stage += 1
	debug_log("Scare warning stage from mistake: " + str(scare_warning_stage))

	if scare_warning_stage == 1:
		_show_bloody_ui()

	elif scare_warning_stage == 2:
		scare_fill_speed_multiplier = WARNING2_SPEED_MULTIPLIER
		warning2_distortion_timer = randf_range(2.4, 3.4)
		play_screen_distort_sfx()
		start_screen_shake(0.25, 8.0)
		start_flicker(0.10, 0.15)

	elif scare_warning_stage >= 3:
		trigger_jumpscare()

func play_scare_alarm_sfx() -> void:
	if scare_alarm_sfx and scare_alarm_sfx.stream:
		if scare_alarm_sfx.playing:
			scare_alarm_sfx.stop()
		scare_alarm_sfx.play()

func _process(delta: float) -> void:
	process_scare_meter(delta)

	if screen_shake_time > 0.0:
		screen_shake_time -= delta

		var offset := Vector2(
			randf_range(-screen_shake_strength, screen_shake_strength),
			randf_range(-screen_shake_strength, screen_shake_strength)
		)

		_apply_layer_shake_offset(offset)

		if screen_shake_time <= 0.0:
			_apply_layer_shake_offset(Vector2.ZERO)

	if flicker_time > 0.0:
		flicker_time -= delta
		_apply_flicker()
	else:
		_reset_flicker()

	if scare_warning_stage >= 2 and not game_over:
		warning2_distortion_timer -= delta

		if warning2_distortion_timer <= 0.0:
			warning2_distortion_timer = randf_range(2.4, 3.4)

			start_screen_shake(randf_range(0.18, 0.30), 8.0)
			play_screen_distort_sfx()
			start_flicker(0.10, 0.15)
	else:
		warning2_distortion_timer = 0.0

func _apply_layer_shake_offset(offset: Vector2) -> void:
	for layer in shake_layers:
		if layer == null:
			continue

		if not original_layer_positions.has(layer):
			continue

		var base_offset = original_layer_positions[layer]

		if layer is Node2D:
			layer.position = base_offset + offset
		elif layer is CanvasLayer:
			layer.offset = base_offset + offset

func start_screen_shake(duration: float = 0.25, strength: float = 6.0) -> void:
	if game_over:
		return

	screen_shake_time = duration
	screen_shake_strength = strength

func start_flicker(duration: float = 0.12, strength: float = 0.18) -> void:
	flicker_time = duration
	flicker_strength = strength

func _apply_flicker() -> void:
	var brightness := randf_range(1.0 - flicker_strength, 1.0 + flicker_strength)
	var tint := Color(brightness, brightness, brightness, 1.0)

	if bg_layer_shake is CanvasItem:
		bg_layer_shake.modulate = tint

	if character_layer_shake is CanvasItem:
		character_layer_shake.modulate = tint

	if documents_shake is CanvasItem:
		documents_shake.modulate = tint

func _reset_flicker() -> void:
	if bg_layer_shake is CanvasItem:
		bg_layer_shake.modulate = Color.WHITE

	if character_layer_shake is CanvasItem:
		character_layer_shake.modulate = Color.WHITE

	if documents_shake is CanvasItem:
		documents_shake.modulate = Color.WHITE
		
func _character_uses_blinds(character: Node) -> bool:
	if character == null:
		return false
	return bool(character.get("anomaly_uses_blinds"))

func _get_character_anomaly_duration(character: Node) -> float:
	if character == null:
		return 0.0

	var custom_duration = character.get("custom_scare_duration")
	if typeof(custom_duration) in [TYPE_FLOAT, TYPE_INT] and float(custom_duration) > 0.0:
		return float(custom_duration)

	if _is_true_form_character(character):
		return 4.0

	if _is_disguised_character(character):
		return 8.0

	return 0.0
	
