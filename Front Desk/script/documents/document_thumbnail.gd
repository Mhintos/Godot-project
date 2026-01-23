extends Area2D

@export var doc_id: String = ""
@export var full_document_scene: PackedScene

func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		var manager = get_tree().get_first_node_in_group("document_manager")
		if manager:
			manager.open_document(doc_id, full_document_scene)
