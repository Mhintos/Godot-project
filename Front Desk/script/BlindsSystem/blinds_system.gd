extends Node2D

signal blinds_closed_success

@onready var blinds: AnimatedSprite2D = $Blinds
@onready var lever: AnimatedSprite2D = $Lever
@onready var lever_area: Area2D = $LeverArea

var is_closed: bool = false
var is_animating: bool = false
var lever_done: bool = false
var blinds_done: bool = false

func _ready() -> void:
	lever_area.input_event.connect(_on_lever_area_input_event)
	blinds.animation_finished.connect(_on_blinds_animation_finished)
	lever.animation_finished.connect(_on_lever_animation_finished)

	blinds.play("idle_open")
	lever.play("up")

func get_inspection_controller() -> Node:
	return get_tree().get_first_node_in_group("inspection_controller")

func force_open() -> void:
	var was_closed := is_closed

	is_closed = false
	is_animating = false
	lever_done = false
	blinds_done = false
	blinds.play("idle_open")
	lever.play("up")

	if was_closed:
		var inspection = get_inspection_controller()
		if inspection and inspection.has_method("play_blinds_up_sfx"):
			inspection.play_blinds_up_sfx()

func _on_lever_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var inspection = get_inspection_controller()
		if inspection and inspection.has_method("play_lever_sfx"):
			inspection.play_lever_sfx()

		toggle_blinds()

func toggle_blinds() -> void:
	if is_animating:
		return

	is_animating = true
	lever_done = false
	blinds_done = false

	var inspection = get_inspection_controller()

	if is_closed:
		if inspection and inspection.has_method("play_blinds_up_sfx"):
			inspection.play_blinds_up_sfx()

		lever.play("pull_up")
		blinds.frame = 0
		blinds.play("opening")
	else:
		if inspection and inspection.has_method("play_blinds_down_sfx"):
			inspection.play_blinds_down_sfx()

		lever.play("pull_down")
		blinds.frame = 0
		blinds.play("closing")

func _on_blinds_animation_finished() -> void:
	if blinds.animation == "closing":
		is_closed = true
		blinds.play("idle_closed")
		blinds_done = true
		blinds_closed_success.emit()
		_check_finish()

	elif blinds.animation == "opening":
		is_closed = false
		blinds.play("idle_open")
		blinds_done = true
		_check_finish()

func _on_lever_animation_finished() -> void:
	if lever.animation == "pull_down":
		lever.play("down")
		lever_done = true
		_check_finish()

	elif lever.animation == "pull_up":
		lever.play("up")
		lever_done = true
		_check_finish()

func _check_finish() -> void:
	if lever_done and blinds_done:
		is_animating = false
