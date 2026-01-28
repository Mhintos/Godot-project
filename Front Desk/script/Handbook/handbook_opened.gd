extends Node2D

#Variables for Drag and Drop
var selected = false
var mouse_offset = Vector2(0,0)

#Variables for Flipping the Book
var flip = false
@onready var book: AnimatedSprite2D = %HandbookOpen
var current_frame = 0
var total_frames = 7
var frame_duration = 0.1

func _ready() -> void:
	book.stop() # Make sure the sprite isn't auto-playing
	book.frame = 0   # Set it to the first frame

#Functions for Flipping the Book
func _on_flip_right_pressed():
	var max_frame = 10
	if current_frame >= max_frame:
		current_frame = 0
	else:
		advance_frame(1)

func _on_flip_left_pressed():
	advance_frame(-1)  # Move backward one frame
	
func advance_frame(direction):
	var _flip_length = book.sprite_frames.get_frame_count(book.animation) # Get the total number of frames in the current animation
	book.frame += direction # Update the current frame
	current_frame = wrapi(current_frame, 0 , total_frames) # Wrap the frame counter around so it loops, wrapi keeps the value between 0 and total_frame

#Functions for Drag and Drop
func _process(_delta):
	if selected:
		followMouse()

#Makes object follow the mouse position where we are dragging it
func followMouse():
	position = get_global_mouse_position() + mouse_offset

@warning_ignore("unused_parameter")
func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_offset = position - get_global_mouse_position()
				selected = true
			else:
				selected = false
