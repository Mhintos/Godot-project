extends Node

@export var document_layer_path: NodePath
@export var inspect_spawn_path: NodePath

var opened_docs := {}  # doc_id -> Node (instance)

func _ready() -> void:
	add_to_group("document_manager")

func open_document(doc_id: String, scene: PackedScene) -> void:
	if doc_id == "" or scene == null:
		return

	var document_layer: Node = get_node(document_layer_path)
	var spawn: Node2D = get_node(inspect_spawn_path)

	# If already opened, just bring to front and move it to spawn
	if opened_docs.has(doc_id) and is_instance_valid(opened_docs[doc_id]):
		var doc = opened_docs[doc_id]
		doc.global_position = spawn.global_position
		_bring_doc_to_front(doc)
		return

	# Otherwise spawn it once
	var doc_instance = scene.instantiate()
	document_layer.add_child(doc_instance)

# IMPORTANT: set global AFTER it is inside the tree
	await get_tree().process_frame

	if doc_instance is Node2D:
		doc_instance.global_position = spawn.global_position

	opened_docs[doc_id] = doc_instance
	_bring_doc_to_front(doc_instance)

func _bring_doc_to_front(doc: Node) -> void:
	# If it's Node2D/CanvasItem, we can raise it
	if doc is CanvasItem:
		doc.z_index = 100000  # quick boost on open
