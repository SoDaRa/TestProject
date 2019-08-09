extends Node

#Colors for shapes
export var color_sequence = [Color(0.0, 0.0, 0.1, 1.0), Color(0.0, 1.0, 1.0, 1.0), Color(1.0, 0.0, 1.0, 1.0), Color(1.0, 1.0, 0.0, 1.0)]

#Default Background Color
var bg_color = Color(0.0,0.0,0.0,1.0)


var bg = Image.new() #Image for background
var bg_array = [] #Image Array for backgrounds
var bg_texture_array = [] #Array of Textures to apply crops of the bg image onto
var bg_sprite_array = [] #Array of sprites to apply image array onto
var images_to_process = -1
#Color splotches for coloring
var color1 = Image.new()
var color2 = Image.new()
var color3 = Image.new()
var clear = Image.new()
#var bgTexture: ImageTexture

#Size Changing
var MAX_SIZE = 80
var MIN_SIZE = 22
var curr_size = 75

#Trail
export var TRAIL_LENGTH = 300
var blank_ball = preload("res://Sprites/blank_ball.png")
var blank_box = preload("res://Sprites/blank_box.png")
#var blank_tri = preload("res://Sprites/blank_triangle.png")
var blank_old_tri = preload("res://Sprites/blank_triangle.png")
var trail_array = []
var trail_index = TRAIL_LENGTH - 1
var buffer = 0
var damage = 0

var percent_thread = Thread.new() #Thread for processing percent

func percent_calc(bg_to_check: Image):
	var count = 0.0
	var compressed_image = Image.new()
	compressed_image.copy_from(bg_to_check)
	compressed_image.resize(100, 100, 0)
	compressed_image.lock()
#	for x in range(bg_to_check.size()):
#		if base_bg[x] != bg_to_check[x]:
#			count += 1.0
	for x in range(100):
		for y in range(100):
			if compressed_image.get_pixel(x, y) != bg_color:
				count += 1.0

	var percent = (count / 10000.0) * 100
	compressed_image.unlock()
	call_deferred("percent_calc_done")
	return percent

func percent_calc_done():
	var percentage = percent_thread.wait_to_finish()
	print(percentage, "%")
	
func set_background():
	var curr_x = images_to_process / (bg.get_width() / 1000) 
	var curr_y = images_to_process % (bg.get_height() / 1000)
	
	bg_array[images_to_process] = bg.get_rect(Rect2(Vector2(curr_x * 1000, curr_y * 1000), Vector2(1000,1000)))
	bg_texture_array[images_to_process].set_data(bg_array[images_to_process])
	
	images_to_process -= 1
	if images_to_process == -1:
		for x in range(TRAIL_LENGTH):
			if x < buffer - damage && trail_array[x].z_index == -x:
				continue
			elif x < buffer && x > buffer - damage:
				trail_array[x].z_index = -TRAIL_LENGTH - x
				continue
			trail_array[x].position = Vector2(-1000,-1000)
			trail_array[x].offset.y = 0
		trail_index = TRAIL_LENGTH - 1
		damage = 0
		
func paint():
	if $Player.curr_shape != $Player.BALL_MODE:
		$Player/PlayerMask/Viewport/PMSprite.rotation_degrees = $Player.rotation_degrees
		yield(get_tree(), "idle_frame")
	
	#Trail Handling
	trail_array[trail_index].position = $Player.position
	trail_array[trail_index].rotation_degrees = $Player.rotation_degrees
	trail_array[trail_index].modulate = color_sequence[$Player.curr_color]
	trail_array[trail_index].scale = $Player/Sprite.scale
	
	if $Player.curr_shape == $Player.BOX_MODE:
		trail_array[trail_index].texture = blank_box
	elif $Player.curr_shape == $Player.BALL_MODE:
		trail_array[trail_index].texture = blank_ball
#		elif $Player.curr_shape == $Player.TRI_MODE:
#			trail_array[trail_index].texture = blank_tri
	elif $Player.curr_shape == $Player.OLD_TRI_MODE:
		trail_array[trail_index].texture = blank_old_tri
		trail_array[trail_index].offset.y = -3
	
	trail_index -= 1
	
	if trail_index == buffer:
		for x in range(buffer):
			trail_array[x].position = Vector2(-1000,-1000)
			trail_array[x].offset.y = 0
		images_to_process = bg_sprite_array.size() - 1
		
	if trail_index < buffer:
		trail_array[trail_index].z_index = -trail_index
		damage += 1
#			bgTexture.create_from_image(bg)
#			bgTexture.set_data(bg)
		
	
	#Get mask and player position
	var mask = $Player/PlayerMask/Viewport.get_texture().get_data()
	var play_pos = $Player.position - Vector2(37,37)
	

	#Paint Stuff
	if $Player.curr_color == 0:
		bg.blend_rect_mask(clear, mask, Rect2(0,0,75,75), play_pos)
	elif $Player.curr_color == 1:
		bg.blit_rect_mask(color1, mask, Rect2(0,0,75,75), play_pos)
	elif $Player.curr_color == 2:
		bg.blit_rect_mask(color2, mask, Rect2(0,0,75,75), play_pos)
	elif $Player.curr_color == 3:
		bg.blit_rect_mask(color3, mask, Rect2(0,0,75,75), play_pos)

# Called when the node enters the scene tree for the first time.
func _ready():
	bg.create(10000, 10000, false, Image.FORMAT_RGB8)
	color1.create(75,75, false, Image.FORMAT_RGB8)
	color2.create(75,75, false, Image.FORMAT_RGB8)
	color3.create(75,75, false, Image.FORMAT_RGB8)
	clear.create(75,75, false, Image.FORMAT_RGB8)
	bg.fill(bg_color)
	color1.fill(color_sequence[1])
	color2.fill(color_sequence[2])
	color3.fill(color_sequence[3])
	clear.fill(color_sequence[0])

#	bgTexture.create_from_image(bg)
#	$Background.set_texture(bgTexture)
#	base_bg = bg.get_data()
	
	for x in range(TRAIL_LENGTH):
		trail_array.append(Sprite.new())
		call_deferred("add_child", trail_array[x])
		trail_array[x].z_index = -x
		
	for x in range(bg.get_width() / 1000):
		for y in range(bg.get_height()/1000):
			var curr_index = x * (bg.get_width() / 1000) + y
			
			bg_array.append(bg.get_rect(Rect2(Vector2(x * 1000, y * 1000), Vector2(1000, 1000))))
			
			bg_texture_array.append(ImageTexture.new())
			bg_texture_array[curr_index].create_from_image(bg_array[curr_index])
			
			bg_sprite_array.append(Sprite.new())
			call_deferred("add_child", bg_sprite_array[curr_index])
			bg_sprite_array[curr_index].position = Vector2(x * 1000, y * 1000)
			bg_sprite_array[curr_index].texture = bg_texture_array[curr_index]
			bg_sprite_array[curr_index].z_index = -320 - x - y
			bg_sprite_array[curr_index].centered = false
			
	buffer = (bg.get_width() / 1000) * (bg.get_height() / 1000) + 5
	pass # Replace with function body.

func _process(delta):
	if images_to_process > -1:
		set_background()

	if Input.is_action_pressed("paint"):
		paint()

	if Input.is_action_just_released("paint"):
#		bgTexture.create_from_image(bg)
		if !percent_thread.is_active():
			percent_thread.start(self, "percent_calc", bg)

	#Size Swapping
	if Input.is_action_pressed("decrease_size") && curr_size != MIN_SIZE:
		var decreased_by = 1 * delta
		$Player/CollisionShape2D.scale.x -= decreased_by
		if $Player/CollisionShape2D.scale.x > 0.1: #Ensure the collision shape doesn't get so small it causes problems
			$Player/CollisionShape2D.scale.y -= decreased_by
			$Player/Sprite.scale.x -= decreased_by
			$Player/Sprite.scale.y -= decreased_by
			$Player/PlayerMask/Viewport/PMSprite.scale.x -= decreased_by
			$Player/PlayerMask/Viewport/PMSprite.scale.y -= decreased_by
			curr_size -= 1
			
		else:
			$Player/CollisionShape2D.scale.x += decreased_by
			curr_size = MIN_SIZE

	if Input.is_action_pressed("increase_size") && curr_size != MAX_SIZE:
		var increased_by = 1 * delta
		$Player/CollisionShape2D.scale.x += increased_by
		$Player/CollisionShape2D.scale.y += increased_by
		$Player/Sprite.scale.x += increased_by
		$Player/Sprite.scale.y += increased_by
		$Player/PlayerMask/Viewport/PMSprite.scale.x += increased_by
		$Player/PlayerMask/Viewport/PMSprite.scale.y += increased_by
		curr_size += 1