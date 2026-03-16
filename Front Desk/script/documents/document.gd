extends Node2D

@export var drag_enabled: bool = true

@onready var sprite: Sprite2D = $Sprite2D

var is_dragging := false
var drag_offset := Vector2.ZERO
var is_active := false


func _ready() -> void:
	add_to_group("draggable_documents")


func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset


func _get_manager():
	return get_tree().get_first_node_in_group("document_manager")


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		if event.pressed:

			if contains_point(get_global_mouse_position()) and _is_topmost_document_under_mouse():
				_make_active()

			_try_start_drag()

		else:
			_stop_drag()


func _try_start_drag():

	if not drag_enabled:
		return

	var mouse_pos := get_global_mouse_position()

	if not contains_point(mouse_pos):
		return

	if not _is_topmost_document_under_mouse():
		return

	var manager = _get_manager()

	if manager != null and manager.dragging_document != null and manager.dragging_document != self:
		return

	_make_active()

	is_dragging = true
	drag_offset = mouse_pos - global_position

	if manager != null:
		manager.dragging_document = self


func _stop_drag():

	if is_dragging:
		is_dragging = false

	var manager = _get_manager()

	if manager != null and manager.dragging_document == self:
		manager.dragging_document = null


func _make_active():

	var manager = _get_manager()

	if manager != null and manager.has_method("set_active_document"):
		manager.set_active_document(self)


func set_active(value: bool):
	is_active = value


func contains_point(point):

	if sprite == null or sprite.texture == null:
		return false

	var tex_size = sprite.texture.get_size()
	var scaled_size = tex_size * sprite.scale

	var sprite_center = global_position + sprite.position

	var rect = Rect2(
		sprite_center - scaled_size / 2,
		scaled_size
	)

	return rect.has_point(point)


func _is_topmost_document_under_mouse():

	var mouse_pos = get_global_mouse_position()

	var top_doc = null
	var top_z = -999999

	for node in get_tree().get_nodes_in_group("draggable_documents"):

		if not (node is Node2D):
			continue

		if not node.has_method("contains_point"):
			continue

		if node.contains_point(mouse_pos):

			if node.z_index > top_z:
				top_z = node.z_index
				top_doc = node

	return top_doc == self
