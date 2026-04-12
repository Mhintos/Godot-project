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
@export var disguised_character_scenes: Array[PackedScene]
@export var true_form_character_scenes: Array[PackedScene]

@export var blood_minitable_path: NodePath
@export var blood_organizer_path: NodePath

@export var jumpscare_sprite_path: NodePath

@export var max_characters_per_shift: int = 10
@export var success_scene_path: String = "res://scene/Success/success.tscn"
@export var game_over_scene_path: String = "res://scene/GameOver/game_over.tscn"

@export var warning2_overlay_path: NodePath

@export var bloodier_minitable_path: NodePath
@export var bloodier_organizer_path: NodePath

@export var meredith_jumpscare_sprite_path: NodePath

@export var microphone_button: TextureButton = null
@onready var dialogue_ui = $DialogueLayer/DialogueUI

@onready var bloodier_minitable: CanvasItem = get_node_or_null(bloodier_minitable_path)
@onready var bloodier_organizer: CanvasItem = get_node_or_null(bloodier_organizer_path)
@onready var meredith_jumpscare_sprite: AnimatedSprite2D = get_node_or_null(meredith_jumpscare_sprite_path)
@onready var warning2_overlay: TextureRect = get_node_or_null(warning2_overlay_path)

@onready var bg_layer_shake: Node = $"BG Layer"
@onready var table_layer_shake: Node = $"BG Layer/Table Layer"
@onready var uilayer_shake: Node = $"BG Layer/Table Layer/UILayer"
@onready var blinds_layer_shake: Node = $"Blinds Layer"
@onready var character_layer_shake: Node = $"Character Layer"
@onready var documents_shake: Node = $"Documents"
@onready var bloody_ui_shake: Node = $"Bloody UI"
@onready var jumpscare_layer_shake: Node = $"JumpscareLayer"
@onready var microphone_layer_shake: Node = $MicrophoneLayer
@onready var dialogueui_layer_shake: Node = $DialogueLayer

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

@onready var alarm_sfx: AudioStreamPlayer = $"Screen Damage Overlay/AlarmSFX"
@onready var blood_damage_sfx: AudioStreamPlayer = $"Screen Damage Overlay/BloodDamageSFX"
@onready var approve_button_sfx: AudioStreamPlayer = $"Screen Damage Overlay/ApproveButtonSFX"
@onready var deny_button_sfx: AudioStreamPlayer = $"Screen Damage Overlay/DenyButtonSFX"
@onready var hover_sfx: AudioStreamPlayer = $"Screen Damage Overlay/HoverSFX"
@onready var click_sfx: AudioStreamPlayer = $"Screen Damage Overlay/ClickSFX"
@onready var lever_sfx: AudioStreamPlayer = $"Screen Damage Overlay/LeverSFX"
@onready var blinds_up_sfx: AudioStreamPlayer = $"Screen Damage Overlay/BlindsUpSFX"
@onready var blinds_down_sfx: AudioStreamPlayer = $"Screen Damage Overlay/BlindsDownSFX"
@onready var scare_meter_sfx: AudioStreamPlayer = $"Screen Damage Overlay/ScareMeterSFX"
@onready var mic_press_sfx: AudioStreamPlayer = $SFX/MicPressSFX
@onready var player_dialogue_sfx: AudioStreamPlayer = $SFX/PlayerDialogueSFX
@onready var character_dialogue_sfx: AudioStreamPlayer = $SFX/CharacterDialogueSFX
@onready var true_form_dialogue_sfx: AudioStreamPlayer = $SFX/TrueFormDialogueSFX


var active_jumpscare_sprite: AnimatedSprite2D = null

const NORMALS_PER_RUN := 6
const DISGUISED_PER_RUN := 2
const TRUE_FORMS_PER_RUN := 2

const WARNING2_SPEED_MULTIPLIER := 1.5
const DEBUG_LOGS := false

var warning2_elapsed_time: float = 0.0
var warning2_burst_interval: float = 3.0

var shift_queue: Array = []

var warning2_overlay_motion_time: float = 0.0
var warning2_overlay_base_alpha: float = 0.62
var warning2_overlay_pulse_speed: float = 0.75

var warning2_overlay_drift_x: float = 4.0
var warning2_overlay_drift_y: float = 2.0
var warning2_overlay_jitter_strength: float = 0.35
var warning2_overlay_flicker_strength: float = 0.08
var warning2_overlay_base_position: Vector2 = Vector2.ZERO

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
var warning2_shake_timer: float = 0.0

var scare_started := false
var scare_fill_progress := 0.0
var scare_fill_speed_multiplier := 1.0
var scare_warning_stage := 0
var scare_alarm_triggered := false

var current_scare_duration := 30.0
var normal_scare_times := [30.0, 27.0, 24.0, 21.0]

var document_manager: Node = null
var current_shake_offset: Vector2 = Vector2.ZERO

var dialogue_finished_for_character := false

var current_approved_messages: Array = []
var current_denied_messages: Array = []
var character_dialogue_messages: Array = []
var microphone_used := false

<<<<<<< Updated upstream
=======


const DISABLED_BUTTON_SFX_STREAM := preload("res://sfx/General Sounds/Error.wav")

var disabled_button_sfx_player: AudioStreamPlayer = null

const DISABLED_BUTTON_SFX_COOLDOWN := 0.8
var disabled_button_sfx_cooldown: float = 0.0

const LEFT_DIALOGUE_SOUND = preload("res://sfx/Characters Dialogue/Character_Player Response.wav")
const RIGHT_DIALOGUE_SOUND = preload("res://sfx/Characters Dialogue/Character Response.wav")
const TRUE_FORM_DIALOGUE_SOUND = preload("res://sfx/Characters Dialogue/True Form.wav")

>>>>>>> Stashed changes
func debug_log(msg) -> void:
	if DEBUG_LOGS:
		print(msg)

func _ready() -> void:
	if dialogue_ui:
		dialogue_ui.left_sound = LEFT_DIALOGUE_SOUND
		dialogue_ui.right_sound = RIGHT_DIALOGUE_SOUND
		dialogue_ui.true_form_sound = TRUE_FORM_DIALOGUE_SOUND

	add_to_group("inspection_controller")

	approve_btn.pressed.connect(func(): _on_decision_pressed("approve"))
	deny_btn.pressed.connect(func(): _on_decision_pressed("deny"))

	document_manager = get_tree().get_first_node_in_group("document_manager")

	if true_form_timer and not true_form_timer.timeout.is_connected(_on_true_form_timer_timeout):
		true_form_timer.timeout.connect(_on_true_form_timer_timeout)

	if blinds_system:
		if blinds_system.has_signal("blinds_closed_success"):
			blinds_system.blinds_closed_success.connect(_on_blinds_closed_success)
	else:
		push_error("BlindsSystem not found in _ready(). Check node path.")

	if jumpscare_sprite and not jumpscare_sprite.animation_finished.is_connected(_on_jumpscare_finished):
		jumpscare_sprite.animation_finished.connect(_on_jumpscare_finished)

	if meredith_jumpscare_sprite and not meredith_jumpscare_sprite.animation_finished.is_connected(_on_jumpscare_finished):
		meredith_jumpscare_sprite.animation_finished.connect(_on_jumpscare_finished)

	_hide_all_jumpscare_sprites()

	shake_layers = [
		bg_layer_shake,
		table_layer_shake,
		uilayer_shake,
		blinds_layer_shake,
		character_layer_shake,
		documents_shake,
		bloody_ui_shake,
		jumpscare_layer_shake,
		microphone_layer_shake,
		dialogueui_layer_shake
	]

	for layer in shake_layers:
		if layer == null:
			continue

		if layer is Node2D:
			original_layer_positions[layer] = layer.position
		elif layer is CanvasLayer:
			original_layer_positions[layer] = layer.offset

	if warning2_overlay:
		warning2_overlay_base_position = warning2_overlay.position
		warning2_overlay.visible = false
		warning2_overlay.modulate.a = 0.0

	if bloodier_minitable:
		bloodier_minitable.visible = false

	if bloodier_organizer:
		bloodier_organizer.visible = false

	screen_shake_time = 0.0
	screen_shake_strength = 0.0
	warning2_distortion_timer = 0.0
	_apply_layer_shake_offset(Vector2.ZERO)

	if in_game_music and in_game_music.stream and not in_game_music.playing:
		in_game_music.play()

	if microphone_button:
		microphone_button.pressed.connect(_on_microphone_pressed)

	reset_run_state()

func generate_shift_queue() -> void:
	shift_queue.clear()

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	if normal_character_scenes.size() < NORMALS_PER_RUN:
		push_error("Need at least %d normal characters." % NORMALS_PER_RUN)
		return

	if disguised_character_scenes.size() < DISGUISED_PER_RUN:
		push_error("Need at least %d disguised characters." % DISGUISED_PER_RUN)
		return

	if true_form_character_scenes.size() < TRUE_FORMS_PER_RUN:
		push_error("Need at least %d true form characters." % TRUE_FORMS_PER_RUN)
		return

	var selected_normals: Array[PackedScene] = normal_character_scenes.duplicate()
	selected_normals.shuffle()
	selected_normals = selected_normals.slice(0, NORMALS_PER_RUN)

	var first_normal: PackedScene = selected_normals[0]
	shift_queue.append({
		"scene": first_normal,
		"is_forged": false,
		"type": "normal"
	})

	var remaining_normals: Array[PackedScene] = selected_normals.slice(1, selected_normals.size())

	var forged_count := rng.randi_range(2, 3)
	forged_count = min(forged_count, remaining_normals.size())

	var forged_pick_pool: Array[PackedScene] = remaining_normals.duplicate()
	forged_pick_pool.shuffle()

	var forged_selected: Array[PackedScene] = forged_pick_pool.slice(0, forged_count)

	var tail_queue: Array = []

	for scene in remaining_normals:
		tail_queue.append({
			"scene": scene,
			"is_forged": forged_selected.has(scene),
			"type": "normal"
		})

	var disguised_pool: Array[PackedScene] = disguised_character_scenes.duplicate()
	disguised_pool.shuffle()
	for i in range(DISGUISED_PER_RUN):
		tail_queue.append({
			"scene": disguised_pool[i],
			"is_forged": false,
			"type": "disguised"
		})

	var true_form_pool: Array[PackedScene] = true_form_character_scenes.duplicate()
	true_form_pool.shuffle()
	for i in range(TRUE_FORMS_PER_RUN):
		tail_queue.append({
			"scene": true_form_pool[i],
			"is_forged": false,
			"type": "true_form"
		})

	tail_queue.shuffle()
	shift_queue.append_array(tail_queue)

func spawn_character() -> void:
	if shift_queue.is_empty():
		push_error("Shift queue is empty. Generate the shift queue first.")
		return

	microphone_used = false

	_lock_gameplay()

	_cleanup_current_character()
	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	if document_manager and document_manager.has_method("clear_opened_docs"):
		document_manager.clear_opened_docs()

	if _char_index >= shift_queue.size():
		debug_log("No more characters left to spawn.")
		return

	var entry: Dictionary = shift_queue[_char_index]
	_char_index += 1

	current_character = entry["scene"].instantiate()

	if current_character.has_method("apply_run_variant"):
		current_character.apply_run_variant(bool(entry.get("is_forged", false)))

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

	if _is_true_form_character(current_character):
		return

	if not scare_started:
		start_scare_meter()

func _on_character_reached_stop() -> void:
	if current_character == null:
		return

	if footstep_sfx and footstep_sfx.playing:
		footstep_sfx.stop()

	if _is_true_form_character(current_character):
		true_form_active = true
		current_scare_duration = 4.0

		approve_btn.disabled = true
		deny_btn.disabled = true

		play_true_form_presence_sfx()

		scare_started = true
		scare_alarm_triggered = false

		if true_form_timer:
			true_form_timer.start(current_scare_duration)

<<<<<<< Updated upstream
=======
		if current_character.has_method("get_dialogue_messages"):
			character_dialogue_messages = current_character.get_dialogue_messages()
		else:
			character_dialogue_messages = []

		if dialogue_ui and character_dialogue_messages.size() > 0:
			dialogue_ui.set_true_form_mode(true)
			if dialogue_ui.conversation_finished.is_connected(_on_true_form_dialogue_finished):
				dialogue_ui.conversation_finished.disconnect(_on_true_form_dialogue_finished)
			dialogue_ui.conversation_finished.connect(_on_true_form_dialogue_finished)
			dialogue_ui.visible = true
			dialogue_ui.start_conversation(character_dialogue_messages)

>>>>>>> Stashed changes
		debug_log("True form reached stop. 4-second anomaly state started.")
		return

	if current_character.has_method("get_dialogue_messages"):
		character_dialogue_messages = current_character.get_dialogue_messages()
	else:
		character_dialogue_messages = []
	_lock_gameplay()

	if _is_disguised_character(current_character):
		true_form_active = true
		current_scare_duration = 8.0

		approve_btn.disabled = true
		deny_btn.disabled = true

		if microphone_button:
			microphone_button.visible = true
			var mic_sprite = microphone_button.get_node("MicSprite")
			if mic_sprite:
				mic_sprite.play("hint")
				await mic_sprite.animation_finished
				if mic_sprite.is_visible_in_tree() and mic_sprite.animation == "hint":
					mic_sprite.play("default")

		scare_started = false
		scare_alarm_triggered = false

		debug_log("Disguised reached stop. Waiting for first mini doc interaction.")
		return

<<<<<<< Updated upstream
	_unlock_gameplay()

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
	microphone_used = false
	if microphone_button and character_dialogue_messages.size() > 0:
		microphone_button.visible = true

func _on_microphone_pressed():
	var mic_sprite = microphone_button.get_node("MicSprite")
	if mic_sprite:
		mic_sprite.stop()
	if not dialogue_ui or not current_character:
		return
	if microphone_used:
		return
	microphone_used = true
	play_sliding_paper_sfx()
	if current_character.has_method("spawn_documents"):
		current_character.spawn_documents()
=======
	microphone_used = false
	if microphone_button and character_dialogue_messages.size() > 0:
		microphone_button.visible = true
		_play_microphone_hint()
		pass

func _on_true_form_dialogue_finished() -> void:
	if dialogue_ui:
		dialogue_ui.set_true_form_mode(false)
		if dialogue_ui.conversation_finished.is_connected(_on_true_form_dialogue_finished):
			dialogue_ui.conversation_finished.disconnect(_on_true_form_dialogue_finished)
		dialogue_ui.visible = false

	character_dialogue_messages = []
	debug_log("True form dialogue finished, anomaly continues.")

func _on_microphone_pressed() -> void:
	if microphone_button == null or not dialogue_ui or not current_character or microphone_used:
		return

	if mic_press_sfx and mic_press_sfx.stream:
		mic_press_sfx.play()

	microphone_used = true

	microphone_button.disabled = true

	var mic_sprite: AnimatedSprite2D = microphone_button.get_node_or_null("MicSprite")
	if mic_sprite and mic_sprite.sprite_frames and mic_sprite.sprite_frames.has_animation("default"):
		mic_sprite.play("default")

>>>>>>> Stashed changes
	if character_dialogue_messages.size() > 0:
		if dialogue_ui.conversation_finished.is_connected(_on_dialogue_finished):
			dialogue_ui.conversation_finished.disconnect(_on_dialogue_finished)
		dialogue_ui.conversation_finished.connect(_on_dialogue_finished)
		dialogue_ui.visible = true
		dialogue_ui.start_conversation(character_dialogue_messages)
	else:
		dialogue_finished_for_character = true
		_unlock_gameplay()

	await get_tree().create_timer(1.0).timeout
	play_sliding_paper_sfx()
	if current_character.has_method("spawn_documents"):
		current_character.spawn_documents()

func _on_dialogue_finished() -> void:
	if dialogue_ui:
		dialogue_ui.conversation_finished.disconnect(_on_dialogue_finished)
		dialogue_ui.visible = false
	character_dialogue_messages = []
<<<<<<< Updated upstream
	_unlock_gameplay()

=======
	print("_on_dialogue_finished called")
	dialogue_finished_for_character = true
	_unlock_gameplay()

	if microphone_button:
		microphone_button.disabled = true

		var mic_sprite: AnimatedSprite2D = microphone_button.get_node_or_null("MicSprite")
		if mic_sprite and mic_sprite.sprite_frames and mic_sprite.sprite_frames.has_animation("default"):
			mic_sprite.play("default")

>>>>>>> Stashed changes
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
	stop_anomaly_sfx()

	approve_btn.disabled = false
	deny_btn.disabled = false

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	if document_manager and document_manager.has_method("clear_opened_docs"):
		document_manager.clear_opened_docs()

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
	stop_all_looping_sfx()

	approve_btn.disabled = false
	deny_btn.disabled = false

	var selected_jumpscare_sprite: AnimatedSprite2D = _get_active_jumpscare_sprite()

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	_hide_all_jumpscare_sprites()
	active_jumpscare_sprite = selected_jumpscare_sprite

	_cleanup_current_character()

	if blinds_system:
		blinds_system.force_open()

	start_screen_shake(0.2, 16.0)
	play_jumpscare_sfx()

	if active_jumpscare_sprite:
		active_jumpscare_sprite.visible = true

		if active_jumpscare_sprite.sprite_frames and active_jumpscare_sprite.sprite_frames.has_animation("play"):
			active_jumpscare_sprite.play("play")
		else:
			push_error("Active jumpscare sprite has no animation named 'play'.")

	debug_log("JUMPSCARE START")
	hide_warning2_overlay()
	hide_bloody_ui2()

func _on_jumpscare_finished() -> void:
	if active_jumpscare_sprite:
		active_jumpscare_sprite.stop()
		active_jumpscare_sprite.visible = false

	debug_log("JUMPSCARE FINISHED")
	get_tree().change_scene_to_file(game_over_scene_path)

func _on_decision_pressed(decision: String) -> void:
	if current_character and current_character.has_method("set_mini_docs_interactable"):
		current_character.set_mini_docs_interactable(false)
	if _locked or game_over:
		return

	if true_form_active:
		return

	if decision == "approve":
		play_approve_button_sfx()
	elif decision == "deny":
		play_deny_button_sfx()

	_lock_gameplay()
	true_form_timer.stop()
	reset_scare_meter()
	stop_anomaly_sfx()

	if mini_table_layer:
		for child in mini_table_layer.get_children():
			if child.has_method("set_interactable"):
				child.set_interactable(false)

	if document_layer:
		for child in document_layer.get_children():
			if child.has_method("set_interactable"):
				child.set_interactable(false)

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

	if document_manager and document_manager.has_method("set_all_opened_docs_interactable"):
		document_manager.set_all_opened_docs_interactable(false)

	var dialogue_messages: Array = []
	var is_forged = current_character.run_is_forged   # true if forged

	if decision == "approve":
		if is_forged and current_character.has_method("get_forged_approve_messages"):
			dialogue_messages = current_character.get_forged_approve_messages()
		elif current_character.has_method("get_approve_messages"):
			dialogue_messages = current_character.get_approve_messages()
	else: # deny
		if is_forged and current_character.has_method("get_forged_deny_messages"):
			dialogue_messages = current_character.get_forged_deny_messages()
		elif current_character.has_method("get_deny_messages"):
			dialogue_messages = current_character.get_deny_messages()

	if dialogue_ui and dialogue_messages.size() > 0:
	# Disconnect any previous connection
		if dialogue_ui.conversation_finished.is_connected(_on_decision_dialogue_finished):
				dialogue_ui.conversation_finished.disconnect(_on_decision_dialogue_finished)
		dialogue_ui.conversation_finished.connect(_on_decision_dialogue_finished.bind(decision))
		dialogue_ui.visible = true
		dialogue_ui.start_conversation(dialogue_messages)
	# Exit will happen after the signal
	else:
		_finish_decision(decision)

func _on_decision_dialogue_finished(decision: String) -> void:
	if dialogue_ui:
		dialogue_ui.conversation_finished.disconnect(_on_decision_dialogue_finished)
		dialogue_ui.visible = false
<<<<<<< Updated upstream
=======

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

>>>>>>> Stashed changes
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
	if blood_minitable:
		blood_minitable.visible = true
	if blood_organizer:
		blood_organizer.visible = true
	play_blood_damage_sfx()
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
	if blood_minitable:
		blood_minitable.visible = false

	if blood_organizer:
		blood_organizer.visible = false

	hide_bloody_ui2()
	_hide_all_jumpscare_sprites()

	reset_scare_meter()
	stop_all_looping_sfx()

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

	true_form_timer.stop()
	_disable_buttons(false)

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	if document_manager and document_manager.has_method("clear_opened_docs"):
		document_manager.clear_opened_docs()

	_cleanup_current_character()
	_apply_layer_shake_offset(Vector2.ZERO)

	if blinds_system:
		blinds_system.force_open()
	else:
		push_error("BlindsSystem not found. Check node path.")

	microphone_used = false
	character_dialogue_messages = []

	generate_shift_queue()
	spawn_character()

	hide_warning2_overlay()

func _finish_character_and_continue() -> void:
	processed_characters += 1
	debug_log("Processed characters: " + str(processed_characters) + "/" + str(max_characters_per_shift))

	if processed_characters >= max_characters_per_shift:
		stop_all_looping_sfx()
		get_tree().change_scene_to_file(success_scene_path)
		return

	reset_scare_meter()
	approve_btn.disabled = false
	deny_btn.disabled = false

	_unlock_gameplay()
	spawn_character()

func play_footstep_sfx() -> void:
	if footstep_sfx and footstep_sfx.stream:
		if not footstep_sfx.playing:
			footstep_sfx.play()

func play_sliding_paper_sfx() -> void:
	if sliding_paper_sfx and sliding_paper_sfx.stream:
		sliding_paper_sfx.play()

func play_page_turn_sfx() -> void:
	if page_turn_sfx and page_turn_sfx.stream and not page_turn_sfx.playing:
		page_turn_sfx.play()

func play_mistake_sfx() -> void:
	if mistake_sfx and mistake_sfx.stream and not mistake_sfx.playing:
		mistake_sfx.play()

func play_true_form_presence_sfx() -> void:
	if true_form_presence_sfx and true_form_presence_sfx.stream and not true_form_presence_sfx.playing:
		true_form_presence_sfx.play()

func play_screen_distort_sfx() -> void:
	if screen_distort_sfx and screen_distort_sfx.stream and not screen_distort_sfx.playing:
		screen_distort_sfx.play()

func play_jumpscare_sfx() -> void:
	if jumpscare_sfx and jumpscare_sfx.stream and not jumpscare_sfx.playing:
		jumpscare_sfx.play()

func play_alarm_sfx() -> void:
	if alarm_sfx and alarm_sfx.stream:
		if alarm_sfx.playing:
			alarm_sfx.stop()
		alarm_sfx.play()

func play_blood_damage_sfx() -> void:
	if blood_damage_sfx and blood_damage_sfx.stream and not blood_damage_sfx.playing:
		blood_damage_sfx.play()

func play_approve_button_sfx() -> void:
	if approve_button_sfx and approve_button_sfx.stream:
		approve_button_sfx.play()

func play_deny_button_sfx() -> void:
	if deny_button_sfx and deny_button_sfx.stream:
		deny_button_sfx.play()

func play_hover_sfx() -> void:
	if hover_sfx and hover_sfx.stream:
		hover_sfx.play()

func play_click_sfx() -> void:
	if click_sfx and click_sfx.stream:
		click_sfx.play()

func play_lever_sfx() -> void:
	if lever_sfx and lever_sfx.stream:
		lever_sfx.play()

func play_blinds_up_sfx() -> void:
	if blinds_up_sfx and blinds_up_sfx.stream:
		blinds_up_sfx.play()

func play_blinds_down_sfx() -> void:
	if blinds_down_sfx and blinds_down_sfx.stream:
		blinds_down_sfx.play()

func stop_anomaly_sfx() -> void:
	if true_form_presence_sfx and true_form_presence_sfx.playing:
		true_form_presence_sfx.stop()
	if screen_distort_sfx and screen_distort_sfx.playing and scare_warning_stage < 2:
		screen_distort_sfx.stop()

func stop_all_looping_sfx() -> void:
	if footstep_sfx and footstep_sfx.playing:
		footstep_sfx.stop()
	if true_form_presence_sfx and true_form_presence_sfx.playing:
		true_form_presence_sfx.stop()
	if screen_distort_sfx and screen_distort_sfx.playing:
		screen_distort_sfx.stop()
	if scare_alarm_sfx and scare_alarm_sfx.playing:
		scare_alarm_sfx.stop()
	if scare_meter_sfx and scare_meter_sfx.playing:
		scare_meter_sfx.stop()
	if alarm_sfx and alarm_sfx.playing:
		alarm_sfx.stop()

func start_scare_meter() -> void:
	if scare_started:
		return

	if current_character == null:
		return

	scare_started = true
	scare_alarm_triggered = false
	
	if _is_disguised_character(current_character) and true_form_timer:
		true_form_timer.start(current_scare_duration)
		
	debug_log("Scare meter started.")

func reset_scare_meter() -> void:
	scare_started = false
	scare_fill_progress = 0.0
	scare_alarm_triggered = false
	screen_shake_time = 0.0
	screen_shake_strength = 0.0
	warning2_elapsed_time = 0.0
	warning2_shake_timer = 0.0

	if scare_meter_sfx:
		if scare_meter_sfx.playing:
			scare_meter_sfx.stop()

	if scare_alarm_sfx and scare_alarm_sfx.playing:
		scare_alarm_sfx.stop()

	if alarm_sfx and alarm_sfx.playing:
		alarm_sfx.stop()

	if screen_distort_sfx and screen_distort_sfx.playing:
		screen_distort_sfx.stop()

	if scare_warning_stage < 2:
		if in_game_music and in_game_music.stream and not in_game_music.playing:
			in_game_music.play()

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

	# Only alarm_sfx from 80% to below 100%
	if scare_fill_progress >= 0.80 and scare_fill_progress < 1.0:
		if alarm_sfx and not alarm_sfx.playing:
			alarm_sfx.play()
	else:
		if alarm_sfx and alarm_sfx.playing:
			alarm_sfx.stop()

	if scare_fill_progress >= 1.0:
		scare_fill_progress = 0.0
		scare_alarm_triggered = false

		if alarm_sfx and alarm_sfx.playing:
			alarm_sfx.stop()

		start_screen_shake(0.22, 12.0)
		play_mistake_sfx()

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
		warning2_distortion_timer = randf_range(2.0, 4.0)
		warning2_shake_timer = warning2_burst_interval
		warning2_elapsed_time = 0.0
		show_warning2_overlay()
		show_bloody_ui2()

	elif scare_warning_stage >= 3:
		trigger_jumpscare()

func advance_warning_state_from_mistake() -> void:
	scare_warning_stage += 1

	debug_log("Scare warning stage from mistake: " + str(scare_warning_stage))

	if scare_warning_stage == 1:
		_show_bloody_ui()

	elif scare_warning_stage == 2:
		scare_fill_speed_multiplier = WARNING2_SPEED_MULTIPLIER
		warning2_distortion_timer = randf_range(2.0, 4.0)
		warning2_shake_timer = warning2_burst_interval
		warning2_elapsed_time = 0.0
		show_warning2_overlay()
		show_bloody_ui2()

	elif scare_warning_stage >= 3:
		trigger_jumpscare()

func _process(delta: float) -> void:
	process_scare_meter(delta)

	var warning1_or_higher: bool = scare_warning_stage >= 1 and not game_over
	var warning2_active: bool = scare_warning_stage >= 2 and not game_over

	if screen_shake_time > 0.0:
		screen_shake_time -= delta

		var shake_ratio: float = clamp(screen_shake_time / 0.36, 0.0, 1.0)
		var t: float = Time.get_ticks_msec() * 0.001

		var slam_x: float = sin(t * 62.0) * screen_shake_strength * 1.85 * shake_ratio
		var slam_y: float = cos(t * 41.0) * screen_shake_strength * 0.55 * shake_ratio

		var random_x: float = randf_range(-screen_shake_strength * 0.26, screen_shake_strength * 0.26)
		var random_y: float = randf_range(-screen_shake_strength * 0.14, screen_shake_strength * 0.14)

		var offset := Vector2(
			slam_x + random_x,
			slam_y + random_y
		)

		_apply_layer_shake_offset(offset)

	elif warning1_or_higher:
		warning2_elapsed_time += delta

		var t: float = Time.get_ticks_msec() * 0.001
		var sway_x: float = 0.35
		var sway_y: float = 0.18

		if warning2_active:
			var sway_growth: float = clamp(warning2_elapsed_time / 18.0, 0.0, 1.0)
			sway_x = lerp(0.35, 0.75, sway_growth)
			sway_y = lerp(0.18, 0.40, sway_growth)

		var subtle_offset := Vector2(
			sin(t * 2.2) * sway_x,
			cos(t * 1.7) * sway_y
		)

		_apply_layer_shake_offset(subtle_offset)

	else:
		_apply_layer_shake_offset(Vector2.ZERO)

	if flicker_time > 0.0:
		flicker_time -= delta
		_apply_flicker()
	else:
		_reset_flicker()

	if warning2_active:
		if warning2_overlay:
			if not warning2_overlay.visible:
				show_warning2_overlay()

			warning2_overlay_motion_time += delta

			var pulse := pow(
				sin(warning2_overlay_motion_time * warning2_overlay_pulse_speed) * 0.5 + 0.5,
				1.6
			)

			var alpha := warning2_overlay_base_alpha + (pulse * warning2_overlay_flicker_strength)
			alpha += randf_range(-0.01, 0.01)
			warning2_overlay.modulate.a = clamp(alpha, 0.45, 0.82)

			var drift_offset := Vector2(
				sin(warning2_overlay_motion_time * 0.55) * warning2_overlay_drift_x,
				cos(warning2_overlay_motion_time * 0.40) * warning2_overlay_drift_y
			)

			var jitter_offset := Vector2(
				randf_range(-warning2_overlay_jitter_strength, warning2_overlay_jitter_strength),
				randf_range(-warning2_overlay_jitter_strength, warning2_overlay_jitter_strength)
			)

			warning2_overlay.position = warning2_overlay_base_position + drift_offset + jitter_offset

		warning2_distortion_timer -= delta
		if warning2_distortion_timer <= 0.0:
			warning2_distortion_timer = randf_range(2.0, 4.0)
			play_screen_distort_sfx()

		warning2_shake_timer -= delta
		if warning2_shake_timer <= 0.0:
			warning2_shake_timer = warning2_burst_interval

			var burst_growth: float = clamp(warning2_elapsed_time / 18.0, 0.0, 1.0)
			var burst_strength: float = lerp(8.5, 12.5, burst_growth)

			start_screen_shake(0.36, burst_strength)

	else:
		warning2_distortion_timer = 0.0
		warning2_shake_timer = 0.0

		if scare_warning_stage < 1:
			warning2_elapsed_time = 0.0

		if warning2_overlay and warning2_overlay.visible:
			hide_warning2_overlay()
		
func _apply_layer_shake_offset(offset: Vector2) -> void:
	if offset == current_shake_offset:
		return

	current_shake_offset = offset

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

func show_warning2_overlay() -> void:
	if warning2_overlay == null:
		return

	warning2_overlay.visible = true
	warning2_overlay.modulate.a = warning2_overlay_base_alpha
	warning2_overlay_motion_time = 0.0
	warning2_overlay.position = warning2_overlay_base_position

func hide_warning2_overlay() -> void:
	if warning2_overlay == null:
		return

	warning2_overlay.visible = false
	warning2_overlay.modulate.a = 0.0
	warning2_overlay_motion_time = 0.0
	warning2_overlay.position = warning2_overlay_base_position
	hide_bloody_ui2()

func _is_meredith_true_form(character: Node) -> bool:
	if character == null:
		return false

	if not _is_true_form_character(character):
		return false

	if character.has_method("get_character_id"):
		return str(character.get_character_id()).to_lower() == "meredith_grey"

	var scene_path := ""
	if character.scene_file_path != null:
		scene_path = str(character.scene_file_path).to_lower()

	return "meredith" in scene_path
	
func _hide_all_jumpscare_sprites() -> void:
	if jumpscare_sprite:
		jumpscare_sprite.visible = false
		jumpscare_sprite.stop()

	if meredith_jumpscare_sprite:
		meredith_jumpscare_sprite.visible = false
		meredith_jumpscare_sprite.stop()

	active_jumpscare_sprite = null
	
func _get_active_jumpscare_sprite() -> AnimatedSprite2D:
	if _is_meredith_true_form(current_character) and meredith_jumpscare_sprite:
		return meredith_jumpscare_sprite

	return jumpscare_sprite
	
func show_bloody_ui2() -> void:
	if bloodier_minitable:
		bloodier_minitable.visible = true

	if bloodier_organizer:
		bloodier_organizer.visible = true
		
func hide_bloody_ui2() -> void:
	if bloodier_minitable:
		bloodier_minitable.visible = false

	if bloodier_organizer:
		bloodier_organizer.visible = false
