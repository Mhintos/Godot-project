extends Node2D

func _on_start_button_pressed() -> void:
	print("START BUTTON PRESSED")
	$ClickSound.play()
	get_tree().change_scene_to_file("res://scene/ui/inspection_2d.tscn")

func _on_quit_button_pressed() -> void:
	$ClickSound.play()
	get_tree().quit()
