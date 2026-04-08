extends Node2D

@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

@onready var back_button = $CanvasLayer/BackButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect hover signal
	back_button.mouse_entered.connect(_on_button_hovered)

# Called every frame. '_delta' unused
func _process(_delta: float) -> void:
	pass

# Hover SFX function
func _on_button_hovered() -> void:
	if hover_sfx.stream:
		if hover_sfx.playing:
			hover_sfx.stop()
		hover_sfx.play()

# Back button click
func _on_back_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished
	get_tree().change_scene_to_file("res://scene/tips/tips_1.tscn")
