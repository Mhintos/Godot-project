extends Control

var top_y: float = 20

signal conversation_finished

@export var appear_interval: float = 2.5
@export var stay_duration: float = 3.5
@export var move_up_distance: float = 100.0
@export var shift_amount: float = 40.0
@export var left_x: float = 20
@export var right_x: float = 420
@export var left_gap: float = 10
@export var right_gap: float = 10
@export var first_bubble_y: float = 70

var active_bubbles = []
var current_index = 0
var dialogues = []
var current_dialogue_index = 0
var current_bubbles = []

var left_sound: AudioStream = null
var right_sound: AudioStream = null
var true_form_sound: AudioStream = null
var _true_form_mode: bool = false

func _ready() -> void:
	return

func set_true_form_mode(enabled: bool) -> void:
	_true_form_mode = enabled

func start_dialogue(chapter_index: int) -> void:
	if chapter_index >= dialogues.size():
		return

	current_bubbles = dialogues[chapter_index]
	current_index = 0
	active_bubbles.clear()
	top_y = first_bubble_y

	for bubble in current_bubbles:
		bubble.visible = false
		bubble.modulate.a = 1.0

	spawn_next_bubble()

func spawn_next_bubble() -> void:
	if current_index >= current_bubbles.size():
		conversation_finished.emit()
		return

	var bubble = current_bubbles[current_index]

	if bubble.get_parent() != self:
		add_child(bubble)
	bubble.visible = true

	await get_tree().process_frame

	if bubble.grow_from_right:
		bubble.position.x = right_x - bubble.size.x
	else:
		bubble.position.x = left_x

	if active_bubbles.size() == 0:
		bubble.position.y = first_bubble_y
		top_y = first_bubble_y
	else:
		var bottom_bubble = null
		var bottom_y = -999999.0

		for entry in active_bubbles:
			var b = entry.node
			if b.position.y > bottom_y:
				bottom_y = b.position.y
				bottom_bubble = b

		var gap = right_gap if bubble.grow_from_right else left_gap
		bubble.position.y = bottom_bubble.position.y + bottom_bubble.size.y + gap

	_play_bubble_sound(bubble.grow_from_right)

	bubble.start()

	var timer = Timer.new()
	timer.wait_time = stay_duration
	timer.one_shot = true
	timer.timeout.connect(_on_bubble_timer_expired.bind(bubble))
	add_child(timer)
	timer.start()

	active_bubbles.append({
		"node": bubble,
		"timer": timer,
		"y": bubble.position.y
	})

	current_index += 1

	await get_tree().create_timer(appear_interval).timeout
	spawn_next_bubble()

func _play_bubble_sound(is_right_side: bool) -> void:
	var stream: AudioStream = null

	if _true_form_mode and true_form_sound != null:
		stream = true_form_sound
	elif is_right_side and right_sound != null:
		stream = right_sound
	elif not is_right_side and left_sound != null:
		stream = left_sound

	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _on_bubble_timer_expired(bubble) -> void:
	if not is_instance_valid(bubble):
		return

	var index := -1
	for i in range(active_bubbles.size()):
		if active_bubbles[i].node == bubble:
			index = i
			break

	if index == -1:
		return

	var timer = active_bubbles[index].timer
	remove_child(timer)
	timer.queue_free()

	active_bubbles.remove_at(index)
	await move_bubble_up_and_remove(bubble)
	reposition_stack()

func move_bubble_up_and_remove(bubble) -> void:
	if not is_instance_valid(bubble):
		return

	var tween = create_tween()
	var target_y = bubble.position.y - move_up_distance
	tween.tween_property(bubble, "position:y", target_y, 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.5)
	await tween.finished

	if is_instance_valid(bubble):
		bubble.visible = false

func reposition_stack() -> void:
	var remaining = []

	for entry in active_bubbles:
		if is_instance_valid(entry.node):
			remaining.append(entry.node)

	remaining.sort_custom(func(a, b): return a.position.y < b.position.y)

	var current_y = top_y

	for bubble in remaining:
		var gap = right_gap if bubble.grow_from_right else left_gap
		var target_y = current_y
		var tween = create_tween()
		tween.tween_property(bubble, "position:y", target_y, 0.3).set_ease(Tween.EASE_OUT)

		for entry in active_bubbles:
			if entry.node == bubble:
				entry.y = target_y
				break

		current_y = target_y + bubble.size.y + gap

func start_conversation(messages: Array) -> void:
	for entry in active_bubbles:
		var timer = entry.timer
		if timer and is_instance_valid(timer):
			timer.stop()

	_clear_all_bubbles()

	var chapter = []
	for msg in messages:
		var bubble = _create_bubble(msg["text"], msg["side"])
		if bubble:
			chapter.append(bubble)

	if chapter.size() == 0:
		return

	dialogues = [chapter]
	current_dialogue_index = 0
	start_dialogue(0)

func _create_bubble(text: String, side: String) -> RichTextLabel:
	var bubble = preload("res://scene/DialogueSystem/message_bubble.tscn").instantiate()
	bubble.text = text
	bubble.grow_from_right = (side == "right")
	add_child(bubble)
	return bubble

func _clear_all_bubbles() -> void:
	for child in get_children():
		if child is RichTextLabel:
			child.queue_free()
		elif child is Timer:
			child.stop()
			child.queue_free()
		elif child is AudioStreamPlayer:
			child.stop()
			child.queue_free()

	active_bubbles.clear()
	current_bubbles = []
