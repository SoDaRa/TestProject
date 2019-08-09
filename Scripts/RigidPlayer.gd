extends RigidBody2D

#RigidBody Movemnet
export var MAX_HORIZONTAL_SPEED = 1000
export var MAX_VERTICAL_SPEED = 2000
export var side_speed_growth = 50
export var jump_strength = 1000

#Kinematic Movement
export var kin_speed = 200

#Shape Changing 
var box_collision = preload("PlayerBoxCollision.tres")
var ball_collision = preload("PlayerBallCollision.tres")
var box_sprite = preload("box.png")
var ball_sprite = preload("ball.png")
enum {BOX_MODE, BALL_MODE}
var curr_shape

#Movement Swapping
enum {RIG_MODE, KIN_MODE}
var curr_mode = RIG_MODE

#Color Swapping
var curr_color = 0

#Trail
#var blank_ball = preload("res://blank_ball.png")
#var blank_box = preload("blank_box.png")
#var trail_array = []
#var trail_index

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_shape = BOX_MODE
	$Sprite.modulate = get_parent().color_sequence[curr_color]
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$PlayerMask/Viewport/PMSprite.texture = box_sprite
	
#	for x in range(200):
#		trail_array.append(Sprite.new())
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Shape Swap
	if Input.is_action_just_pressed("swap_shape"):
		if curr_shape == BOX_MODE:
			$CollisionShape2D.shape = ball_collision
			$Sprite.texture = ball_sprite
			$PlayerMask/Viewport/PMSprite.texture = ball_sprite
			curr_shape = BALL_MODE
		elif curr_shape == BALL_MODE:
			$CollisionShape2D.shape = box_collision
			$Sprite.texture = box_sprite
			$PlayerMask/Viewport/PMSprite.texture = box_sprite
			curr_shape = BOX_MODE

	#Color Swap
	if Input.is_action_just_pressed("cycle_color") || Input.is_action_just_pressed("next_color"):
		curr_color += 1
		if curr_color > 3:
			curr_color = 0
		$Sprite.modulate = get_parent().color_sequence[curr_color]
		
	if Input.is_action_just_pressed("previous_color"):
		curr_color -= 1
		if curr_color < 0:
			curr_color = 3
		$Sprite.modulate = get_parent().color_sequence[curr_color]

	#Swap Physics
	if Input.is_action_just_pressed("swap_player_physics"):
		if curr_mode == RIG_MODE:
			curr_mode = KIN_MODE
			self.custom_integrator = true
		elif curr_mode == KIN_MODE:
			curr_mode = RIG_MODE
			self.custom_integrator = false
			
	#Trail Paint
#	if Input.is_action_just_pressed("paint"):
#		trail_index = 0
	
	if Input.is_action_pressed("paint"):
		print("paint pressed")
		trail_array[trail_index].position = self.position
		trail_array[trail_index].rotation_degrees = self.rotation_degrees
		trail_array[trail_index].modulate = get_parent().color_sequence[curr_color]
		if curr_shape == BOX_MODE:
			trail_array[trail_index].texture = blank_box
		elif curr_shape == BALL_MODE:
			trail_array[trail_index].texture = blank_ball
		trail_index += 1
		if trail_index == 200:
			trail_index = 0
			

func _integrate_forces(state):
	#Rigid Mode
	if curr_mode == RIG_MODE:
		#Horizontal Movement
		if Input.is_action_pressed("right") && state.linear_velocity.x < MAX_HORIZONTAL_SPEED:
			state.apply_central_impulse(Vector2(side_speed_growth, 0))
		if Input.is_action_pressed("left") && state.linear_velocity.x > MAX_HORIZONTAL_SPEED * -1:
			state.apply_central_impulse((Vector2(side_speed_growth * -1, 0)))
		#Jump
		if Input.is_action_just_pressed("up") && state.get_contact_count() > 0 && state.linear_velocity.y > MAX_VERTICAL_SPEED * -1:
			state.apply_central_impulse(Vector2(0, jump_strength *-1))
			
	#Kinematic Mode
	elif curr_mode == KIN_MODE:
		var velocity = Vector2(0,0)
		if Input.is_action_pressed("left"):
			velocity.x -= kin_speed
		if Input.is_action_pressed("right"):
			velocity.x += kin_speed
		if Input.is_action_pressed("up"):
			velocity.y -= kin_speed
		if Input.is_action_pressed("down"):
			velocity.y += kin_speed
#		if !self.test_motion(velocity * state.step, true, 1.0):
		state.set_linear_velocity(velocity)
		
	