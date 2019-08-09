extends RigidBody2D

#RigidBody Movemnet
export var MAX_HORIZONTAL_SPEED = 1000
export var MAX_VERTICAL_SPEED = 2000
export var side_speed_growth = 50
export var jump_strength = 1000

#Kinematic Movement
export var kin_speed = 200

#Shape Changing
var box_collision = preload("res://Collision/PlayerBoxCollision.tres")
var ball_collision = preload("res://Collision/PlayerBallCollision.tres")
var old_tri_collision = preload("res://Collision/PlayerTriangleCollision.tres")
var box_sprite = preload("res://Sprites/box.png")
var ball_sprite = preload("res://Sprites/ball.png")
var old_tri_sprite = preload("res://Sprites/triangle.png")
enum {BOX_MODE, BALL_MODE, TRI_MODE, OLD_TRI_MODE}
var curr_shape

#Movement Swapping
enum {RIG_MODE, KIN_MODE}
var curr_mode = RIG_MODE

#Color Swapping
var curr_color = 0

onready var MaskSprite = get_node("PlayerMask/Viewport/PMSprite")

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_shape = BOX_MODE
	$Sprite.modulate = get_parent().color_sequence[curr_color]
	MaskSprite.texture = box_sprite
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Shape Swap
	if Input.is_action_just_pressed("swap_shape"):
		if curr_shape == BOX_MODE:
			$CollisionShape2D.shape = ball_collision
			$Sprite.texture = ball_sprite
			MaskSprite.texture = ball_sprite
			curr_shape = BALL_MODE
		elif curr_shape == BALL_MODE:
			$CollisionShape2D.shape = old_tri_collision
			$CollisionShape2D.position.y = -3
			$Sprite.texture = old_tri_sprite
			$Sprite.offset.y = -3
			MaskSprite.texture = old_tri_sprite
			MaskSprite.offset.y = -3
			curr_shape = OLD_TRI_MODE
#		elif curr_shape == TRI_MODE:
#			$CollisionShape2D.shape = old_tri_collision
#			$Sprite.texture = old_tri_sprite
#			MaskSprite.texture = old_tri_sprite
#			curr_shape = OLD_TRI_MODE
		elif curr_shape == OLD_TRI_MODE:
			$CollisionShape2D.shape = box_collision
			$CollisionShape2D.position.y = 0
			$Sprite.texture = box_sprite
			$Sprite.offset.y = 0
			MaskSprite.texture = box_sprite
			MaskSprite.offset.y = 0
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
		

	#Swap Physics Mode
	if Input.is_action_just_pressed("swap_player_physics"):
		if curr_mode == RIG_MODE:
			curr_mode = KIN_MODE
			self.custom_integrator = true
		elif curr_mode == KIN_MODE:
			curr_mode = RIG_MODE
			self.custom_integrator = false
			
			

func _integrate_forces(state: Physics2DDirectBodyState):
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