extends Node2D

func _on_home_button_pressed() -> void:
	$ClickSound.play()
	get_tree().change_scene_to_file("res://scene/mainmenu/node_2dmainmenu.tscn")
