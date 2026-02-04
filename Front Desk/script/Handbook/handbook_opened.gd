extends Node2D

#Variables for Drag and Drop
var selected = false
var mouse_offset = Vector2(0,0)

#Variables for Page Navigation
var page_frames = {
	"contents": 0, #The main contents page frame
	"basic_rules": 1, #The basic rules page frame
	"basic_rules_hover": 7, #The hover state for basic rules
	"employees": 2, #The employees page frame
	"employees_hover": 8, #The hover state for employees
	"e_one": 2, #E-1 page frame
	"e_one_hover": 9, #The hover state for E-1
	"e_two": 3, #E-2 page frame
	"e_two_hover": 10, #The hover state for E-2
	"e_three": 4, #E-3 page frame
	"e_three_hover": 11, #The hover state for E-3
	"e_four": 5, #E-4 page frame
	"e_four_hover": 12 #The hover state for E-4
}
@onready var basic_rules_button: Button = %BasicRules
@onready var employees_button: Button = %Employees
@onready var e_one_button: Button = %"E-1"
@onready var e_two_button: Button = %"E-2"
@onready var e_three_button: Button = %"E-3"
@onready var e_four_button: Button = %"E-4"
@onready var bookmark_button: Button = %"Bookmark (Red)"

#Variables for Handbook
@onready var handbook_opened_node2D: Node2D = %HandbookOpened

#Variables for Flipping the Book
var flip = false
@onready var handbook_opened_sprite: AnimatedSprite2D = %HandbookOpen
var current_frame = 0
var total_frames = 7
var frame_duration = 0.1

func _ready() -> void:
	handbook_opened_sprite.stop() # Make sure the sprite isn't auto-playing
	handbook_opened_sprite.frame = 0   # Set it to the first frame

	#First page button signals
	basic_rules_button.mouse_entered.connect(_on_basic_rules_hover)
	basic_rules_button.mouse_exited.connect(_on_basic_rules_unhover)
	basic_rules_button.pressed.connect(_on_basic_rules_clicked)
	employees_button.mouse_entered.connect(_on_employees_hover)
	employees_button.mouse_exited.connect(_on_employees_unhover)
	employees_button.pressed.connect(_on_employees_clicked)
	e_one_button.mouse_entered.connect(_on_e_one_hover)
	e_one_button.mouse_exited.connect(_on_e_one_unhover)
	e_one_button.pressed.connect(_on_e_one_clicked)
	e_two_button.mouse_entered.connect(_on_e_two_hover)
	e_two_button.mouse_exited.connect(_on_e_two_unhover)
	e_two_button.pressed.connect(_on_e_two_clicked)
	e_three_button.mouse_entered.connect(_on_e_three_hover)
	e_three_button.mouse_exited.connect(_on_e_three_unhover)
	e_three_button.pressed.connect(_on_e_three_clicked)
	e_four_button.mouse_entered.connect(_on_e_four_hover)
	e_four_button.mouse_exited.connect(_on_e_four_unhover)
	e_four_button.pressed.connect(_on_e_four_clicked)
	bookmark_button.pressed.connect(_on_bookmark_clicked)

#Functions for Flipping the Book
func _on_flip_right_pressed():
	print("FLIP RIGHT PRESSED")
	if current_frame >= total_frames - 1:
		print("Already at last page")
		return
	else:
		advance_frame(1)
	update_button_visibility()

func _on_flip_left_pressed():
	print("FLIP LEFT PRESSED")
	if current_frame <= 0:
		print ("Already at first page")
		return #It stops here
	else:
		advance_frame(-1)  # Move backward one frame
	update_button_visibility()

func advance_frame(direction):
	var _flip_length = handbook_opened_sprite.sprite_frames.get_frame_count(handbook_opened_sprite.animation) # Get the total number of frames in the current animation
	current_frame += direction # Update the current frame
	current_frame = wrapi(current_frame, 0 , total_frames) # Wrap the frame counter around so it loops, wrapi keeps the value between 0 and total_frame
	handbook_opened_sprite.frame = current_frame
	print("Current frame after advance: ", current_frame)

#Function for button visibility upon change of frames
func update_button_visibility():
	#Shows buttons only on the Contents page
	if current_frame == page_frames["contents"]:
		basic_rules_button.disabled = false
		basic_rules_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		employees_button.disabled = false
		employees_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		e_one_button.disabled = false
		e_one_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		e_two_button.disabled = false
		e_two_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		e_three_button.disabled = false
		e_three_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		e_four_button.disabled = false
		e_four_button.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		basic_rules_button.disabled = true
		basic_rules_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		employees_button.disabled = true
		employees_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		e_one_button.disabled = true
		e_one_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		e_two_button.disabled = true
		e_two_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		e_three_button.disabled = true
		e_three_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		e_four_button.disabled = true
		e_four_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
				var _mouse_pos = get_global_mouse_position()
				mouse_offset = position - get_global_mouse_position()
				selected = true
			else:
				selected = false

#For small handbook pop-up function
func _on_button_pressed() -> void:
	handbook_opened_node2D.visible = !handbook_opened_node2D.visible
	if handbook_opened_node2D.visible:
		handbook_opened_node2D.position = Vector2(800, 300) #Places book consistently on the same spot

#For First page button functions
func _on_basic_rules_hover():
	#For hover effect
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["basic_rules_hover"]

func _on_basic_rules_unhover():
	#For unhover effect
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_basic_rules_clicked():
	#For click function of the buttons
	current_frame = page_frames["basic_rules"]
	handbook_opened_sprite.frame = current_frame
	#For Button node to disappear to avoid interference with other pages
	basic_rules_button.disabled = true

func _on_employees_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["employees_hover"]

func _on_employees_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_employees_clicked():
	current_frame = page_frames["employees"]
	handbook_opened_sprite.frame = current_frame
	employees_button.disabled = true

func _on_e_one_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["e_one_hover"]

func _on_e_one_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_e_one_clicked():
	current_frame = page_frames["e_one"]
	handbook_opened_sprite.frame = current_frame
	e_one_button.disabled = true

func _on_e_two_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["e_two_hover"]

func _on_e_two_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_e_two_clicked():
	current_frame = page_frames["e_two"]
	handbook_opened_sprite.frame = current_frame
	e_two_button.disabled = true

func _on_e_three_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["e_three_hover"]

func _on_e_three_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_e_three_clicked():
	current_frame = page_frames["e_three"]
	handbook_opened_sprite.frame = current_frame
	e_three_button.disabled = true

func _on_e_four_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["e_four_hover"]

func _on_e_four_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_e_four_clicked():
	current_frame = page_frames["e_four"]
	handbook_opened_sprite.frame = current_frame
	e_four_button.disabled = true

func _on_bookmark_clicked():
	current_frame = page_frames["contents"]
	handbook_opened_sprite.frame = current_frame
