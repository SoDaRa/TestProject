extends Sprite

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var shade_color = Color(0.0, 0.5, 0.5, 0.0)
# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	material.set_shader_param("new_color", shade_color)
