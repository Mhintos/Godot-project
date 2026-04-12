extends Control

signal conversation_finished

@export var right_safe_min_x: float = 180.0
@export var right_safe_max_x: float = 820.0
@export var lever_block_x: float = 860.0
@export var lever_block_y: float = 430.0
@export var lever_block_width: float = 220.0
@export var lever_block_height: float = 220.0
@export var lever_avoid_margin: float = 18.0
@export var vertical_avoid_step: float = 36.0
@export var max_upward_avoid_steps: int = 6

@export var appear_interval: float = 2.5
@export var stay_duration: float = 3.5

@export var move_up_distance: float = 100.0
@export var left_x: float = 20.0
@export var right_x: float = 420.0
@export var left_gap: float = 10.0
@export var right_gap: float = 10.0
@export var first_bubble_y: float = 70.0
@export var right_first_bubble_y: float = 120.0

@export var min_read_time: float = 3.5
@export var max_read_time: float = 3.5
@export var letters_per_second: float = 18.0
@export var fast_forward_multiplier: float = 1.0

var left_sound: AudioStream = null
var right_sound: AudioStream = null
var true_form_sound: AudioStream = null
var _true_form_mode: bool = false

var active_bubbles: Array = []
var current_messages: Array = []
var current_index: int = 0
var top_y: float = 20.0

var _conversation_id: int = 0
var _running: bool = false
var _fast_forward: bool = false

var _advance_timer: SceneTreeTimer = null
var _audio_player: AudioStreamPlayer = null

var _fast_forward_click_count: int = 0

func _ready() -> void:
	top_y = first_bubble_y

	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "DialogueAudioPlayer"
	add_child(_audio_player)

	visible = false

func set_true_form_mode(enabled: bool) -> void:
	_true_form_mode = enabled

func is_conversation_running() -> bool:
	return _running

func set_fast_forward(enabled: bool) -> void:
	_fast_forward = enabled

func stop_conversation(clear_bubbles: bool = true) -> void:
	_fast_forward_click_count = 0
	_conversation_id += 1
	_running = false
	_fast_forward = false
	current_messages.clear()
	current_index = 0
	_advance_timer = null

	if clear_bubbles:
		_clear_all_bubbles()

	visible = false

func start_conversation(messages: Array) -> void:
	stop_conversation(true)

	if messages.is_empty():
		conversation_finished.emit()
		return

	current_messages = _sanitize_messages(messages)
	if current_messages.is_empty():
		conversation_finished.emit()
		return

	visible = true
	_running = true
	_fast_forward = false
	current_index = 0
	top_y = first_bubble_y
	_conversation_id += 1
	_fast_forward_click_count = 0

	_spawn_conversation_loop(_conversation_id)

func _spawn_conversation_loop(conversation_id: int) -> void:
	while _running and conversation_id == _conversation_id and current_index < current_messages.size():
		var msg: Dictionary = current_messages[current_index]
		var bubble := _create_bubble(str(msg["text"]), str(msg["side"]))

		if bubble == null:
			current_index += 1
			continue

		await get_tree().process_frame

		if not _running or conversation_id != _conversation_id:
			if is_instance_valid(bubble):
				bubble.queue_free()
			return

		_place_bubble(bubble)
		_play_bubble_sound(bubble.grow_from_right)

		if bubble.has_method("start"):
			bubble.start()

		var read_time := _get_message_read_time(str(msg["text"]))
		var adjusted_stay := read_time
		var adjusted_gap := appear_interval

		if _fast_forward:
			adjusted_stay *= fast_forward_multiplier
			adjusted_gap *= fast_forward_multiplier

		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = adjusted_stay
		timer.timeout.connect(_on_bubble_timer_expired.bind(bubble, conversation_id))
		add_child(timer)
		timer.start()

		active_bubbles.append({
			"node": bubble,
			"timer": timer
		})

		current_index += 1

		_advance_timer = get_tree().create_timer(max(0.05, adjusted_gap))
		await _advance_timer.timeout

	if not _running or conversation_id != _conversation_id:
		return

	_running = false
	_fast_forward = false
	conversation_finished.emit()

func _sanitize_messages(messages: Array) -> Array:
	var cleaned: Array = []

	for msg in messages:
		if typeof(msg) != TYPE_DICTIONARY:
			continue

		if not msg.has("text"):
			continue

		var text := str(msg.get("text", "")).strip_edges()
		if text == "":
			continue

		var side := str(msg.get("side", "left")).to_lower()
		if side != "right":
			side = "left"

		cleaned.append({
			"text": text,
			"side": side
		})

	return cleaned

func _create_bubble(text: String, side: String) -> RichTextLabel:
	var scene: PackedScene = preload("res://scene/DialogueSystem/message_bubble.tscn")
	var bubble = scene.instantiate()

	if bubble == null:
		return null

	bubble.text = text
	bubble.grow_from_right = (side == "right")
	add_child(bubble)
	bubble.visible = true
	bubble.modulate.a = 1.0

	return bubble

func _get_lever_block_rect() -> Rect2:
	return Rect2(
		Vector2(lever_block_x, lever_block_y),
		Vector2(lever_block_width, lever_block_height)
	)

func _get_bubble_rect(bubble: RichTextLabel, pos: Vector2) -> Rect2:
	return Rect2(pos, bubble.size)

func _resolve_right_bubble_safe_position(bubble: RichTextLabel, start_pos: Vector2) -> Vector2:
	var block_rect := _get_lever_block_rect().grow(lever_avoid_margin)
	var candidate := start_pos

	for _i in range(max_upward_avoid_steps):
		var candidate_rect := _get_bubble_rect(bubble, candidate)
		if not candidate_rect.intersects(block_rect):
			return candidate

		candidate.y += vertical_avoid_step

	var final_rect := _get_bubble_rect(bubble, candidate)
	if final_rect.intersects(block_rect):
		candidate.x = min(candidate.x, block_rect.position.x - bubble.size.x - lever_avoid_margin)
		candidate.x = clamp(candidate.x, right_safe_min_x, right_safe_max_x - bubble.size.x)

	return candidate

func _place_bubble(bubble: RichTextLabel) -> void:
	var start_y: float = right_first_bubble_y if bubble.grow_from_right else first_bubble_y

	if not active_bubbles.is_empty():
		var bottom_bubble: RichTextLabel = null
		var bottom_y: float = -999999.0

		for entry in active_bubbles:
			var b = entry["node"]
			if is_instance_valid(b) and b.position.y > bottom_y:
				bottom_y = b.position.y
				bottom_bubble = b

		if bottom_bubble != null:
			var gap := right_gap if bubble.grow_from_right else left_gap
			start_y = bottom_bubble.position.y + bottom_bubble.size.y + gap

	if bubble.grow_from_right:
		var original_pos := Vector2(right_x - bubble.size.x, start_y)
		var block_rect := _get_lever_block_rect().grow(lever_avoid_margin)
		var bubble_rect := _get_bubble_rect(bubble, original_pos)

		if bubble_rect.intersects(block_rect):
			bubble.position = _resolve_right_bubble_safe_position(bubble, original_pos)
		else:
			bubble.position = original_pos
	else:
		bubble.position = Vector2(left_x, start_y)

	if active_bubbles.is_empty():
		top_y = first_bubble_y
		
func _get_message_read_time(_text: String) -> float:
	return stay_duration

func _play_bubble_sound(is_right_side: bool) -> void:
	if _audio_player == null:
		return

	var stream: AudioStream = null

	if _true_form_mode and true_form_sound != null:
		stream = true_form_sound
	elif is_right_side and right_sound != null:
		stream = right_sound
	elif not is_right_side and left_sound != null:
		stream = left_sound

	if stream == null:
		return

	_audio_player.stop()
	_audio_player.stream = stream
	_audio_player.play()

func _on_bubble_timer_expired(bubble: RichTextLabel, conversation_id: int) -> void:
	if conversation_id != _conversation_id:
		return

	if not is_instance_valid(bubble):
		return

	var index := -1
	for i in range(active_bubbles.size()):
		if active_bubbles[i]["node"] == bubble:
			index = i
			break

	if index == -1:
		return

	var timer: Timer = active_bubbles[index]["timer"]
	if is_instance_valid(timer):
		timer.stop()
		timer.queue_free()

	active_bubbles.remove_at(index)
	await _move_bubble_up_and_remove(bubble, conversation_id)
	_reposition_stack()

func _move_bubble_up_and_remove(bubble: RichTextLabel, conversation_id: int) -> void:
	if not is_instance_valid(bubble):
		return

	if conversation_id != _conversation_id:
		if is_instance_valid(bubble):
			bubble.queue_free()
		return

	var tween := create_tween()
	var target_y := bubble.position.y - move_up_distance

	tween.tween_property(bubble, "position:y", target_y, 0.22).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.22)

	await tween.finished

	if is_instance_valid(bubble):
		bubble.queue_free()

func _reposition_stack() -> void:
	var remaining_left: Array = []
	var remaining_right: Array = []

	for entry in active_bubbles:
		var bubble = entry["node"]
		if not is_instance_valid(bubble):
			continue

		if bubble.grow_from_right:
			remaining_right.append(bubble)
		else:
			remaining_left.append(bubble)

	remaining_left.sort_custom(func(a, b): return a.position.y < b.position.y)
	remaining_right.sort_custom(func(a, b): return a.position.y < b.position.y)

	var left_y: float = first_bubble_y
	for bubble in remaining_left:
		var left_target: Vector2 = Vector2(left_x, left_y)
		var left_tween := create_tween()
		left_tween.tween_property(bubble, "position", left_target, 0.18).set_ease(Tween.EASE_OUT)
		left_y += bubble.size.y + left_gap

	var right_y: float = right_first_bubble_y
	for bubble in remaining_right:
		var original_pos: Vector2 = Vector2(right_x - bubble.size.x, right_y)
		var block_rect: Rect2 = _get_lever_block_rect().grow(lever_avoid_margin)
		var bubble_rect: Rect2 = _get_bubble_rect(bubble, original_pos)

		var target_pos: Vector2 = original_pos
		if bubble_rect.intersects(block_rect):
			target_pos = _resolve_right_bubble_safe_position(bubble, original_pos)

		# Never move right bubbles downward.
		if target_pos.y > bubble.position.y:
			target_pos.y = bubble.position.y

		var right_tween := create_tween()
		right_tween.tween_property(bubble, "position", target_pos, 0.18).set_ease(Tween.EASE_OUT)

		right_y = max(target_pos.y, bubble.position.y) + bubble.size.y + right_gap

func _clear_all_bubbles() -> void:
	for entry in active_bubbles:
		var bubble = entry.get("node", null)
		var timer = entry.get("timer", null)

		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()

		if is_instance_valid(bubble):
			bubble.queue_free()

	active_bubbles.clear()

	for child in get_children():
		if child is Timer and child.name != "DialogueAudioPlayer":
			child.stop()
			child.queue_free()
		elif child is RichTextLabel:
			child.queue_free()

func _gui_input(event: InputEvent) -> void:
	if not _running:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fast_forward_click_count += 1

		if _fast_forward_click_count >= 2:
			_fast_forward = true
