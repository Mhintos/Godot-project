extends CharacterBody2D

@export var drag_speed: float = 25.0

var is_active := false
var dragging := false
var drag_offset := Vector2.ZERO

@onready var document_manager: Node = get_tree().get_first_node_in_group("document_manager")


func _ready() -> void:
	set_physics_process(false)
	_update_visual()


func set_active(value: bool) -> void:
	if is_active == value:
		return

	is_active = value
	_update_visual()


func _update_visual() -> void:
	if is_active:
		modulate = Color(1.1, 1.1, 1.1)
	else:
		modulate = Color(1, 1, 1)


func _input_event(_viewport, event, _shape_idx) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if event.pressed:
		_start_drag()
	else:
		_stop_drag()


func _start_drag() -> void:
	dragging = true
	drag_offset = global_position - get_global_mouse_position()
	set_physics_process(true)

	if document_manager:
		if document_manager.has_method("_bring_doc_to_front"):
			document_manager._bring_doc_to_front(self)
		if document_manager.has_method("set_active_document"):
			document_manager.set_active_document(self)


func _stop_drag() -> void:
	dragging = false
	velocity = Vector2.ZERO
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if not dragging:
		return

	var target_pos := get_global_mouse_position() + drag_offset
	velocity = (target_pos - global_position) * drag_speed
	move_and_slide()


func _exit_tree() -> void:
	dragging = false
	velocity = Vector2.ZERO
	set_physics_process(false)
