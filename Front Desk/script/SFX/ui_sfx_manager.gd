extends Node

var click_player: AudioStreamPlayer
var hover_player: AudioStreamPlayer
var menu_click_player: AudioStreamPlayer

const CLICK_STREAM := preload("res://sfx/General Sounds/ButtonClick.mp3")
const HOVER_STREAM := preload("res://sfx/General Sounds/Button Hover.mp3")
const MENU_CLICK_STREAM := preload("res://sfx/General Sounds/Cursor Click.mp3")

const CLICK_VOLUME_DB := -10.0
const HOVER_VOLUME_DB := -25.0
const MENU_CLICK_VOLUME_DB := -10.0

func _ready() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.name = "ClickPlayer"
	click_player.stream = CLICK_STREAM
	click_player.volume_db = CLICK_VOLUME_DB
	add_child(click_player)

	hover_player = AudioStreamPlayer.new()
	hover_player.name = "HoverPlayer"
	hover_player.stream = HOVER_STREAM
	hover_player.volume_db = HOVER_VOLUME_DB
	add_child(hover_player)

	menu_click_player = AudioStreamPlayer.new()
	menu_click_player.name = "MenuClickPlayer"
	menu_click_player.stream = MENU_CLICK_STREAM
	menu_click_player.volume_db = MENU_CLICK_VOLUME_DB
	add_child(menu_click_player)

func play_click() -> void:
	if click_player == null or click_player.stream == null:
		return

	if click_player.playing:
		click_player.stop()

	click_player.play()

func play_hover() -> void:
	if hover_player == null or hover_player.stream == null:
		return

	if hover_player.playing:
		hover_player.stop()

	hover_player.play()

func play_menu_click() -> void:
	if menu_click_player == null or menu_click_player.stream == null:
		return

	if menu_click_player.playing:
		menu_click_player.stop()

	menu_click_player.play()
