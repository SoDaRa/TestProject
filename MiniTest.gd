extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	var vec = Vector2(-7.8, 10.6)
	print(rad2deg(vec.angle()))