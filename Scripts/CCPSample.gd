extends ColorRect

var my_material = ShaderMaterial.new()
var my_shader = preload("res://Themes_Shaders/ColorPickerSample.shader")

signal mouse_input(pos)

#This exists solely to ensure it's unique upon loading
func _ready():
	my_material.shader = my_shader
	self.material = my_material

func _gui_input(event):
	if event is InputEventMouse:
		if event.get_button_mask() & BUTTON_MASK_LEFT:
			var m_pos = event.position
			if m_pos.x > 255:
				m_pos.x = 255
			elif m_pos.x < 0:
				m_pos.x = 0
			if m_pos.y > 255:
				m_pos.y = 255
			elif m_pos.y < 0:
				m_pos.y = 0
			emit_signal("mouse_input", m_pos)
