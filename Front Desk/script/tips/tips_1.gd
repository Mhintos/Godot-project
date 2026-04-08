extends Node2D

@export var main_menu_path: String = "res://scene/Main Menu/Mainmenu.tscn"
@export var tips2_scene_path: String = "res://scene/tips/tips_2.tscn"

@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX
@onready var main_menu_music: AudioStreamPlayer = $TipsMusic

@onready var back_button = $CanvasLayer/BackButton  # ✅ Added
@onready var next_button = $CanvasLayer/NextButton  # ✅ Added

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect hover signals
	back_button.mouse_entered.connect(_on_button_hovered)
	next_button.mouse_entered.connect(_on_button_hovered)

# Called every frame. '_delta' is unused, so we prefix with underscore
func _process(_delta: float) -> void:
	pass

# Hover SFX function
func _on_button_hovered() -> void:
	if hover_sfx.stream:
		if hover_sfx.playing:
			hover_sfx.stop()
		hover_sfx.play()

func _on_back_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished
	get_tree().change_scene_to_file(main_menu_path)

func _on_next_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished
	get_tree().change_scene_to_file(tips2_scene_path)
