extends ColorRect

var my_material = ShaderMaterial.new()
var my_shader = preload("res://Scripts/ColorPickerSample.shader")

#This exists solely to ensure it's unique upon loading
func _ready():
	my_material.shader = my_shader
	self.material = my_material


