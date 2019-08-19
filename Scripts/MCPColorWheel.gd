extends TextureRect

onready var wheel_center = Vector2(rect_size.x / 2, rect_size.y / 2)

signal wheel_mouse_input(angle)

#func _ready():
#	wheel_center = Vector2(rect_size.x / 2, rect_size.y / 2)

func _gui_input(event):
	if event is InputEventMouse:
		if event.get_button_mask() & BUTTON_MASK_LEFT:
			var angle = rad2deg(wheel_center.angle_to_point(event.position)) + 180
			emit_signal("wheel_mouse_input", angle)
			print("Wheel Mouse Signal ", angle)