extends Node2D

# =============================
# Exported variables (must be at the top!)
# =============================

@export var game_scene_path: String = "res://GameScene.tscn"
@export var button_click_wav: AudioStream  # assign your WAV in the Inspector

# =============================
# Called when the scene is ready
# =============================
func _ready():
	# Connect Start and Quit buttons under CanvasLayer
	var start_button = get_node_or_null("CanvasLayer/StartButton")
	var quit_button = get_node_or_null("CanvasLayer/QuitButton")
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	else:
		print("StartButton not found!")
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	else:
		print("QuitButton not found!")

# =============================
# Function to play the button click sound
# =============================
func _play_button_sfx():
	if not button_click_wav:
		return  # do nothing if no WAV assigned
	
	# Create a temporary AudioStreamPlayer
	var sfx = AudioStreamPlayer.new()
	add_child(sfx)                 # add under MainMenu root
	sfx.stream = button_click_wav
	sfx.volume_db = 0
	sfx.bus = "Master"
	sfx.play()
	
	# Wait for the duration of the sound, then free the node
	var duration = sfx.stream.get_length()
	await get_tree().create_timer(duration).timeout
	sfx.queue_free()

# =============================
# Start button pressed
# =============================
func _on_start_pressed():
	_play_button_sfx()                    # play click sound
	await get_tree().process_frame        # wait one frame to ensure sound starts
	var scene_res = load(game_scene_path)
	if scene_res:
		get_tree().change_scene_to(scene_res)
	else:
		print("Game scene not found at: ", game_scene_path)

# =============================
# Quit button pressed
# =============================
func _on_quit_pressed():
	_play_button_sfx()                    # play click sound
	await get_tree().process_frame        # wait one frame
	get_tree().quit()
