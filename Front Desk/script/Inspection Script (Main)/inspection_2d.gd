extends Node2D

@export var mini_id_slot_path: NodePath
@export var mini_permit_slot_path: NodePath

@export var approve_button_path: NodePath
@export var deny_button_path: NodePath

@export var mini_table_layer_path: NodePath
@export var document_layer_path: NodePath

@export var character_scenes: Array[PackedScene]

@export var blood_minitable_path: NodePath
@export var blood_organizer_path: NodePath

@export var jumpscare_sprite_path: NodePath

@export var max_characters_per_shift: int = 4
@export var success_scene_path: String = "res://scene/Success/success.tscn"
@export var game_over_scene_path: String = "res://scene/GameOver/game_over.tscn"

@onready var true_form_timer: Timer = $TrueFormTimer
@onready var blinds_system: Node = get_node_or_null("Blinds Layer/BlindsSystem")

@onready var approve_btn: BaseButton = get_node(approve_button_path)
@onready var deny_btn: BaseButton = get_node(deny_button_path)

@onready var mini_table_layer: Node = get_node(mini_table_layer_path)
@onready var document_layer: Node = get_node(document_layer_path)

@onready var blood_minitable: CanvasItem = get_node(blood_minitable_path)
@onready var blood_organizer: CanvasItem = get_node(blood_organizer_path)

@onready var jumpscare_sprite: AnimatedSprite2D = get_node(jumpscare_sprite_path)

@onready var in_game_music: AudioStreamPlayer = $SFX/InGameMusic
@onready var footstep_sfx: AudioStreamPlayer = $SFX/FootstepSFX
@onready var sliding_paper_sfx: AudioStreamPlayer = $SFX/SlidingPaperSFX
@onready var page_turn_sfx: AudioStreamPlayer = $SFX/PageTurnSFX
@onready var mistake_sfx: AudioStreamPlayer = $SFX/MistakeSFX
@onready var true_form_presence_sfx: AudioStreamPlayer = $SFX/TrueFormPresenceSFX
@onready var screen_distort_sfx: AudioStreamPlayer = $SFX/ScreenDistortSFX
@onready var jumpscare_sfx: AudioStreamPlayer = $SFX/JumpscareSFX

var _char_index := 0
var current_character: Node2D = null
var _locked := false
var true_form_active := false
var mistake_count := 0
var game_over := false
var processed_characters := 0

const DEBUG_LOGS := false

func debug_log(msg) -> void:
	if DEBUG_LOGS:
		print(msg)

func _ready() -> void:
	reset_run_state()

	approve_btn.pressed.connect(func(): _on_decision_pressed("approve"))
	deny_btn.pressed.connect(func(): _on_decision_pressed("deny"))

	if blinds_system:
		blinds_system.blinds_closed_success.connect(_on_blinds_closed_success)
	else:
		push_error("BlindsSystem not found in _ready(). Check node path.")

	jumpscare_sprite.visible = false
	jumpscare_sprite.animation_finished.connect(_on_jumpscare_finished)

	spawn_character()


func spawn_character() -> void:
	if character_scenes.is_empty():
		push_error("inspection_2d.gd: character_scenes is empty. Add character scenes in Inspector.")
		return

	_cleanup_current_character()
	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	if _char_index >= character_scenes.size():
		debug_log("No more characters left to spawn.")
		return

	current_character = character_scenes[_char_index].instantiate()
	_char_index += 1

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


func _on_character_reached_stop() -> void:
	if current_character == null:
		return

	play_sliding_paper_sfx()

	if current_character.is_true_form:
		true_form_active = true
		play_true_form_presence_sfx()
		play_screen_distort_sfx()
		debug_log("True form reached stop. Timer started.")
		true_form_timer.start()


func _on_blinds_closed_success() -> void:
	if not true_form_active:
		return

	if current_character == null:
		return

	if current_character.is_true_form:
		true_form_timer.stop()
		debug_log("True form blocked successfully.")
		_reject_true_form()


func _reject_true_form() -> void:
	if _locked:
		return

	_lock_gameplay()
	true_form_timer.stop()
	true_form_active = false

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
		debug_log("True form blocked in time.")
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

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)

	_cleanup_current_character()

	if blinds_system:
		blinds_system.force_open()

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

	_lock_gameplay()
	true_form_timer.stop()

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

	var exit_method := "exit_right"
	if decision == "deny":
		exit_method = "exit_left"

	if current_character.has_method(exit_method):
		current_character.call(exit_method, func():
			current_character = null

			if blinds_system:
				blinds_system.force_open()

			if game_over:
				return

			_finish_character_and_continue()
		)
	else:
		current_character = null

		if blinds_system:
			blinds_system.force_open()

		if game_over:
			return

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


func _register_mistake() -> void:
	mistake_count += 1
	play_mistake_sfx()
	debug_log("Mistake count: " + str(mistake_count))

	if mistake_count == 1:
		_show_bloody_ui()
	elif mistake_count >= 2:
		trigger_jumpscare()


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
	mistake_count = 0
	game_over = false
	true_form_active = false
	_locked = false
	processed_characters = 0
	_char_index = 0

	blood_minitable.visible = false
	blood_organizer.visible = false
	jumpscare_sprite.visible = false
	jumpscare_sprite.stop()

	true_form_timer.stop()
	_disable_buttons(false)

	_clear_layer(mini_table_layer)
	_clear_layer(document_layer)
	_cleanup_current_character()

	if blinds_system:
		blinds_system.force_open()
	else:
		push_error("BlindsSystem not found. Check node path.")


func _finish_character_and_continue() -> void:
	processed_characters += 1
	debug_log("Processed characters: " + str(processed_characters) + "/" + str(max_characters_per_shift))

	if processed_characters >= max_characters_per_shift:
		get_tree().change_scene_to_file(success_scene_path)
		return

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
