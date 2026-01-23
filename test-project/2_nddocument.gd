extends TextureRect

var stored_texture: Texture2D = null
var dropped_successfully := false

func _get_drag_data(_at_position):
	if texture == null:
		return null

	# store the texture, then remove it from the slot
	stored_texture = texture
	texture = null
	dropped_successfully = false

	# drag data (contains texture + original slot)
	var drag_data = {
		"texture": stored_texture,
		"source": self
	}

	# preview shown while dragging
	var preview_texture = TextureRect.new()
	preview_texture.texture = stored_texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = Vector2(80, 110)

	var preview = Control.new()
	preview.add_child(preview_texture)
	set_drag_preview(preview)

	return drag_data


func _can_drop_data(_pos, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("texture")


func _drop_data(_pos, data):
	var incoming_texture: Texture2D = data["texture"]
	var source: TextureRect = data["source"]

	# mark success so the source won't restore itself
	source.dropped_successfully = true

	# OPTIONAL: swap behavior (drag onto occupied slot)
	var temp = texture
	texture = incoming_texture

	# give old texture back to source slot (swap)
	source.texture = temp

	# cleanup
	source.stored_texture = null


func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		# if drag ended but wasn't dropped on a valid slot -> restore back
		if !dropped_successfully and texture == null and stored_texture != null:
			texture = stored_texture

		# cleanup
		stored_texture = null
		dropped_successfully = false
