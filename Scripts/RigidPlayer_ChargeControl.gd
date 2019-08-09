extends RigidBody2D

export var max_horizontal_charge = 9500
export var max_jump_charge = 500
export var horizontal_charge_rate = 5000
export var jump_charge_rate = 8000
const MAX_HORIZONTAL_SPEED = 1000
const MAX_VERTICAL_SPEED = 5000
var right_charge
var left_charge
var jump_charge

var box_collision = preload("PlayerBoxCollision.tres")
var ball_collision = preload("PlayerBallCollision.tres")
var box_sprite = preload("box.png")
var ball_sprite = preload("ball.png")
enum {BOX_MODE, BALL_MODE}
var current_shape


# Called when the node enters the scene tree for the first time.
func _ready():
	current_shape = BOX_MODE
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("right"):
		right_charge = 0.0
	if Input.is_action_just_pressed("left"):
		left_charge = 0.0
	if Input.is_action_just_pressed("up"):
		jump_charge = 0.0

	if Input.is_action_pressed("right"):
		if right_charge < max_horizontal_charge:
			right_charge += horizontal_charge_rate * delta
	if Input.is_action_pressed("left"):
		if left_charge < max_horizontal_charge:
			left_charge += horizontal_charge_rate * delta
	if Input.is_action_pressed("up"):
		if jump_charge < max_jump_charge:
			jump_charge += jump_charge_rate * delta

	if Input.is_action_just_pressed("swap_shape"):
		if current_shape == BOX_MODE:
			$CollisionShape2D.shape = ball_collision
			$Sprite.texture = ball_sprite
			current_shape = BALL_MODE
		elif current_shape == BALL_MODE:
			$CollisionShape2D.shape = box_collision
			$Sprite.texture = box_sprite
			current_shape = BOX_MODE


func _integrate_forces(state):
	if Input.is_action_just_released("right") && right_charge > 0:
		state.apply_central_impulse(Vector2(right_charge, 0))
		right_charge = 0

	if Input.is_action_just_released("left") && left_charge > 0:
		state.apply_central_impulse(Vector2(left_charge * -1, 0))
		left_charge = 0

	if Input.is_action_just_released("up") && jump_charge > 0:
		state.apply_central_impulse(Vector2(0, jump_charge * -1))
		jump_charge = 0