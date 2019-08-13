extends RigidBody2D
#ver4
#This version has many of it's features removed and moved to PlayerVer3.gd
#RigidBody Movemnet
export var MAX_HORIZONTAL_SPEED = 1000
export var MAX_VERTICAL_SPEED = 2000
export var side_speed_growth = 50
export var jump_strength = 1000
export var rotate_speed_growth = .1
export var MAX_ROTATE_SPEED = 10
#Kinematic Movement
export var kin_speed = 200

var apply_jump = false #This is used to delay a jump

signal jumping

#Movement Swapping
enum {RIG_MODE, KIN_MODE}
var curr_mode = RIG_MODE

func _integrate_forces(state: Physics2DDirectBodyState):
	#Swap Physics Mode
	if Input.is_action_just_pressed("swap_player_physics"):
		if curr_mode == RIG_MODE:
			curr_mode = KIN_MODE
			self.custom_integrator = true   #To disable gravity and allowing the player to fly instead.
		elif curr_mode == KIN_MODE:
			curr_mode = RIG_MODE
			self.custom_integrator = false
	#Rigid Mode
	if curr_mode == RIG_MODE:
		#Horizontal Movement
		if Input.is_action_pressed("right") && state.linear_velocity.x < MAX_HORIZONTAL_SPEED:
			state.apply_central_impulse(Vector2(side_speed_growth, 0))
		if Input.is_action_pressed("left") && state.linear_velocity.x > -MAX_HORIZONTAL_SPEED:
			state.apply_central_impulse((Vector2(side_speed_growth * -1, 0)))
		#Jump
		if Input.is_action_just_pressed("up") && state.get_contact_count() > 0 && state.linear_velocity.y > -MAX_VERTICAL_SPEED:
			emit_signal("jumping")
			$Timer.start()
			
		if apply_jump == true:
			state.apply_central_impulse(Vector2(0,jump_strength * -1))
			apply_jump = false

	#Kinematic Mode
	elif curr_mode == KIN_MODE:
		var velocity = Vector2(0,0)
		var rotation_speed = state.angular_velocity
		if Input.get_connected_joypads().size() > 0:
			var xAxis = Input.get_joy_axis(0, JOY_AXIS_0)
			var yAxis = Input.get_joy_axis(0, JOY_AXIS_1)
			if abs(xAxis) > .14:
				velocity.x = xAxis * 1.25 * kin_speed
			if abs(yAxis) > .14:
				velocity.y = yAxis * 1.25 * kin_speed
		else:
			if Input.is_action_pressed("left"):
				velocity.x -= kin_speed
			if Input.is_action_pressed("right"):
				velocity.x += kin_speed
			if Input.is_action_pressed("up"):
				velocity.y -= kin_speed
			if Input.is_action_pressed("down"):
				velocity.y += kin_speed

		if Input.is_action_pressed("rotate_cw") && rotation_speed < MAX_ROTATE_SPEED:
			rotation_speed += rotate_speed_growth
		if Input.is_action_pressed("rotate_ccw") && rotation_speed > -MAX_ROTATE_SPEED:
			rotation_speed -= rotate_speed_growth
		#Slow/Stop spinning
		if Input.is_action_pressed("rotate_ccw") && Input.is_action_pressed("rotate_cw"): #TODO: For controller, make this R3 and Mouse 3?
			rotation_speed = rotation_speed / 1.05
			if abs(rotation_speed) < 0.25:
				rotation_speed = 0
#		if !self.test_motion(velocity * state.step, true, 1.0):
		state.set_linear_velocity(velocity)
		state.angular_velocity = rotation_speed

func _on_Timer_timeout():
	apply_jump = true

#	if Input.is_action_just_pressed("zoom_out"): 
#NOTE: How to move it to a specific point in integrate forces
#This can also be done in PlayerVer3 directly with position. However it won't conserve momentum that well. Good for portals I guess
#		var my_transform = state.get_transform()
#		var my_x = my_transform.x
#		var my_y = my_transform.y
#		var my_origin = Vector2(50,50)
#		var new_transform = Transform2D(my_x, my_y, my_origin)
#		print(my_transform)
#		print(new_transform)
#		state.set_transform(new_transform)