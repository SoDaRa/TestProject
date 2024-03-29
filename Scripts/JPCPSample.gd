extends ColorRect

var my_material = ShaderMaterial.new()
var my_shader = preload("res://Scripts/ColorPickerSample.shader")

signal mouse_input(pos)

#This exists solely to ensure it's unique upon loading
func _ready():
	my_material.shader = my_shader
	self.material = my_material

func _gui_input(event):
	if event is InputEventMouseButton:
		emit_signal("mouse_input", event.position)
		pass
	pass
