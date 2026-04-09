extends Node

var player: AudioStreamPlayer = null
var current_stream: AudioStream = null

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "MenuMusicPlayer"
	player.finished.connect(_on_player_finished)
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
	player.play()

func stop_music() -> void:
	if player and player.playing:
		player.stop()

	current_stream = null

func is_playing_stream(stream: AudioStream) -> bool:
	return player != null and player.playing and current_stream == stream

func _on_player_finished() -> void:
	if player == null:
		return

	if current_stream == null:
		return

	player.play()
