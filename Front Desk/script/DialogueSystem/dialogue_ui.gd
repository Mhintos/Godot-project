extends Control

var top_y: float = 20   # Stores the Y where the first bubble appeared

signal conversation_finished

# --------------------------------------------------------------------
# EXPORT VARIABLES (set in Inspector)
# --------------------------------------------------------------------
# (No single bubbles export – we now use dialogues array)
@export var appear_interval: float = 2.5         # Time between new bubbles appearing
@export var stay_duration: float = 3.5           # How long each bubble stays before leaving
@export var move_up_distance: float = 100.0      # How far the leaving bubble moves up
@export var shift_amount: float = 40.0           # How much bubbles below shift up when one leaves
@export var left_x: float = 20                   # X position for left-side bubbles
@export var right_x: float = 420                 # X position for right-side bubbles
@export var left_gap: float = 10                 # Gap between left-side bubbles
@export var right_gap: float = 10                # Gap between right-side bubbles
@export var first_bubble_y: float = 70
@export var left_sound: AudioStream  # assign in Inspector
@export var right_sound: AudioStream
@export var true_form_sound: AudioStream

# --------------------------------------------------------------------
# INTERNAL VARIABLES
# --------------------------------------------------------------------
var active_bubbles = []          # Each entry: { "node": bubble, "timer": timer, "y": y_position }
var current_index = 0
var dialogues = []               # List of chapters (each chapter is an Array of RichTextLabel nodes)
var current_dialogue_index = 0
var current_bubbles = []      # Will hold an Array of RichTextLabel for the active chapter
var is_true_form_conversation := false

func _ready():
	return


func start_dialogue(chapter_index: int):
	if chapter_index >= dialogues.size():
		return
	current_bubbles = dialogues[chapter_index]
	current_index = 0
	active_bubbles.clear()
	top_y = first_bubble_y
	# Hide all bubbles in the new chapter
	for bubble in current_bubbles:
		bubble.visible = false
		bubble.modulate.a = 1.0
	spawn_next_bubble()

func spawn_next_bubble():
	if current_index >= current_bubbles.size():
		conversation_finished.emit()
		return

	var bubble = current_bubbles[current_index]  # bubble is RichTextLabel

	# Make sure bubble is in the tree (it should be, but just in case)
	if bubble.get_parent() != self:
		add_child(bubble)
	bubble.visible = true

	# Wait one frame for size to be calculated
	await get_tree().process_frame

	# --- X alignment (left/right edges) ---
	if bubble.grow_from_right:
		# Align right edge at right_x
		bubble.position.x = right_x - bubble.size.x
	else:
		# Align left edge at left_x
		bubble.position.x = left_x

	# --- Y stacking with consistent gap ---
	if active_bubbles.size() == 0:
		bubble.position.y = first_bubble_y
		top_y = first_bubble_y   # Remember this as the top anchor
	else:
		# Find the bottommost active bubble
		var bottom_bubble = null
		var bottom_y = -999999
		for entry in active_bubbles:
			var b = entry.node
			if b.position.y > bottom_y:
				bottom_y = b.position.y
				bottom_bubble = b
		var gap = right_gap if bubble.grow_from_right else left_gap
		bubble.position.y = bottom_bubble.position.y + bottom_bubble.size.y + gap

	# Start animation
	bubble.start()

	var side = bubble.get_meta("side", "")
	var stream: AudioStream = null
	if is_true_form_conversation and true_form_sound:
		stream = true_form_sound
	elif side == "left":
		stream = left_sound
	elif side == "right":
		stream = right_sound

	if stream:
		var player = AudioStreamPlayer.new()
		player.stream = stream
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)

	# Timer for staying duration
	var timer = Timer.new()
	timer.wait_time = stay_duration
	timer.one_shot = true
	timer.timeout.connect(_on_bubble_timer_expired.bind(bubble))
	add_child(timer)
	timer.start()

	# Store in active list
	active_bubbles.append({
		"node": bubble,
		"timer": timer,
		"y": bubble.position.y
	})

	current_index += 1

	# Schedule next bubble
	await get_tree().create_timer(appear_interval).timeout
	spawn_next_bubble()

func _on_bubble_timer_expired(bubble):
	if not is_instance_valid(bubble):
		return
	var index = -1
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
	reposition_stack()   # instead of shift_bubbles_below

func move_bubble_up_and_remove(bubble):
	if not is_instance_valid(bubble):
		return
	print("Moving and fading bubble: ", bubble.text)
	var tween = create_tween()
	var target_y = bubble.position.y - move_up_distance
	tween.tween_property(bubble, "position:y", target_y, 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.5)
	await tween.finished
	if is_instance_valid(bubble):
		bubble.visible = false
	else:
		print("Bubble already freed after tween")

func reposition_stack():
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

func set_true_form_mode(enabled: bool) -> void:
	is_true_form_conversation = enabled

# Starts a conversation with a list of messages
# messages: Array of dictionaries, each with "text" (String) and "side" (String, "left" or "right")
func start_conversation(messages: Array) -> void:
	for entry in active_bubbles:
		var timer = entry.timer
		if timer and is_instance_valid(timer):
			timer.stop()
	_clear_all_bubbles()
# Build the dialogue chapters: one chapter with all messages
	var chapter = []
	for msg in messages:
		var bubble =  _create_bubble(msg["text"], msg["side"])
		if bubble:
			chapter.append(bubble)
# Replace the dialogues array with this single chapter
	if chapter.size() == 0:
		return
	dialogues = [chapter]
	current_dialogue_index = 0
	start_dialogue(0)

# Helper to create a bubble node (if you don't have pre‑placed ones)
func _create_bubble(text: String, side: String) -> RichTextLabel:
	var bubble = preload("res://scene/DialogueSystem/message_bubble.tscn").instantiate()
	bubble.text = text
	bubble.grow_from_right = (side == "right")
	bubble.set_meta("side", side)
	add_child(bubble)
<<<<<<< Updated upstream
=======

	var stream: AudioStream = null
	if is_true_form_conversation and true_form_sound:
		stream = true_form_sound
	if side == "left":
		stream = left_sound
	elif side == "right":
		stream = right_sound

	if stream:
		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = 0.0  # ensure full volume
		add_child(player)
		player.play()
		player.finished.connect(func(): print("Sound finished for ", side))
		# Do NOT queue_free immediately; keep it for 2 seconds then free
		player.queue_free()
	else:
		print("No stream for side ", side)

>>>>>>> Stashed changes
	return bubble

func _play_sound(player: AudioStreamPlayer):
	if player and player.stream:
		player.play()

func _clear_all_bubbles() -> void:
	for child in get_children():
		if child is RichTextLabel:
			child.queue_free()
		elif child is Timer:
			child.stop()
			child.queue_free()
	active_bubbles.clear()
	current_bubbles = []
