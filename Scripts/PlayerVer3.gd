extends Node

#Colors
export var color_sequence = [Color(1, 1, 1, 1), Color(0, 1, 1, 1), Color(1, 0, 1, 1), Color(1, 1, 0, 1)] 
var extra_color_queue = [Color.aquamarine, Color.beige, Color.chocolate, Color.orange, Color.gray]
export var curr_color = 0

#Collision
#var box_collision = preload("res://Collision/PlayerBoxCollision.tres")
#var ball_collision = preload("res://Collision/PlayerBallCollision.tres")
var tri_collision = preload("res://Collision/PlayerTriangleCollision.tres")

var box_sprite = preload("res://Sprites/box.png")
var ball_sprite = preload("res://Sprites/ball.png")
var walrus_sprite = preload("res://Sprites/walrus.png")
var tri_sprite = preload("res://Sprites/triangle.png")
var custom_image = Image.new()
var custom_sprite = ImageTexture.new()

var collision_outline_shader = preload("res://PlayerCollisionOutlineShader.tres")

onready var PaletteMenu = get_node("ColorChoices/PaletteMenu")

#Shape
enum SHAPE {BALL, BOX, TRIANGLE, WALRUS, CUSTOM}
export(SHAPE) onready var starting_shape
onready var curr_shape = starting_shape
var shapes_available = 3

#"Stay in-bounds"
var level_rect = Rect2(Vector2(0,0), Vector2(100,100)) 	#Used to define where out of bounds is. Is set up by parent/RootNode.gd
var last_valid_position = Vector2(0,0)					#Used to get back in bounds if out of bounds
var tolerance = 50										#How far the player can travel out of bounds before being snapped inbounds

#Size Changing
var BASE_SIZE = 50 #This represents the player being 1-to-1 with the image file's pixel size.
var MIN_SIZE = 10
var curr_size = 50
var curr_max_size = 75 #This will be used to cap how large the player can grow as they unlock more size upgrades.

signal painted(paint_image, mask_pos)

onready var MaskSprite = get_node("PlayerMask/Viewport/PMSpriteScale/PMSprite")
onready var RigidCollision= get_node("PlayerBody/CollisionShape2D")
onready var MySprite = get_node("SpriteScale/PlayerSprite")

#NOTE: Due to player now being a Node instead of a RigidBody, the level should have a Position2D to specify where it should start.

# Called when the node enters the scene tree for the first time.
func _ready():
	var custom_path = "custom.png"
	var file_checker = File.new()
	if file_checker.file_exists(custom_path):
		var err = custom_image.load(custom_path)
		if err || custom_image.is_empty() || custom_image.is_invisible() || custom_image.get_size() != box_sprite.get_size():
			custom_sprite = load("res://Sprites/default_custom.png")
		else:
			custom_sprite.create_from_image(custom_image, 5)
	else:
		custom_sprite = load("res://Sprites/default_custom.png")
	MySprite.modulate = color_sequence[curr_color]
	update_shape()
	
	for my_color in color_sequence:
#		CCPButtonContainer._add_color(my_color, self)
		PaletteMenu.add_color(my_color)
	PaletteMenu.connect("color_changed", self, "_color_picker_changed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta):
	var my_position = $PlayerBody.position
	var level_start = level_rect.position
	var level_end = level_rect.end
	var is_in_bounds = level_rect.has_point(my_position)
	var is_out_of_bounds = my_position.x < level_start.x - tolerance || my_position.y < level_start.y - tolerance 
	is_out_of_bounds = is_out_of_bounds || my_position.x > level_end.x + tolerance || my_position.y > level_end.y + tolerance
	
	if is_in_bounds:
		last_valid_position = $PlayerBody.position
	if is_out_of_bounds:
		if level_rect.has_point(last_valid_position):
			$PlayerBody.position = last_valid_position
		else: #If somehow the last_valid_position isn't within the level_rect, then default to it's top left corner.
			$PlayerBody.position = level_rect.position
	
	if Input.is_action_just_pressed("Dummy_Button"):
		var new_color = extra_color_queue.pop_front()
		color_sequence.append(new_color)
		PaletteMenu.add_color(new_color)
		
#	if curr_shape != SHAPE.BALL: #Get rotation if not a ball
#		MaskSprite.rotation_degrees = MySprite.rotation_degrees
		
		#Shape Swap
	if Input.is_action_just_pressed("swap_shape"):
		curr_shape += 1
		curr_shape = wrapi(curr_shape, 0, shapes_available)
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
		
	#Size Swapping
	if Input.is_action_pressed("decrease_size") && curr_size != MIN_SIZE:
		var decreased_by = 1.0/BASE_SIZE      #HACK Probably should do this as a function and have more clear MAX and MIN
		var new_scale = MySprite.scale
		new_scale -= Vector2(decreased_by, decreased_by)

		if new_scale.x > 0.1: #Ensure the collision shape doesn't get so small it causes problems
			MySprite.scale = new_scale
			MaskSprite.scale = new_scale
			RigidCollision.shape = update_collision()
			curr_size -= 1
		
		else: #If already too small, just say we're at the min
			curr_size = MIN_SIZE

	if Input.is_action_pressed("increase_size") && curr_size != curr_max_size:
		var increased_by = 1.0/BASE_SIZE
		var new_scale = MySprite.scale
		new_scale += Vector2(increased_by, increased_by)
#		RigidCollision.scale = new_scale
		MySprite.scale = new_scale
		MaskSprite.scale = new_scale
		RigidCollision.shape = update_collision()
		curr_size += 1
		
func _unhandled_input(event):
	if event.is_action("palette_menu") && !PaletteMenu.is_visible() && !get_tree().paused:
		if Input.is_action_just_pressed("palette_menu"):
			PaletteMenu.set_top_slice(curr_color)
			PaletteMenu.show()
			return

# warning-ignore:unused_argument
func _physics_process(delta):
	$SpriteScale.position = $PlayerBody.position
	MySprite.rotation_degrees = $PlayerBody.rotation_degrees
	
	if Input.is_action_pressed("paint") && get_tree().paused == false:
		if curr_shape != SHAPE.BALL: #Get rotation if not a ball
			MaskSprite.rotation_degrees = MySprite.rotation_degrees
		var my_mask = $PlayerMask/Viewport.get_texture().get_data() #Get the mask to use for blit
		my_mask = my_mask.get_rect(my_mask.get_used_rect())
		var player_color = Image.new()								#Get Color for blit
		player_color.create(my_mask.get_width(), my_mask.get_height(), false, Image.FORMAT_RGBA8)
		player_color.fill(color_sequence[curr_color])
		var player_paint = Image.new() 								#Image to send out
		player_paint.create(my_mask.get_width(), my_mask.get_height(), false, Image.FORMAT_RGBA8)
		player_paint.blit_rect_mask(player_color, my_mask, my_mask.get_used_rect(), Vector2(0,0))
		
		var mask_pos = $PlayerBody.position - Vector2(player_paint.get_width() / 2.0,player_paint.get_height() / 2.0)
		emit_signal("painted", player_paint, mask_pos)
		$PlayerTrail.draw_trail(my_mask, mask_pos, color_sequence[curr_color])
		#NOTE: Don't turn off PlayerMask Visibility
		#NOTE: Be sure the paint signal is connected to the level!!

func _color_picker_changed(new_color, picker_name):
	var picker_index = int(picker_name)
	color_sequence[picker_index] = new_color
	if curr_color == picker_index:
		MySprite.modulate = color_sequence[curr_color]

func update_shape():
	match(curr_shape):
		SHAPE.BALL:
			MySprite.texture = ball_sprite
			MaskSprite.texture = ball_sprite
			MySprite.material = null
		SHAPE.BOX:
			MySprite.texture = box_sprite
			MaskSprite.texture = box_sprite
			MySprite.material = null
		SHAPE.TRIANGLE:
			MySprite.texture = tri_sprite
			MaskSprite.texture = tri_sprite
			MySprite.material = null
		SHAPE.WALRUS:
			MySprite.texture = walrus_sprite
			MaskSprite.texture = walrus_sprite
			MySprite.material = collision_outline_shader
		SHAPE.CUSTOM:
			MySprite.texture = custom_sprite
			MaskSprite.texture = custom_sprite
			MySprite.material = collision_outline_shader
	RigidCollision.shape = update_collision()

func _on_RigidBody2D_jumping():
	if $SpriteScale/AnimationPlayer.is_playing():
		$SpriteScale/AnimationPlayer.stop()
		$PlayerMask/Viewport/PMSpriteScale/MaskAnimation.stop()
	$SpriteScale/AnimationPlayer.play("JumpAnimation")
	$PlayerMask/Viewport/PMSpriteScale/MaskAnimation.play("JumpAnimation")
	
func set_new_bounds(new_rect: Rect2, new_pos: Vector2):
	level_rect = new_rect
	$PlayerBody.position = new_pos
	$SpriteScale.position = $PlayerBody.position
	MySprite.rotation_degrees = $PlayerBody.rotation_degrees
	last_valid_position = new_pos
	
func update_collision() -> Shape2D:
	var new_collision
	match(curr_shape):
		SHAPE.BALL: 
			new_collision = CircleShape2D.new()
			new_collision.set_radius(float(curr_size) / 2.0)
		SHAPE.TRIANGLE:
			new_collision = ConvexPolygonShape2D.new()
			var new_vector_pool = PoolVector2Array()
			new_vector_pool.append_array(tri_collision.get_points())
			var scale = float(curr_size) / float(BASE_SIZE)
			for idx in range(new_vector_pool.size()): #Update the vector pool to reflect the size
				var new_vector = new_vector_pool[idx] * scale
				new_vector_pool.set(idx, new_vector)
			new_collision.set_points(new_vector_pool)
		_:		#This is the case for the box, walrus and custom modes.
			new_collision = RectangleShape2D.new()
			var new_extends = Vector2(float(curr_size) / 2.0, float(curr_size) / 2.0)
			new_collision.set_extents(new_extends)
			
	return new_collision