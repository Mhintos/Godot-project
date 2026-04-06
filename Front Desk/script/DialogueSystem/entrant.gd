# IMPORTANT NOTE: If you will change the code using AI, ASK IT TO KEEP THE COMMENTS PLEASE
#  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
extends RichTextLabel

@export var grow_from_right := true   # true = grows from right edge, false = from left

func _ready():
	# Start hidden
	scale = Vector2(0, 1)
	visible_characters = 0
	
	await get_tree().process_frame
	
	if grow_from_right:
		pivot_offset = Vector2(size.x, 0)   # grow leftwards
	else:
		pivot_offset = Vector2(0, 0)        # grow rightwards

# Call this to start the bubble's animation
func start():
	scale = Vector2(0, 1)
	visible_characters = 0
	grow_background()

func grow_background():
	var tween = create_tween()
		#Growth speed of bubble, just edit 0.3 seconds if you want changes
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).from(Vector2(0, 1))\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished
	start_typing()

func start_typing():
	var total_chars = text.length()
	var tween = create_tween()
	tween.tween_method(update_visible_chars, 0, total_chars, 1.0)
	# No extra waiting – bubble just stays visible after typing

func update_visible_chars(count):
	visible_characters = count
