extends Node

#Colors for shapes
export var color_sequence = [Color(1.0, 1.0, 1.0, 1.0), Color(0.0, 1.0, 1.0, 1.0), Color(1.0, 0.0, 1.0, 1.0), Color(1.0, 1.0, 0.0, 1.0)]
export var curr_color = 0


var box_collision = preload("res://Collision/PlayerBoxCollision.tres")
var ball_collision = preload("res://Collision/PlayerBallCollision.tres")
var tri_collision = preload("res://Collision/PlayerTriangleCollision.tres")

var box_sprite = preload("res://Sprites/box.png")
var ball_sprite = preload("res://Sprites/ball.png")
var walrus_sprite = preload("res://Sprites/walrus.png")
var tri_sprite = preload("res://Sprites/triangle.png")
var custom_sprite

var collision_outline_shader = preload("res://PlayerCollisionOutlineShader.tres")

enum {BOX_MODE, BALL_MODE, TRI_MODE, WALRUS_MODE, CUSTOM_MODE}   

export var curr_shape = BALL_MODE

#Size Changing
var BASE_SIZE = 50 #This represents the player being 1-to-1 with the image file's pixel size.
var MIN_SIZE = 10
var curr_size = 50
var curr_max_size = 75 #This will be used to cap how large the player can grow as they unlock more size upgrades.

signal paint(mask, mask_pos, player_color)

onready var MaskSprite = get_node("PlayerMask/Viewport/PMSpriteScale/PMSprite")
onready var RigidCollision= get_node("RigidBody2D/CollisionShape2D")
onready var MySprite = get_node("SpriteScale/Sprite")

#NOTE: Due to player now being a Node instead of a RigidBody, the level should have a Position2D to specify where it should start.

# Called when the node enters the scene tree for the first time.
func _ready():
	custom_sprite = load("user://custom.png")
	if custom_sprite == null:
		custom_sprite = load("res://Sprites/default_custom.png")
	if custom_sprite.get_size() != box_sprite.get_size():
		custom_sprite = load("res://Sprites/default_custom.png")
	MySprite.modulate = color_sequence[curr_color]
	update_shape()

# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta):
#	if Input.is_action_just_pressed("Dummy_Button"):
#		color_sequence.append(Color(0.5,0.5,0.5,1.0))
#		$ColorChoices/CenterContainer/GridContainer._add_color()
		
	if curr_shape != BALL_MODE: #Get rotation if not a ball
		MaskSprite.rotation_degrees = MySprite.rotation_degrees
		
		#Shape Swap
	if Input.is_action_just_pressed("swap_shape"):
		curr_shape += 1
		curr_shape = wrapi(curr_shape, 0, 5)
		update_shape()
		
	#Color Swap
	if Input.is_action_just_pressed("next_color"):
		curr_color += 1
		curr_color = wrapi(curr_color, 0, color_sequence.size())
		MySprite.modulate = color_sequence[curr_color]

	if Input.is_action_just_pressed("previous_color"):
		curr_color -= 1
		curr_color = wrapi(curr_color, 0, color_sequence.size())
		MySprite.modulate = color_sequence[curr_color]
		
	#TODO: Consider adjusting PlayerMask.Viewport.size with this. May make images smaller and easier to pass around sometimes.
	#Size Swapping
	if Input.is_action_pressed("decrease_size") && curr_size != MIN_SIZE:
		var decreased_by = 1.0/BASE_SIZE      #HACK Probably should do this as a function and have more clear MAX and MIN
		var new_scale = MySprite.scale
		new_scale -= Vector2(decreased_by, decreased_by)

		if new_scale.x > 0.1: #Ensure the collision shape doesn't get so small it causes problems
			RigidCollision.scale = new_scale
			MySprite.scale = new_scale
			MaskSprite.scale = new_scale

			curr_size -= 1

		else: #If already too small, just say we're at the min
			curr_size = MIN_SIZE

	if Input.is_action_pressed("increase_size") && curr_size != curr_max_size:
		var increased_by = 1.0/BASE_SIZE
		var new_scale = MySprite.scale
		new_scale += Vector2(increased_by, increased_by)
		RigidCollision.scale = new_scale
		MySprite.scale = new_scale
		MaskSprite.scale = new_scale

		curr_size += 1

# warning-ignore:unused_argument
func _physics_process(delta):
	$SpriteScale.position = $RigidBody2D.position
	MySprite.rotation_degrees = $RigidBody2D.rotation_degrees
	
	if Input.is_action_pressed("paint") && get_tree().paused == false:
		if curr_shape != BALL_MODE: #Get rotation if not a ball
			MaskSprite.rotation_degrees = MySprite.rotation_degrees
		var my_mask = $PlayerMask/Viewport.get_texture().get_data()
		var mask_pos = $RigidBody2D.position - Vector2(my_mask.get_width() / 2.0,my_mask.get_height() / 2.0)
		emit_signal("paint", my_mask, mask_pos, color_sequence[curr_color])
		#NOTE: Don't turn off PlayerMask Visibility
		#NOTE: Be sure the paint signal is connected to the level!!

func _color_picker_changed(new_color, picker_name):
	var picker_index = int(picker_name)
	color_sequence[picker_index] = new_color
	if curr_color == picker_index:
		MySprite.modulate = color_sequence[curr_color]
	pass

func color_popup_opened():
	get_tree().paused = true

func color_popup_closed():
	get_tree().paused = false

func update_shape():
	match(curr_shape):
		#TODO: Generate collision for Collision shape on the fly
		BALL_MODE:
			RigidCollision.shape = ball_collision
			MySprite.texture = ball_sprite
			MaskSprite.texture = ball_sprite
			MySprite.material = null
		BOX_MODE:
			RigidCollision.shape = box_collision
			MySprite.texture = box_sprite
			MaskSprite.texture = box_sprite
			MySprite.material = null
		TRI_MODE:
			RigidCollision.shape = tri_collision
			MySprite.texture = tri_sprite
			MaskSprite.texture = tri_sprite
			MySprite.material = null
		WALRUS_MODE:
			RigidCollision.shape = box_collision
			MySprite.texture = walrus_sprite
			MaskSprite.texture = walrus_sprite
			MySprite.material = collision_outline_shader
		CUSTOM_MODE:
			RigidCollision.shape = box_collision
			MySprite.texture = custom_sprite
			MaskSprite.texture = custom_sprite
			MySprite.material = collision_outline_shader



func _on_RigidBody2D_jumping():
	if $SpriteScale/AnimationPlayer.is_playing():
		$SpriteScale/AnimationPlayer.stop()
		$PlayerMask/Viewport/PMSpriteScale/MaskAnimation.stop()
	$SpriteScale/AnimationPlayer.play("JumpAnimation")
	$PlayerMask/Viewport/PMSpriteScale/MaskAnimation.play("JumpAnimation")