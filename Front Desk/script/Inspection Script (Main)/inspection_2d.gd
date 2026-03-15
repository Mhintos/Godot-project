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
@onready var true_form_timer: Timer = $TrueFormTimer
@onready var blinds_system = $Background/BlindsSystem

@onready var blood_minitable: CanvasItem = get_node(blood_minitable_path)
@onready var blood_organizer: CanvasItem = get_node(blood_organizer_path)

@export var jumpscare_sprite_path: NodePath
@onready var jumpscare_sprite: AnimatedSprite2D = get_node(jumpscare_sprite_path)

var _char_index := 0

var current_character: Node2D = null
var _locked := false
var true_form_active := false
var mistake_count := 0
var game_over := false

func _ready() -> void:
	var approve_btn: BaseButton = get_node(approve_button_path)
	var deny_btn: BaseButton = get_node(deny_button_path)

	reset_run_state()

	approve_btn.pressed.connect(func(): _on_decision_pressed("approve"))
	deny_btn.pressed.connect(func(): _on_decision_pressed("deny"))
	blinds_system.blinds_closed_success.connect(_on_blinds_closed_success)

	spawn_character()
	
	jumpscare_sprite.visible = false
	jumpscare_sprite.animation_finished.connect(_on_jumpscare_finished)

func spawn_character() -> void:
	if character_scenes.is_empty():
		push_error("inspection_2d.gd: character_scenes is empty. Add Professor scenes in Inspector.")
		return

	if _char_index >= character_scenes.size():
		_char_index = 0

	current_character = character_scenes[_char_index].instantiate()
	_char_index += 1

	current_character.spawn_marker_path = NodePath("../CharacterSpawn")
	current_character.stop_marker_path = NodePath("../CharacterStop")
	current_character.exit_right_marker_path = NodePath("../CharacterExitRight")
	current_character.exit_left_marker_path = NodePath("../CharacterExitLeft")

	current_character.mini_table_layer_path = NodePath("../MiniTableLayer")
	current_character.mini_id_slot_path = NodePath("../MiniSlot_ID")
	current_character.mini_permit_slot_path = NodePath("../MiniSlot_Permit")

	add_child(current_character)
	current_character.reached_stop.connect(_on_character_reached_stop)


func _on_character_reached_stop() -> void:
	if current_character == null:
		return

	if current_character.is_true_form:
		true_form_active = true
		print("True form reached stop. Timer started.")
		true_form_timer.start()

func _on_blinds_closed_success() -> void:
	if not true_form_active:
		return

	if current_character == null:
		return

	if current_character.is_true_form:
		true_form_timer.stop()
		print("True form blocked successfully.")
		_reject_true_form()


func _reject_true_form() -> void:
	if _locked:
		return
	_locked = true
	_disable_buttons(true)
	true_form_timer.stop()
	true_form_active = false

	_clear_layer(get_node(mini_table_layer_path))
	_clear_layer(get_node(document_layer_path))

	if current_character and is_instance_valid(current_character):
		if current_character.has_method("exit_left"):
			current_character.call("exit_left", func():
				current_character = null
				blinds_system.force_open()
				_locked = false
				_disable_buttons(false)
				spawn_character()
			)
			return

	current_character = null
	blinds_system.force_open()
	_locked = false
	_disable_buttons(false)
	spawn_character()


func _on_true_form_timer_timeout() -> void:
	if not true_form_active:
		return

	if blinds_system.is_closed:
		print("True form blocked in time.")
		_reject_true_form()
	else:
		true_form_active = false
		print("Time ran out - jumpscare")
		trigger_jumpscare()


func trigger_jumpscare() -> void:
	if game_over:
		return

	game_over = true
	true_form_active = false
	_locked = true
	_disable_buttons(true)
	true_form_timer.stop()

	_clear_layer(get_node(mini_table_layer_path))
	_clear_layer(get_node(document_layer_path))

	if current_character and is_instance_valid(current_character):
		current_character.queue_free()
		current_character = null

	blinds_system.force_open()

	jumpscare_sprite.visible = true
	jumpscare_sprite.play("play")

	print("JUMPSCARE START")
	
func _on_jumpscare_finished() -> void:
	jumpscare_sprite.stop()
	print("JUMPSCARE FINISHED")
	
func _on_decision_pressed(decision: String) -> void:
	if _locked or game_over:
		return
	_locked = true
	_disable_buttons(true)

	true_form_timer.stop()

	if current_character == null:
		true_form_active = false
		blinds_system.force_open()
		_locked = false
		_disable_buttons(false)
		spawn_character()
		return

	var is_correct := _is_decision_correct(decision)

	if not is_correct:
		_register_mistake()

	true_form_active = false

	_clear_layer(get_node(mini_table_layer_path))
	_clear_layer(get_node(document_layer_path))

	var exit_method := "exit_right"
	if decision == "deny":
		exit_method = "exit_left"

	if current_character.has_method(exit_method):
		current_character.call(exit_method, func():
			current_character = null
			blinds_system.force_open()

			if game_over:
				return

			_locked = false
			_disable_buttons(false)
			spawn_character()
		)
	else:
		current_character = null
		blinds_system.force_open()

		if game_over:
			return

		_locked = false
		_disable_buttons(false)
		spawn_character()
	
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
	print("Mistake count: ", mistake_count)

	if mistake_count == 1:
		_show_bloody_ui()
	elif mistake_count >= 2:
		trigger_jumpscare()


func _show_bloody_ui() -> void:
	blood_minitable.visible = true
	blood_organizer.visible = true
	print("SHOW BLOODY UI WARNING")

func _clear_layer(layer: Node) -> void:
	for c in layer.get_children():
		c.queue_free()


func _disable_buttons(disabled: bool) -> void:
	var approve_btn: BaseButton = get_node(approve_button_path)
	var deny_btn: BaseButton = get_node(deny_button_path)
	approve_btn.disabled = disabled
	deny_btn.disabled = disabled

func reset_run_state() -> void:
	mistake_count = 0
	game_over = false
	true_form_active = false
	_locked = false

	blood_minitable.visible = false
	blood_organizer.visible = false

	true_form_timer.stop()
	_disable_buttons(false)
	blinds_system.force_open()
