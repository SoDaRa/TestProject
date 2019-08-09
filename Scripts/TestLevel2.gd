extends Node
#ver2

#Default Background Color
var bg_color = Color(0.0,0.0,0.0,1.0)

var bg = Image.new() #Image for background
var bg_array = [] #Image Array for backgrounds
var bg_texture_array = [] #Array of Textures to apply crops of the bg image onto
var bg_sprite_array = [] #Array of sprites to apply image array onto
var images_to_process = -1
export var BG_SIZE = 4000 #Must be wholly divisible by BG_CROP_DIMEN
var BG_CROP_DIMEN = 500 # BG sprite dimensions. For now x and y length will be equal

var sprite_rect_array = []
var paint_array_1 = []
var paint_array_2 = []
var painted_1_in_use = false #Refers to if it should write to painted_1 or 2

#Trail
export var TRAIL_LENGTH = 300
var blank_ball = preload("res://Sprites/blank_ball.png")
var blank_box = preload("res://Sprites/blank_box.png")
var blank_tri = preload("res://Sprites/blank_triangle.png")
var blank_walrus = preload("res://Sprites/blank_walrus.png")
var blank_custom = preload("res://Sprites/blank_custom.png")
var trail_array = []  #Main Trail array
var trail_idx = TRAIL_LENGTH - 1

var buffer_size = 0
var buffer_1 = []
var buffer_2 = []
var buffer_idx = 0
var buffer_1_in_use = false #Refers to if buffer_1 is currently displayed

var percent_thread = Thread.new() #Thread for processing percent

func percent_calc(bg_to_check: Image):
	var count = 0.0
	var compressed_image = Image.new()
	compressed_image.copy_from(bg_to_check)
	compressed_image.resize(100, 100, 0)
	compressed_image.lock()
	
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
	var tile = -1
	if painted_1_in_use == true:
		tile = paint_array_1.pop_front()
	else:
		tile = paint_array_2.pop_front()
	if tile == -1:
		print("ERROR!!")
	if tile >= bg_array.size():
		tile = 0
	var curr_x = tile / (bg.get_width() / BG_CROP_DIMEN) 
	var curr_y = tile % (bg.get_height() / BG_CROP_DIMEN)
	
	bg_array[tile] = bg.get_rect(Rect2(Vector2(curr_x * BG_CROP_DIMEN, curr_y * BG_CROP_DIMEN), Vector2(BG_CROP_DIMEN,BG_CROP_DIMEN)))
	bg_texture_array[tile].set_data(bg_array[tile])
	
	images_to_process -= 1
	
	#When done updating the background, reset the trail_array
	if images_to_process == -1:
		for x in range(TRAIL_LENGTH):
			if x < buffer_size:
				if buffer_1_in_use == true:
					buffer_1[x].position = Vector2(-1000,-1000)
#					buffer_1[x].offset.y = 0
					buffer_1[x].z_index = -x
					buffer_2[x].z_index = -TRAIL_LENGTH - buffer_size - x #But this beneath main trail
				else:
					buffer_2[x].position = Vector2(-1000,-1000)
#					buffer_2[x].offset.y = 0
					buffer_2[x].z_index = -x
					buffer_1[x].z_index = -TRAIL_LENGTH - buffer_size - x
			trail_array[x].position = Vector2(-1000,-1000)
			trail_array[x].offset.y = 0 #This is only to set it back to normal if it was a triangle
		trail_idx = TRAIL_LENGTH - 1
		buffer_idx = buffer_size - 1
		if buffer_1_in_use == false:
			buffer_1_in_use = true
		else:
			buffer_1_in_use = false
		print("Clear")
		print(" ")

#Trail Code
func paint_trail():
	#Putting at player position
	trail_array[trail_idx] = update_sprite(trail_array[trail_idx])
	trail_idx -= 1
	
	#Start setting the background sprites
	if trail_idx == -1 && images_to_process == -1:
		if painted_1_in_use == false:
			images_to_process = paint_array_1.size() - 1
			painted_1_in_use = true
			print("Images to Process is ", images_to_process + 1)
		else:
			images_to_process = paint_array_2.size() - 1
			painted_1_in_use = false
			print("Images to Process is ", images_to_process + 1)
func paint_buffer():
	if buffer_1_in_use == false:
		buffer_1[buffer_idx] = update_sprite(buffer_1[buffer_idx])
	else:
		buffer_2[buffer_idx] = update_sprite(buffer_2[buffer_idx])
	buffer_idx -= 1

func update_sprite(to_update: Sprite) -> Sprite:
	to_update.position = $Player.position
	to_update.rotation_degrees = $Player.rotation_degrees
	to_update.modulate = $Player.color_sequence[$Player.curr_color] #Still kinda hacky but if only for trail I guess okay
	to_update.scale = $Player/Sprite.scale
	
	#Setting to player shape
	if $Player.curr_shape == $Player.BOX_MODE:
		to_update.texture = blank_box
	elif $Player.curr_shape == $Player.BALL_MODE:
		to_update.texture = blank_ball
	elif $Player.curr_shape == $Player.TRI_MODE:
		to_update.texture = blank_tri
		#to_update.offset.y = -3
	elif $Player.curr_shape == $Player.WALRUS_MODE:
		to_update.texture = blank_walrus
	elif $Player.curr_shape == $Player.CUSTOM_MODE:
		to_update.texture = blank_custom
	
	return to_update
# Called when the node enters the scene tree for the first time.
func _ready():
	#Setup background image
	bg.create(BG_SIZE, BG_SIZE, false, Image.FORMAT_RGB8)
	bg.fill(bg_color)
	buffer_size = (bg.get_width() / BG_CROP_DIMEN) * (bg.get_height() / BG_CROP_DIMEN) + 5
	buffer_idx = buffer_size - 1
	$Player/Camera2D.limit_top = 0
	$Player/Camera2D.limit_bottom = BG_SIZE
	$Player/Camera2D.limit_left = 0
	$Player/Camera2D.limit_right = BG_SIZE
	$ZoomCamera.position = Vector2(BG_SIZE/2, BG_SIZE/2)
	
	$Borders/LeftWall.position.y = BG_SIZE/2
	$Borders/Ceiling.position.x = BG_SIZE/2
	$Borders/RightWall.position.x = BG_SIZE+50
	$Borders/RightWall.position.y = BG_SIZE/2
	$Borders/Floor.position.x = BG_SIZE/2
	$Borders/Floor.position.y = BG_SIZE+50
	#Setup Trail
	for x in range(TRAIL_LENGTH):
		trail_array.append(Sprite.new())
		call_deferred("add_child", trail_array[x])
		trail_array[x].z_index = -x - buffer_size - 1
	
	#Setup buffer
	for x in range(buffer_size):
		buffer_1.append(Sprite.new())
		buffer_2.append(Sprite.new())
		call_deferred("add_child", buffer_1[x])
		call_deferred("add_child", buffer_2[x])
		buffer_1[x].z_index = -x
		buffer_2[x].z_index = -x
	
	#Setup background sprites
	for x in range(bg.get_width() / BG_CROP_DIMEN): #consider ways to divide up background for non-1000x1000 sizes
		for y in range(bg.get_height()/BG_CROP_DIMEN):
			var curr_index = x * (bg.get_width() / BG_CROP_DIMEN) + y
			var sprite_rect = Rect2(Vector2(x * BG_CROP_DIMEN, y * BG_CROP_DIMEN), Vector2(BG_CROP_DIMEN, BG_CROP_DIMEN))
			bg_array.append(bg.get_rect(sprite_rect))
			
			bg_texture_array.append(ImageTexture.new())
			bg_texture_array[curr_index].create_from_image(bg_array[curr_index], 5)
			
			bg_sprite_array.append(Sprite.new())
			call_deferred("add_child", bg_sprite_array[curr_index])
			bg_sprite_array[curr_index].position = Vector2(x * BG_CROP_DIMEN, y * BG_CROP_DIMEN)
			bg_sprite_array[curr_index].texture = bg_texture_array[curr_index]
			bg_sprite_array[curr_index].z_index = -2000
			bg_sprite_array[curr_index].centered = false
			
			sprite_rect_array.append(sprite_rect)

# warning-ignore:unused_argument
func _process(delta):
	if images_to_process > -1:
		set_background()

	if Input.is_action_just_released("paint"):
		if !percent_thread.is_active() && get_tree().paused == false:
			percent_thread.start(self, "percent_calc", bg)
		if images_to_process == -1:
			if painted_1_in_use == false:
				images_to_process = paint_array_1.size() - 1
				painted_1_in_use = true
				print("Images to Process is ", images_to_process + 1)
			else:
				images_to_process = paint_array_2.size() - 1
				painted_1_in_use = false
				print("Images to Process is ", images_to_process + 1)
		
	if Input.is_action_just_pressed("save_background"):
		var curr_time = OS.get_datetime()
		var image_name = str(curr_time.day) + "_" + str(curr_time.month) + "_" + str(curr_time.year) + "_" + str(curr_time.hour) + "_" + str(curr_time.minute) + "_" + str(curr_time.second) + ".png"
		bg.save_png(image_name)

	if Input.is_action_just_pressed("zoom_out"):
		get_tree().paused = true
		$Player/Camera2D._tween_zoom($ZoomCamera.zoom)
		$Player/Camera2D._tween_position($ZoomCamera.position)
		$Player/Camera2D.limit_top = -1000000
		$Player/Camera2D.limit_bottom = 1000000
		$Player/Camera2D.limit_left = -1000000
		$Player/Camera2D.limit_right = 1000000
		
	if Input.is_action_just_released("zoom_out"):
		get_tree().paused = false
		$Player/Camera2D._reset()
		$Player/Camera2D.limit_top = 0
		$Player/Camera2D.limit_bottom = 4000
		$Player/Camera2D.limit_left = 0
		$Player/Camera2D.limit_right = 4000

func _on_Player_paint_signal(player_pos:Vector2, mask:Image, current_color:Color):
	var player_color = Image.new()
	player_color.create(mask.get_width(),mask.get_height(), false, Image.FORMAT_RGB8)
	player_color.fill(current_color)
	bg.blit_rect_mask(player_color, mask, Rect2(0,0,mask.get_width(), mask.get_height()), player_pos)
	check_painted(player_pos, mask.get_width(), mask.get_height())
	if get_tree().paused == false:
		if trail_idx > -1 && images_to_process == -1:
			paint_trail()
		else:
			paint_buffer()

#Calculates which squares have been painted
#Doesn't check the actual position where the player painted, but a rectangle around their position
#This may be inaccurate and may lead to some sprites being updated that don't need it, but better safe than sorry
func check_painted(player_pos:Vector2, width:float, height:float):
#	var player_rect = Rect2(player_pos, Vector2(width, height))
	var left = floor(player_pos.x / BG_CROP_DIMEN)
	var top = floor(player_pos.y / BG_CROP_DIMEN)
	var right = floor((player_pos.x + width) / BG_CROP_DIMEN)
	var bottom = floor( (player_pos.y + height) / BG_CROP_DIMEN)
	var topleft = int(left * (bg.get_height()/BG_CROP_DIMEN) + top)
	var topright = int(right * (bg.get_height() / BG_CROP_DIMEN) + top)
	var bottomleft = int(left * (bg.get_height() / BG_CROP_DIMEN) + bottom)
	var bottomright = int(right * (bg.get_height() / BG_CROP_DIMEN) + bottom)
	var skip_topright = topleft == topright
	var skip_bottomleft = topleft == bottomleft
	var skip_bottomright = (bottomright == topright) || (bottomright == bottomleft)
	
	if painted_1_in_use == false:
		if paint_array_1.find(topleft) == -1:
			paint_array_1.push_back(topleft)
		if !skip_topright:
			if paint_array_1.find(topright) == -1:
				paint_array_1.push_back(topright)
		if !skip_bottomleft:
			if paint_array_1.find(bottomleft) == -1:
				paint_array_1.push_back(bottomleft)
		if !skip_bottomright:
			if paint_array_1.find(bottomright) == -1:
				paint_array_1.push_back(bottomright)
#		painted_array_1[left * (bg.get_width() / BG_CROP_DIMEN) + top] = true
#		painted_array_1[left * (bg.get_width() / BG_CROP_DIMEN) + bottom] = true
#		painted_array_1[right * (bg.get_width() / BG_CROP_DIMEN) + top] = true
#		painted_array_1[right * (bg.get_width() / BG_CROP_DIMEN) + bottom] = true
	else:
		if paint_array_2.find(topleft) == -1:
			paint_array_2.push_back(topleft)
		if !skip_topright:
			if paint_array_2.find(topright) == -1:
				paint_array_2.push_back(topright)
		if !skip_bottomleft:
			if paint_array_2.find(bottomleft) == -1:
				paint_array_2.push_back(bottomleft)
		if !skip_bottomright:
			if paint_array_2.find(bottomright) == -1:
				paint_array_2.push_back(bottomright)
#		painted_array_2[left * (bg.get_width() / BG_CROP_DIMEN) + top] = true
#		painted_array_2[left * (bg.get_width() / BG_CROP_DIMEN) + bottom] = true
#		painted_array_2[right * (bg.get_width() / BG_CROP_DIMEN) + top] = true
#		painted_array_2[right * (bg.get_width() / BG_CROP_DIMEN) + bottom] = true
#	for idx in range(sprite_rect_array.size()):
#		if sprite_rect_array[idx].intersects(player_rect):
#			if painted_1_in_use == false:
#				painted_array_1[idx] = true
#			else:
#				painted_array_2[idx] = true