extends Node

const ENDING_GAME_OVER_CONSUMED := "game_over_consumed"
const ENDING_YOU := "ending_you"
const ENDING_THEY_GOT_IN := "ending_they_got_in"
const ENDING_ROUTINE_SHIFT := "ending_routine_shift"
const ENDING_TRUTH_BELOW := "ending_truth_below"

var ending_id: String = ""
var main_menu_scene_path: String = "res://scene/Main Menu/Mainmenu.tscn"

var total_characters_processed: int = 0
var mistakes_made: int = 0
var forged_documents_missed: int = 0
var disguised_anomalies_stopped: int = 0
var true_forms_stopped: int = 0

func set_ending(new_ending_id: String) -> void:
	ending_id = new_ending_id

func set_stats(
	new_total_characters_processed: int,
	new_mistakes_made: int,
	new_forged_documents_missed: int,
	new_disguised_anomalies_stopped: int,
	new_true_forms_stopped: int
) -> void:
	total_characters_processed = new_total_characters_processed
	mistakes_made = new_mistakes_made
	forged_documents_missed = new_forged_documents_missed
	disguised_anomalies_stopped = new_disguised_anomalies_stopped
	true_forms_stopped = new_true_forms_stopped

func clear_result() -> void:
	ending_id = ""
	total_characters_processed = 0
	mistakes_made = 0
	forged_documents_missed = 0
	disguised_anomalies_stopped = 0
	true_forms_stopped = 0
