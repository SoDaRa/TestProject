extends KinematicBody2D

var curr_color = 0

export var run_speed = 360
export var jump_speed = -1000
export var gravity = 2500
const MAX_HORIZONTAL_SPEED = 1000

#var Bullet = preload("res://Bullet.tscn")

var velocity = Vector2()

#func shoot():
#	var shot = Bullet.instance()
#	shot.start(self.position + Vector2(0,-50), Vector2(0,-100))
#	get_parent().add_child(shot)
#	pass

func _ready():
	$Sprite.modulate = get_parent().color_sequence[curr_color]

func get_input():
	velocity.x = 0
	var right = Input.is_action_pressed('right')
	var left = Input.is_action_pressed('left')
	var jump = Input.is_action_just_pressed('up')
#	var left_click = Input.is_action_just_pressed("left_click")
	var right_click = Input.is_action_just_pressed("right_click")
	
	if is_on_floor() and jump:
		velocity.y = jump_speed
		$AnimationPlayer.play("Jump")
	if right:
		velocity.x += run_speed
	if left:
		velocity.x -= run_speed
#	if left_click:
#		shoot()
	if right_click:
		curr_color += 1
		if curr_color > 3:
			curr_color = 0
		$Sprite.modulate = get_parent().color_sequence[curr_color]
		
func _process(delta):
	if not velocity.x == 0:
		if velocity.x > 0:
			$Sprite.rotate(deg2rad(velocity.length() * delta * 2))
		else:
			$Sprite.rotate(deg2rad(velocity.length() * delta * -2))
			
		if $Sprite.rotation_degrees > 360 || $Sprite.rotation_degrees < 0:
				$Sprite.rotation_degrees = wrapf($Sprite.rotation_degrees, 0, 360)

func _physics_process(delta):
	velocity.y += gravity * delta
	get_input()
	if Input.is_action_pressed("down") || velocity.length() == 0:
		velocity = move_and_slide(velocity, Vector2(0, -1), true, 4, deg2rad(75))
	velocity = move_and_slide(velocity, Vector2(0, -1), false, 4, deg2rad(75))
