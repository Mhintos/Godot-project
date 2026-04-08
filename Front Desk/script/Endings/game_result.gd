extends Node

const ENDING_GAME_OVER_CONSUMED := "game_over_consumed"
const ENDING_YOU := "ending_you"
const ENDING_THEY_GOT_IN := "ending_they_got_in"
const ENDING_ROUTINE_SHIFT := "ending_routine_shift"
const ENDING_TRUTH_BELOW := "ending_truth_below"

var ending_id: String = ""
var main_menu_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"

func set_ending(new_ending_id: String) -> void:
	ending_id = new_ending_id

func clear_result() -> void:
	ending_id = ""
