extends Node

@export var document_layer_path: NodePath
@export var inspect_spawn_path: NodePath
var inspection_controller: Node = null

var opened_docs := {}

var dragging_document: Node = null
var active_document: Node = null

func _ready() -> void:
	add_to_group("document_manager")
	inspection_controller = get_tree().get_first_node_in_group("inspection_controller")

func clear_opened_docs() -> void:
	for doc in opened_docs.values():
		if is_instance_valid(doc):
			doc.queue_free()

	opened_docs.clear()
	active_document = null

func set_active_document(doc: Node) -> void:
	if active_document and is_instance_valid(active_document):
		if active_document.has_method("set_active"):
			active_document.set_active(false)

	active_document = doc

	if active_document and is_instance_valid(active_document):
		if active_document.has_method("set_active"):
			active_document.set_active(true)

		var highest: int = 0

		for node in get_tree().get_nodes_in_group("draggable_documents"):
			if node is Node2D:
				highest = max(highest, node.z_index)

		if active_document is Node2D:
			active_document.z_index = highest + 1

func open_document(doc_id: String, scene: PackedScene) -> void:
	if doc_id == "" or scene == null:
		return

	var document_layer: Node = get_node_or_null(document_layer_path)
	var spawn: Node2D = get_node_or_null(inspect_spawn_path)

	if document_layer == null:
		push_error("DocumentManager: document_layer_path invalid: " + str(document_layer_path))
		return

	if spawn == null:
		push_error("DocumentManager: inspect_spawn_path invalid: " + str(inspect_spawn_path))
		return

	var inspection = inspection_controller

	# If document already exists, bring it to front and replay paper SFX
	if opened_docs.has(doc_id) and is_instance_valid(opened_docs[doc_id]):
		var doc = opened_docs[doc_id]

		if inspection and inspection.has_method("play_sliding_paper_sfx"):
			inspection.play_sliding_paper_sfx()

		if doc is Node2D:
			doc.global_position = spawn.global_position

		_bring_doc_to_front(doc)
		set_active_document(doc)
		return

	# Play paper sound when opening a new document
	if inspection and inspection.has_method("play_sliding_paper_sfx"):
		inspection.play_sliding_paper_sfx()

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

	var z: int = 0
	for d in docs:
		d.z_index = z
		z += 1

	doc.z_index = z
