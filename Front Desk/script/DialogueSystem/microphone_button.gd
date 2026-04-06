extends TextureButton
@onready var sprite = $MicSprite

func _ready():
	sprite.play("default")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	sprite.play("hover")

func _on_mouse_exited():
	sprite.play("default")

# Optional: if you want a click effect
func _pressed():
# you can play a short "click" animation or sound
	pass
