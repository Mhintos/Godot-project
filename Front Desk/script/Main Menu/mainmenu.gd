extends Node2D

@export var game_scene_path: String = "res://scene/ui/inspection_2d.tscn"
@export var tips_scene_path: String = "res://scene/tips/tips_1.tscn"

@onready var start_button = $CanvasLayer/StartButton
@onready var quit_button = $CanvasLayer/QuitButton
@onready var settings_button = $CanvasLayer/SettingsButton # ✅ ADDED
@onready var tips_button = $CanvasLayer/TipsButton # ✅ ADDED for hover sound

@onready var main_menu_music: AudioStreamPlayer = $MainMenuMusic
@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

@onready var music: AudioStreamPlayer = $MainMenuMusic

func _ready() -> void:
	var stream = main_menu_music.stream
	
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	
	main_menu_music.play()
	
	start_button.mouse_entered.connect(_on_button_hovered)
	quit_button.mouse_entered.connect(_on_button_hovered)
	settings_button.mouse_entered.connect(_on_button_hovered) # ✅ ADDED
	tips_button.mouse_entered.connect(_on_button_hovered) # ✅ ADDED Tips hover

func _on_button_hovered() -> void:
	if hover_sfx.stream:
		if hover_sfx.playing:
			hover_sfx.stop()
		hover_sfx.play()

func _on_start_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file(game_scene_path)

func _on_quit_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().quit()

func _on_settings_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished
		
	get_tree().change_scene_to_file("res://scene/Settings/Settings.tscn")

func _on_tips_button_pressed() -> void:
	if click_sfx.stream:
		click_sfx.play()
		await click_sfx.finished

	get_tree().change_scene_to_file("res://scene/tips/tips_1.tscn")
