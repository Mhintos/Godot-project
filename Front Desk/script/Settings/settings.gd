extends Node2D 

@onready var volume_slider = $CanvasLayer/VolumeSlider
@onready var back_button = $CanvasLayer/BackButton

@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

func _ready() -> void:
	var db = AudioServer.get_bus_volume_db(0)
	volume_slider.value = db_to_linear(db)


func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))


func _on_back_button_hovered() -> void:
	if hover_sfx:
		hover_sfx.play()


func _on_back_button_pressed() -> void:
	if click_sfx:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file("res://scene/Main Menu/Mainmenu.tscn")
