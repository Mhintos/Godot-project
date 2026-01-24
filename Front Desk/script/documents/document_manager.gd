extends Node

@export var document_layer_path: NodePath
@export var inspect_spawn_path: NodePath

var active_document: Node = null
var opened_docs := {}  # doc_id -> Node (instance)

func _ready() -> void:
	add_to_group("document_manager")

func set_active_document(doc: Node) -> void:
	# Remove highlight from previous
	if active_document and is_instance_valid(active_document):
		active_document.set_active(false)

	active_document = doc

	if active_document:
		active_document.set_active(true)

func open_document(doc_id: String, scene: PackedScene) -> void:
	if doc_id == "" or scene == null:
		return

	var document_layer: Node = get_node(document_layer_path)
	var spawn: Node2D = get_node(inspect_spawn_path)

	# If already opened, bring to front + activate
	if opened_docs.has(doc_id) and is_instance_valid(opened_docs[doc_id]):
		var doc = opened_docs[doc_id]
		doc.global_position = spawn.global_position
		_bring_doc_to_front(doc)
		set_active_document(doc)   # 🔹 STEP 4.4
		return

	# Otherwise spawn it once
	var doc_instance = scene.instantiate()
	document_layer.add_child(doc_instance)

	# IMPORTANT: wait until inside tree before positioning
	await get_tree().process_frame

	if doc_instance is Node2D:
		doc_instance.global_position = spawn.global_position

	opened_docs[doc_id] = doc_instance
	_bring_doc_to_front(doc_instance)
	set_active_document(doc_instance)   # 🔹 STEP 4.4

func _bring_doc_to_front(doc: Node) -> void:
	if doc is CanvasItem:
		doc.z_index = 100000
