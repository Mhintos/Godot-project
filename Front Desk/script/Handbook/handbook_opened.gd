extends Node2D

#Variables for Drag and Drop
var selected = false
var mouse_offset = Vector2(0,0)

#Variables for Page Navigation
var page_frames = {
	"contents": 0, #The main contents page frame
	"basic_rules": 1, #The basic rules page frame
	"basic_rules_hover": 7, #The hover state for basic rules
	"professor1": 2, #The employees page frame
	"professor_hover": 8, #The hover state for professor
	"guard": 3, #E-1 page frame
	"guard_hover": 9, #The hover state for E-1
	"service_master": 4, #E-2 page frame
	"service_master_hover": 10, #The hover state for E-2
	"school_caterer": 5, #E-3 page frame
	"school_caterer_hover": 11, #The hover state for E-3
}
@onready var basic_rules_button: Button = %BasicRules
@onready var professor_button: Button = %Professor
@onready var guard_button: Button = %Guard
@onready var service_master_button: Button = %ServiceMaster
@onready var school_caterer_button: Button = %SchoolCaterer
@onready var bookmark_button: Button = %"Bookmark (Red)"

#Variables for Handbook
@onready var handbook_icon: Node2D = %HandbookIcon
@onready var handbook: Node2D = %Handbook

#Variables for Flipping the Book
var flip = false
@onready var handbook_opened_sprite = %HandbookOpen
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
	professor_button.mouse_entered.connect(_on_professor_hover)
	professor_button.mouse_exited.connect(_on_professor_unhover)
	professor_button.pressed.connect(_on_professor_clicked)
	guard_button.mouse_entered.connect(_on_guard_hover)
	guard_button.mouse_exited.connect(_on_guard_unhover)
	guard_button.pressed.connect(_on_guard_clicked)
	service_master_button.mouse_entered.connect(_on_service_master_hover)
	service_master_button.mouse_exited.connect(_on_service_master_unhover)
	service_master_button.pressed.connect(_on_service_master_clicked)
	school_caterer_button.mouse_entered.connect(_on_school_caterer_hover)
	school_caterer_button.mouse_exited.connect(_on_school_caterer_unhover)
	school_caterer_button.pressed.connect(_on_school_caterer_clicked)
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
		
		professor_button.disabled = false
		professor_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		guard_button.disabled = false
		guard_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		service_master_button.disabled = false
		service_master_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		school_caterer_button.disabled = false
		school_caterer_button.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		basic_rules_button.disabled = true
		basic_rules_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		professor_button.disabled = true
		professor_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		guard_button.disabled = true
		guard_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		service_master_button.disabled = true
		service_master_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		school_caterer_button.disabled = true
		school_caterer_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	handbook.visible = !handbook.visible
	if handbook.visible:
		handbook_opened_sprite.global_position = Vector2(800, 350) #Places book consistently on the same spot
		current_frame = page_frames["contents"]
		handbook_opened_sprite.frame = current_frame
		basic_rules_button.disabled = false
		professor_button.disabled = false
		guard_button.disabled = false
		service_master_button.disabled = false
		school_caterer_button.disabled = false

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
	professor_button.disabled = true
	guard_button.disabled = true
	service_master_button.disabled = true
	school_caterer_button.disabled = true

func _on_professor_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["professor_hover"]

func _on_professor_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_professor_clicked():
	current_frame = page_frames["professor1"]
	handbook_opened_sprite.frame = current_frame
	basic_rules_button.disabled = true
	professor_button.disabled = true
	guard_button.disabled = true
	service_master_button.disabled = true
	school_caterer_button.disabled = true

func _on_guard_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["guard_hover"]

func _on_guard_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_guard_clicked():
	current_frame = page_frames["guard"]
	handbook_opened_sprite.frame = current_frame
	basic_rules_button.disabled = true
	professor_button.disabled = true
	guard_button.disabled = true
	service_master_button.disabled = true
	school_caterer_button.disabled = true

func _on_service_master_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["service_master_hover"]

func _on_service_master_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_service_master_clicked():
	current_frame = page_frames["service_master"]
	handbook_opened_sprite.frame = current_frame
	basic_rules_button.disabled = true
	professor_button.disabled = true
	guard_button.disabled = true
	service_master_button.disabled = true
	school_caterer_button.disabled = true

func _on_school_caterer_hover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["school_caterer_hover"]

func _on_school_caterer_unhover():
	if current_frame == page_frames["contents"]:
		handbook_opened_sprite.frame = page_frames["contents"]

func _on_school_caterer_clicked():
	current_frame = page_frames["school_caterer"]
	handbook_opened_sprite.frame = current_frame
	basic_rules_button.disabled = true
	professor_button.disabled = true
	guard_button.disabled = true
	service_master_button.disabled = true
	school_caterer_button.disabled = true

func _on_bookmark_clicked():
	current_frame = page_frames["contents"]
	handbook_opened_sprite.frame = current_frame
	basic_rules_button.disabled = false
	professor_button.disabled = false
	guard_button.disabled = false
	service_master_button.disabled = false
	school_caterer_button.disabled = false
