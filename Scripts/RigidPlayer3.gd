extends RigidBody2D
#ver3
#RigidBody Movemnet
export var MAX_HORIZONTAL_SPEED = 1000
export var MAX_VERTICAL_SPEED = 2000
export var side_speed_growth = 50
export var jump_strength = 1000
export var rotate_speed_growth = .1
export var MAX_ROTATE_SPEED = 10
#Kinematic Movement
export var kin_speed = 200

#Colors for shapes
export var color_sequence = [Color(0.0, 0.0, 0.1, 1.0), Color(0.0, 1.0, 1.0, 1.0), Color(1.0, 0.0, 1.0, 1.0), Color(1.0, 1.0, 0.0, 1.0)]
var curr_color = 0

#Shape Changing
var box_collision = preload("res://Collision/PlayerBoxCollision.tres")
var ball_collision = preload("res://Collision/PlayerBallCollision.tres")
var tri_collision = preload("res://Collision/PlayerTriangleCollision.tres")
var box_sprite = preload("res://Sprites/box.png")
var ball_sprite = preload("res://Sprites/ball.png")
var walrus_sprite = preload("res://Sprites/walrus.png")
var tri_sprite = preload("res://Sprites/triangle.png")
var custom_sprite = preload("res://Sprites/custom.png")
enum {BOX_MODE, BALL_MODE, TRI_MODE, WALRUS_MODE, CUSTOM_MODE}   #TODO Consider means to make WALRUS_MODE more like CUSTOM_MODE. Custom space to draw in game?
var curr_shape

#Movement Swapping
enum {RIG_MODE, KIN_MODE}
var curr_mode = RIG_MODE

#Size Changing
var MAX_SIZE = 75
var MIN_SIZE = 10
var curr_size = 75

signal paint(mask, mask_pos, player_color)

onready var MaskSprite = get_node("PlayerMask/Viewport/PMSprite")


func _color_picker_changed(new_color, picker_name):
	var picker_index = int(picker_name)
	color_sequence[picker_index] = new_color
	if curr_color == picker_index:
		$Sprite.modulate = color_sequence[curr_color]
	pass
	
func color_popup_opened():
	get_tree().paused = true

func color_popup_closed():
	get_tree().paused = false

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_shape = BOX_MODE
	$Sprite.modulate = color_sequence[curr_color]
	MaskSprite.texture = box_sprite
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta):
	#Paint
	if curr_shape != BALL_MODE: #Get rotation if not a ball
		$PlayerMask/Viewport/PMSprite.rotation_degrees = self.rotation_degrees
	
	#Shape Swap
	if Input.is_action_just_pressed("swap_shape"):
		curr_shape += 1
		curr_shape = wrapi(curr_shape, 0, 5)
		match(curr_shape):
			BALL_MODE:
				$CollisionShape2D.shape = ball_collision
				$Sprite.texture = ball_sprite
				MaskSprite.texture = ball_sprite
			BOX_MODE:
				$CollisionShape2D.shape = box_collision
				$Sprite.texture = box_sprite
				MaskSprite.texture = box_sprite
			TRI_MODE:
				$CollisionShape2D.shape = tri_collision
				$Sprite.texture = tri_sprite
				MaskSprite.texture = tri_sprite
			WALRUS_MODE:
				$CollisionShape2D.shape = box_collision
				$Sprite.texture = walrus_sprite
				MaskSprite.texture = walrus_sprite
			CUSTOM_MODE:
				$CollisionShape2D.shape = box_collision
				$Sprite.texture = custom_sprite
				MaskSprite.texture = custom_sprite

	#Color Swap
	if Input.is_action_just_pressed("next_color"):
		curr_color += 1
		curr_color = wrapi(curr_color, 0, 4)
		$Sprite.modulate = color_sequence[curr_color]

	if Input.is_action_just_pressed("previous_color"):
		curr_color -= 1
		curr_color = wrapi(curr_color, 0, 4)
		$Sprite.modulate = color_sequence[curr_color]
		

	#Swap Physics Mode
	if Input.is_action_just_pressed("swap_player_physics"):
		if curr_mode == RIG_MODE:
			curr_mode = KIN_MODE
			self.custom_integrator = true   #To disable gravity and allowing the player to fly instead.
		elif curr_mode == KIN_MODE:
			curr_mode = RIG_MODE
			self.custom_integrator = false
	
	#Size Swapping
	if Input.is_action_pressed("decrease_size") && curr_size != MIN_SIZE:
		var decreased_by = 1.0/MAX_SIZE      #HACK probably should do this as a function and have more clear MAX and MIN
		var new_scale = $CollisionShape2D.scale
		new_scale -= Vector2(decreased_by, decreased_by)
		
		if new_scale.x > 0.1: #Ensure the collision shape doesn't get so small it causes problems
			$CollisionShape2D.scale = new_scale
			$Sprite.scale = new_scale
			$PlayerMask/Viewport/PMSprite.scale = new_scale
			
			curr_size -= 1
			
		else: #If already too small, just say we're at the min
			curr_size = MIN_SIZE

	if Input.is_action_pressed("increase_size") && curr_size != MAX_SIZE:
		var increased_by = 1.0/MAX_SIZE
		var new_scale = $Sprite.scale
		new_scale += Vector2(increased_by, increased_by)
		
		$CollisionShape2D.scale = new_scale
		$Sprite.scale = new_scale
		$PlayerMask/Viewport/PMSprite.scale = new_scale
		
		curr_size += 1

func _integrate_forces(state: Physics2DDirectBodyState):
	if Input.is_action_pressed("paint") && get_tree().paused == false:
		if curr_shape != BALL_MODE: #Get rotation if not a ball
			$PlayerMask/Viewport/PMSprite.rotation_degrees = self.rotation_degrees
		var my_mask = $PlayerMask/Viewport.get_texture().get_data()
		var mask_pos = self.position - Vector2(my_mask.get_width() / 2.0,my_mask.get_height() / 2.0)
		emit_signal("paint", my_mask, mask_pos, color_sequence[curr_color])
		#NOTE: Don't turn off PlayerMask Visibility
	#Rigid Mode
	if curr_mode == RIG_MODE:
		#Horizontal Movement
		if Input.is_action_pressed("right") && state.linear_velocity.x < MAX_HORIZONTAL_SPEED:
			state.apply_central_impulse(Vector2(side_speed_growth, 0))
		if Input.is_action_pressed("left") && state.linear_velocity.x > MAX_HORIZONTAL_SPEED * -1:
			state.apply_central_impulse((Vector2(side_speed_growth * -1, 0)))
		#Jump
		if Input.is_action_just_pressed("up") && state.get_contact_count() > 0 && state.linear_velocity.y > -MAX_VERTICAL_SPEED:
			state.apply_central_impulse(Vector2(0, jump_strength *-1))
			
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
		
#	if Input.is_action_just_pressed("zoom_out"): #NOTE: How to move it to a specific point
#		var my_transform = state.get_transform()
#		var my_x = my_transform.x
#		var my_y = my_transform.y
#		var my_origin = Vector2(50,50)
#		var new_transform = Transform2D(my_x, my_y, my_origin)
#		print(my_transform)
#		print(new_transform)
#		state.set_transform(new_transform)