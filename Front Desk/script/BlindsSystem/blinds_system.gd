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
	lever_area.input_event.connect(_on_lever_input_event)
	blinds.animation_finished.connect(_on_blinds_animation_finished)
	lever.animation_finished.connect(_on_lever_animation_finished)

	blinds.play("idle_open")
	lever.play("up")

func force_open() -> void:
	is_closed = false
	is_animating = false
	lever_done = false
	blinds_done = false
	blinds.play("idle_open")
	lever.play("up")
	
func _on_lever_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_blinds()


func toggle_blinds() -> void:
	if is_animating:
		return

	is_animating = true
	lever_done = false
	blinds_done = false

	if is_closed:
		lever.play("pull_up")
		blinds.play("opening")
	else:
		lever.play("pull_down")
		blinds.play("closing")


func _on_blinds_animation_finished() -> void:
	if blinds.animation == "closing":
		is_closed = true
		blinds.play("idle_closed")
		blinds_done = true
		emit_signal("blinds_closed_success")
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
