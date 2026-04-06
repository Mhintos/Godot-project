extends Node2D

# =============================
# Drag / Stack System
# =============================
var is_dragging := false
var drag_offset := Vector2.ZERO
var is_active := false

@onready var handbook = self
@onready var handbook_opened_sprite = %HandbookOpen

# =============================
# SFX
# =============================
@onready var page_turn_sfx: AudioStreamPlayer = get_tree().current_scene.get_node_or_null("SFX/PageTurnSFX")

# =============================
# Page Navigation
# =============================
var page_frames = {
	"contents": 0,
	"basic_rules": 1,
	"basic_rules_hover": 10,
	"professor1": 3,
	"professor_hover": 11,
	"canteen_staff": 6,
	"canteen_staff_hover": 12,
	"guard": 8,
	"guard_hover": 13,
}

@onready var basic_rules_button: Button = %BasicRules
@onready var professor_button: Button = %Professor
@onready var canteen_staff_button: Button = %CanteenStaff
@onready var guard_button: Button = %Guard
@onready var bookmark_button: Button = %"Bookmark (Red)"

# If you have flip buttons in scene, keep these exact node names or adjust
@onready var flip_right_button: Button = get_node_or_null("FlipRight")
@onready var flip_left_button: Button = get_node_or_null("FlipLeft")

var current_frame := 0
var total_frames := 10

# =============================
# READY
# =============================
func _ready():
	add_to_group("draggable_documents")

	handbook.visible = false

	if handbook_opened_sprite:
		handbook_opened_sprite.stop()
		handbook_opened_sprite.frame = 0
		handbook_opened_sprite.visible = true

	# Reconnect button logic
	if basic_rules_button:
		basic_rules_button.mouse_entered.connect(_on_basic_rules_hover)
		basic_rules_button.mouse_exited.connect(_on_basic_rules_unhover)
		basic_rules_button.pressed.connect(_on_basic_rules_clicked)

	if professor_button:
		professor_button.mouse_entered.connect(_on_professor_hover)
		professor_button.mouse_exited.connect(_on_professor_unhover)
		professor_button.pressed.connect(_on_professor_clicked)

	if canteen_staff_button:
		canteen_staff_button.mouse_entered.connect(_on_canteen_staff_hover)
		canteen_staff_button.mouse_exited.connect(_on_canteen_staff_unhover)
		canteen_staff_button.pressed.connect(_on_canteen_staff_clicked)

	if guard_button:
		guard_button.mouse_entered.connect(_on_guard_hover)
		guard_button.mouse_exited.connect(_on_guard_unhover)
		guard_button.pressed.connect(_on_guard_clicked)

	if bookmark_button:
		bookmark_button.pressed.connect(_on_bookmark_clicked)

	if flip_right_button:
		flip_right_button.pressed.connect(_on_flip_right_pressed)

	if flip_left_button:
		flip_left_button.pressed.connect(_on_flip_left_pressed)

	update_button_visibility()

# =============================
# PROCESS
# =============================
func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

# =============================
# Use _unhandled_input instead of _input
# so buttons get first chance to receive click
# =============================
func _unhandled_input(event):
	if not handbook.visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if contains_point(get_global_mouse_position()) and _is_topmost_document_under_mouse():
				_try_start_drag()
		else:
			_stop_drag()

# =============================
# Drag
# =============================
func _try_start_drag():
	var mouse_pos = get_global_mouse_position()

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

func set_active(value):
	is_active = value

# =============================
# Manager
# =============================
func _get_manager():
	return get_tree().get_first_node_in_group("document_manager")

func _get_highest_z_index_among_documents() -> int:
	var highest := 0

	for node in get_tree().get_nodes_in_group("draggable_documents"):
		if node is Node2D:
			highest = max(highest, node.z_index)

	return highest

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

# =============================
# Hitbox for handbook dragging
# =============================
func contains_point(point):
	if not handbook.visible:
		return false

	if handbook_opened_sprite == null:
		return false

	if handbook_opened_sprite.sprite_frames == null:
		return false

	var tex = handbook_opened_sprite.sprite_frames.get_frame_texture(
		handbook_opened_sprite.animation,
		handbook_opened_sprite.frame
	)

	if tex == null:
		return false

	var size = tex.get_size() * handbook_opened_sprite.scale
	var center = handbook_opened_sprite.global_position
	var rect = Rect2(center - size / 2, size)

	return rect.has_point(point)

# =============================
# Open / Close Handbook
# =============================
func _on_button_pressed() -> void:
	handbook.visible = !handbook.visible

	if handbook.visible:
		z_index = _get_highest_z_index_among_documents() + 1

		if handbook_opened_sprite:
			handbook_opened_sprite.visible = true
			handbook_opened_sprite.stop()

		current_frame = page_frames["contents"]
		handbook_opened_sprite.frame = current_frame

		update_button_visibility()
		play_page_turn_sfx()
	else:
		_stop_drag()

# =============================
# SFX
# =============================
func play_page_turn_sfx() -> void:
	if page_turn_sfx and page_turn_sfx.stream:
		if page_turn_sfx.playing:
			page_turn_sfx.stop()
		page_turn_sfx.play()

# =============================
# Flip Right
# =============================
func _on_flip_right_pressed():
	print("FLIP RIGHT PRESSED")

	if current_frame >= total_frames - 1:
		print("Already at last page")
		return

	play_page_turn_sfx()
	advance_frame(1)
	update_button_visibility()

# =============================
# Flip Left
# =============================
func _on_flip_left_pressed():
	print("FLIP LEFT PRESSED")

	if current_frame <= 0:
		print("Already at first page")
		return

	play_page_turn_sfx()
	advance_frame(-1)
	update_button_visibility()

# =============================
# Advance Frame
# =============================
func advance_frame(direction):
	current_frame += direction
	current_frame = clamp(current_frame, 0, total_frames - 1)

	handbook_opened_sprite.frame = current_frame
	print("Current frame after advance: ", current_frame)

# =============================
# Button visibility control
# =============================
func update_button_visibility():
	if current_frame == page_frames["contents"]:
		basic_rules_button.disabled = false
		basic_rules_button.mouse_filter = Control.MOUSE_FILTER_STOP

		professor_button.disabled = false
		professor_button.mouse_filter = Control.MOUSE_FILTER_STOP

		canteen_staff_button.disabled = false
		canteen_staff_button.mouse_filter = Control.MOUSE_FILTER_STOP

		guard_button.disabled = false
		guard_button.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		basic_rules_button.disabled = true
		basic_rules_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

		professor_button.disabled = true
		professor_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

		canteen_staff_button.disabled = true
		canteen_staff_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

		guard_button.disabled = true
		guard_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

# =============================
# BASIC RULES BUTTON
# =============================
func _on_basic_rules_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["basic_rules_hover"]

func _on_basic_rules_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_basic_rules_clicked():
	play_page_turn_sfx()

	current_frame = page_frames["basic_rules"]
	handbook_opened_sprite.frame = current_frame

	update_button_visibility()

# =============================
# PROFESSOR BUTTON
# =============================
func _on_professor_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["professor_hover"]

func _on_professor_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_professor_clicked():
	play_page_turn_sfx()

	current_frame = page_frames["professor1"]
	handbook_opened_sprite.frame = current_frame

	update_button_visibility()

# =============================
# CANTEEN STAFF BUTTON
# =============================
func _on_canteen_staff_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["canteen_staff_hover"]

func _on_canteen_staff_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_canteen_staff_clicked():
	play_page_turn_sfx()

	current_frame = page_frames["canteen_staff"]
	handbook_opened_sprite.frame = current_frame

	update_button_visibility()

# =============================
# GUARD BUTTON
# =============================
func _on_guard_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["guard_hover"]

func _on_guard_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_guard_clicked():
	play_page_turn_sfx()

	current_frame = page_frames["guard"]
	handbook_opened_sprite.frame = current_frame

	update_button_visibility()

# =============================
# BOOKMARK BUTTON
# =============================
func _on_bookmark_clicked():
	play_page_turn_sfx()

	current_frame = page_frames["contents"]
	handbook_opened_sprite.frame = current_frame

	update_button_visibility()
