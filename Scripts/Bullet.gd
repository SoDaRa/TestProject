extends RigidBody2D

#export var speed = 250

func start(initial_position, initial_velocity = Vector2()):
	position = initial_position
	apply_central_impulse(initial_velocity)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
