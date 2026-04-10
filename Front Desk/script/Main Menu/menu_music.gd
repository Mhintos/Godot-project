extends Node

var player: AudioStreamPlayer = null
var current_stream: AudioStream = null

const MAIN_MENU_STREAM := preload("res://sfx/Background Music/Main Menu Official BG Music.mp3")
const MAIN_MENU_VOLUME_DB := -11.0

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "MenuMusicPlayer"
	add_child(player)

func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return

	if player == null:
		return

	if current_stream == stream and player.playing:
		return

	current_stream = stream
	player.stream = stream
	player.volume_db = volume_db

	if player.stream is AudioStreamOggVorbis:
		player.stream.loop = true
	elif player.stream is AudioStreamMP3:
		player.stream.loop = true

	player.play()

func play_main_menu_music() -> void:
	play_music(MAIN_MENU_STREAM, MAIN_MENU_VOLUME_DB)

func stop_music() -> void:
	if player and player.playing:
		player.stop()

	current_stream = null

func is_playing_stream(stream: AudioStream) -> bool:
	return player != null and player.playing and current_stream == stream
