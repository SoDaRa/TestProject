extends Node2D

var percent_thread = Thread.new() 			#Thread for processing percent
#var save_background_thread = Thread.new()	#Thread for saving the background
var percent_colored = 0.0
#var save_bg_next_pass = false

var image_array = []					#Holds the various background images after an update. Copied to threads for use
var scale_bg_image_by = Vector2(1.0,1.0)

var bg_color = Color(0.0,0.0,0.0,1.0)

const MAX_IMAGE_SIZE = Vector2(16000, 16000)#Max size an Image can be. Can go up to 16384x16384, but I'd rather stay under that
export var LEVEL_SIZE = Vector2(4000,4000)	#Total size of the level and background
export var BG_NODE_SIZE = 500 				#Size of an individual background node's image
export var BG_NODE_SPRITE_SIZE = 250 		#Size of the sprites that make up the background node's. See BGHandler.gd for more


var bg_node_array = [] 		#The array of nodes that hold and handle the background images
var node_array_width: int		#How many columns the array has
var node_array_height: int		#How many rows the array has
var bg_node = preload("res://Scenes/BGNode.tscn")

var paint_log = []
var bg_update_list = []
var nodes_to_update = -1

const wall_width = 50	#How thick the borders of the level are.

signal update_started
signal update_completed
	
# Called when the node enters the scene tree for the first time.
func _ready():
	#Setup bg_nodes
	node_array_width = int(ceil(LEVEL_SIZE.x / BG_NODE_SIZE))
	node_array_height = int(ceil(LEVEL_SIZE.y / BG_NODE_SIZE))
	
	if LEVEL_SIZE.x > MAX_IMAGE_SIZE.x:
		scale_bg_image_by.x = MAX_IMAGE_SIZE.x / LEVEL_SIZE.x
	if LEVEL_SIZE.y > MAX_IMAGE_SIZE.y:
		scale_bg_image_by.y = MAX_IMAGE_SIZE.y / LEVEL_SIZE.y
	
	for x in range(node_array_width):
		for y in range(node_array_height):
			var curr_index = (x * node_array_height) + y
			var node_position = Vector2(x * BG_NODE_SIZE, y * BG_NODE_SIZE)
			var node_bg_size_vector = Vector2(BG_NODE_SIZE, BG_NODE_SIZE)
			var node_sprite_size_vector = Vector2(BG_NODE_SPRITE_SIZE, BG_NODE_SPRITE_SIZE)
			
			if node_position.x + BG_NODE_SIZE > LEVEL_SIZE.x:
				node_bg_size_vector.x = LEVEL_SIZE.x - node_position.x
			if node_position.y + BG_NODE_SIZE > LEVEL_SIZE.y:
				node_bg_size_vector.y = LEVEL_SIZE.y - node_position.y
#			print("Node_bg_size is ", node_bg_size_vector)
			
			bg_node_array.append(bg_node.instance())
			call_deferred("add_child", bg_node_array[curr_index])
			bg_node_array[curr_index].position = node_position
			bg_node_array[curr_index].index_id = curr_index
			bg_node_array[curr_index].setup(node_bg_size_vector, node_sprite_size_vector, bg_color, scale_bg_image_by)
			bg_node_array[curr_index].connect("update_complete", self, "_progress_update")
			
			image_array.append(Image.new())
#			bg_node_array[curr_index].connect("update_start", self, "_on_BGNode_update_start")
	
	#Set up level walls
	var v_wall_collision = RectangleShape2D.new()
	var h_wall_collision = RectangleShape2D.new()
	
	v_wall_collision.extents = Vector2(wall_width, (LEVEL_SIZE.y + (wall_width * 4)) / 2)
	h_wall_collision.extents = Vector2(LEVEL_SIZE.x / 2, wall_width)
	
	$Borders/LeftWall/CollisionShape2D.shape = v_wall_collision
	$Borders/RightWall/CollisionShape2D.shape = v_wall_collision
	$Borders/Ceiling/CollisionShape2D.shape = h_wall_collision
	$Borders/Floor/CollisionShape2D.shape = h_wall_collision

	$Borders/LeftWall.position = Vector2(-wall_width, LEVEL_SIZE.y/2)
	$Borders/Ceiling.position = Vector2(LEVEL_SIZE.x/2, -wall_width)
	$Borders/RightWall.position = Vector2(LEVEL_SIZE.x+wall_width, LEVEL_SIZE.y/2)
	$Borders/Floor.position = Vector2(LEVEL_SIZE.x/2, LEVEL_SIZE.y+wall_width)

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_released("paint"):
		if nodes_to_update == -1:
			start_update() #NOTE: Release update start 
#			print("Background Update: Release") 
		
#	if Input.is_action_just_pressed("save_background"):
#		var bg_updated = nodes_to_update == -1 && paint_log.size() == 0
#		if !save_background_thread.is_active() && get_tree().paused == false && bg_updated: 
#			save_background_thread.start(self, "save_background", image_array)
#		elif !save_background_thread.is_active() && get_tree().paused == false && !bg_updated: 
#			save_bg_next_pass = true #Shouldn't do it right now but will do it after next update is complete

# warning-ignore:unused_argument
func percent_calc(my_img_array: Array):
	var count = 0
	var compressed_image = bg_from_array(my_img_array, true)
	compressed_image.lock()
	for x in range(100):
		for y in range(100):
			if compressed_image.get_pixel(x, y) != bg_color:
				count += 1
	
	var percent = (float(count) / 10000.0) * 100
	compressed_image.unlock()
	call_deferred("percent_calc_done")
	return percent

func percent_calc_done():
	var percentage = percent_thread.wait_to_finish()
	print("Level: ", percentage, "%")
	if percentage > percent_colored:
		percent_colored = percentage

func save_background(): #Old arg my_img_array: Array
	var my_img_array = []
	for bg_node in bg_node_array:
		my_img_array.append(bg_node.bg)
	var curr_time = OS.get_datetime()
	var image_name = "MyImage" + str(curr_time.month) + "_" + str(curr_time.day) + "_" + str(curr_time.year) + "_" + \
								 str(curr_time.hour)  + "_" + str(curr_time.minute) + "_" + str(curr_time.second) + ".png"
	var my_bg = bg_from_array(my_img_array)
	my_bg.save_png(image_name)
	print("Background Save Complete")

#func save_background_done():
#	save_background_thread.wait_to_finish()
#	print("Background Save Complete")

func _on_Player_paint(mask: Image, mask_pos: Vector2):
	var new_pos = mask_pos - self.position
	var paint_nodes = check_nodes_to_paint(new_pos, mask.get_width(), mask.get_height())
	if paint_nodes.size() != 0:
		for node in paint_nodes:
			bg_node_array[node].paint_background(mask, mask_pos)
			
			if paint_log.find(node) == -1:
				paint_log.push_back(node)


func _on_Trail_main_empty():
	if nodes_to_update == -1:
		start_update()
#		print("Background Update: Trail") #NOTE: Trail update start

func start_update():
	var curr_node = -1
	nodes_to_update = paint_log.size() - 1
	if nodes_to_update == -1:
#		print("Cancel Update: No nodes to process")
		return
	#Swap the lists
	while paint_log.size() > 0:
		bg_update_list.push_back(paint_log.pop_front())
	curr_node = bg_update_list.pop_back()
	
	assert(curr_node != null)
	assert(curr_node >= 0)
	assert(curr_node < bg_node_array.size())
	bg_node_array[curr_node].start_sprite_update()
	emit_signal("update_started")
	
func _progress_update(bg_image:Image, node_idx: int):
#	print("Node Ending Update: ", node_idx)
	image_array[node_idx] = bg_image #TODO: Make this not cause so much lagggg. Access sprites to get in chunks?
	nodes_to_update -= 1
	
	#Ending the update
	if nodes_to_update == -1:
		end_update()
		return
	
	#Continuing the update
	var curr_node = -1
	curr_node = bg_update_list.pop_back()
	assert(curr_node != null)
	assert(curr_node >= 0)
	assert(curr_node < bg_node_array.size())
#	print("Calling node ", curr_node)
	bg_node_array[curr_node].start_sprite_update()

func end_update():
	if !percent_thread.is_active() && get_tree().paused == false: 
		percent_thread.start(self, "percent_calc", image_array)
	#Save bg now that image_array is up to date
#	if save_bg_next_pass && !save_background_thread.is_active(): 
#		save_background_thread.start(self, "save_background", image_array)
#		save_bg_next_pass = false
	emit_signal("update_completed")
#	print("Node processing complete")
#	print(" ")

func bg_from_array(img_array: Array, should_resize = false, resize_width = 100, resize_height = 100) -> Image:
	var my_bg = Image.new()
	if LEVEL_SIZE.x <= MAX_IMAGE_SIZE.x && LEVEL_SIZE.y <= MAX_IMAGE_SIZE.y: 
		my_bg.create(LEVEL_SIZE.x, LEVEL_SIZE.y, false, Image.FORMAT_RGBA8)
		my_bg.fill(bg_color)
		for idx in range(img_array.size()):
			if img_array[idx].get_data().size() == 0: #Prevents reading from an image that hasn't been set yet
				continue
			my_bg.blit_rect(img_array[idx], Rect2(0, 0, img_array[idx].get_width(), img_array[idx].get_height()), bg_node_array[idx].position)
	else:
		my_bg.create(MAX_IMAGE_SIZE.x, MAX_IMAGE_SIZE.y, false, Image.FORMAT_RGBA8)
		my_bg.fill(bg_color)
		for idx in range(img_array.size()): 
			if img_array[idx].get_data().size() == 0: #Prevents reading from an image that hasn't been set yet
				continue
			var img_position = bg_node_array[idx].position * scale_bg_image_by
			img_position = Vector2(floor(img_position.x), floor(img_position.y))
			my_bg.blit_rect(img_array[idx], Rect2(0, 0, img_array[idx].get_width(), img_array[idx].get_height()), img_position)
	if should_resize:
		my_bg.resize(resize_width, resize_height, Image.INTERPOLATE_NEAREST)
	return my_bg

#TODO: Move this into a class and make a static function so BGHandler and this can share it.
func check_nodes_to_paint(mask_pos: Vector2, width: float, height: float) -> Array:
	var nodes_to_paint = []
	#Get left, top, right and bottom
	var left = int(floor(mask_pos.x / BG_NODE_SIZE))
	var top = int(floor(mask_pos.y / BG_NODE_SIZE))
	var right = int(floor((mask_pos.x + width) / BG_NODE_SIZE))
	var bottom = int(floor((mask_pos.y + height) / BG_NODE_SIZE))
	
	var left_bad = left < 0 || left >= node_array_width
	var top_bad = top < 0 || top >= node_array_height
	var right_bad = right < 0 || right >= node_array_width
	var bottom_bad = bottom < 0 || bottom >= node_array_width
	#Figure out which sprites each of the four corners are in
	var topleft = -1
	var topright = -1
	var bottomleft = -1
	var bottomright = -1
	if !top_bad && !left_bad:
		topleft = left * node_array_height + top
	if !top_bad && !right_bad:
		topright = right * node_array_height + top
	if !bottom_bad && !left_bad:
		bottomleft = left * node_array_height + bottom
	if !bottom_bad && !right_bad:
		bottomright = right * node_array_height + bottom
	
	#These are just to avoid redundant find calls if two corners are in the same section or one is out of bounds
	var skip_topleft = left_bad || top_bad || topleft < 0 || topleft >= bg_node_array.size()
	var skip_topright = topleft == topright || right_bad || top_bad || topright < 0 || topright >= bg_node_array.size()
	var skip_bottomleft = topleft == bottomleft || left_bad || bottom_bad || bottomleft < 0 || bottomleft >= bg_node_array.size()
	var skip_bottomright = bottomright == topright || bottomright == bottomleft || right_bad || bottom_bad || \
							bottomright < 0 || bottomright >= bg_node_array.size()
	
	if !skip_topleft:
		nodes_to_paint.push_back(topleft)
	if !skip_topright:
		nodes_to_paint.push_back(topright)
	if !skip_bottomleft:
		nodes_to_paint.push_back(bottomleft)
	if !skip_bottomright:
		nodes_to_paint.push_back(bottomright)
	
	return nodes_to_paint

#func _private_set(value = null):
#	print("Cannot set private variable")
#	return value
#
#func _private_get(value = null):
#	print("Cannot get private variable")
#	return value