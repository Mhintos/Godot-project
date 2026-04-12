extends TextureButton

@onready var sprite: AnimatedSprite2D = $MicSprite

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if not visible or disabled:
		return

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("hover"):
		sprite.play("hover")

func _on_mouse_exited() -> void:
	if not visible or disabled:
		return

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")
