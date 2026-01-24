extends CharacterBody2D

static var top_z := 0
@export var drag_speed: float = 25.0

var is_active := false
var dragging := false
var drag_offset := Vector2.ZERO

func set_active(value: bool) -> void:
	is_active = value
	_update_visual()

func _update_visual() -> void:
	if is_active:
		modulate = Color(1.1, 1.1, 1.1) # subtle highlight
	else:
		modulate = Color(1, 1, 1)

func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = global_position - get_global_mouse_position()

			top_z += 1
			z_index = top_z

			var manager = get_tree().get_first_node_in_group("document_manager")
			if manager:
				manager.set_active_document(self)
		else:
			dragging = false

func _physics_process(delta: float) -> void:
	if dragging:
		var target_pos = get_global_mouse_position() + drag_offset
		velocity = (target_pos - global_position) * drag_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
