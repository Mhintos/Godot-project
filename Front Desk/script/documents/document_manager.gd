extends Node

@export var document_layer_path: NodePath
@export var inspect_spawn_path: NodePath

var active_document: Node = null
var opened_docs := {}  # doc_id -> Node (instance)

func _ready() -> void:
	add_to_group("document_manager")

func set_active_document(doc: Node) -> void:
	if active_document and is_instance_valid(active_document):
		active_document.set_active(false)

	active_document = doc

	if active_document and is_instance_valid(active_document):
		active_document.set_active(true)

func open_document(doc_id: String, scene: PackedScene) -> void:
	if doc_id == "" or scene == null:
		return

	var document_layer: Node = get_node(document_layer_path)
	var spawn: Node2D = get_node(inspect_spawn_path)

	if opened_docs.has(doc_id) and is_instance_valid(opened_docs[doc_id]):
		var doc = opened_docs[doc_id]
		if doc is Node2D:
			doc.global_position = spawn.global_position
		_bring_doc_to_front(doc)
		set_active_document(doc)
		return

	var doc_instance = scene.instantiate()
	document_layer.add_child(doc_instance)

	await get_tree().process_frame

	if doc_instance is Node2D:
		doc_instance.global_position = spawn.global_position

	opened_docs[doc_id] = doc_instance
	_bring_doc_to_front(doc_instance)
	set_active_document(doc_instance)

func _bring_doc_to_front(doc: CanvasItem) -> void:
	var document_layer := get_node(document_layer_path)
	var docs: Array[CanvasItem] = []

	for child in document_layer.get_children():
		if child is CanvasItem:
			docs.append(child)

	docs.erase(doc)

	var z := 0
	for d in docs:
		d.z_index = z
		z += 1

	doc.z_index = z
