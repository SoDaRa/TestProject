extends Node

var percent_thread = Thread.new() #Thread for processing percent
var percent_colored = 0.0

var image_array = []
var scale_bg_image_by = Vector2(1.0,1.0)

var bg_color = Color(0.0,0.0,0.0,1.0)

export var LEVEL_SIZE = Vector2(3111,2000)	#Total size of the level and background
export var BG_NODE_SIZE = 1000 		 #Size of an individual background node's image
export var BG_NODE_SPRITE_SIZE = 500 #Size of the sprites that make up the background node's. See BGHandler.gd for more

var bg_node_array = [] 		#The array of nodes that hold and handle the background images
var node_array_width
var node_array_height
var bg_node = preload("res://Scenes/BGNode.tscn")

var bg_updated_array_1 = []
var bg_updated_array_2 = []
var bua_1_in_use = false #bua = bg_updated_array
var bg_nodes_to_process = -1

var player_camera

var zoom_camera_position: Vector2
var zoom_camera_scale = Vector2(6.8,6.8)

var wall_width = 100

func _on_Root_ready(): #TODO: Will need to fix this when loading levels
	player_camera = get_node("../Player/PlayerBody/Camera2D")
#	player_camera.limit_top = 0
#	player_camera.limit_bottom = LEVEL_SIZE.y
#	player_camera.limit_left = 0
#	player_camera.limit_right = LEVEL_SIZE.x
	zoom_camera_position = Vector2(LEVEL_SIZE.x/2, LEVEL_SIZE.y/2)
	
	get_node("../Player/PlayerBody").position = $Position2D.position
	
# Called when the node enters the scene tree for the first time.
func _ready():
	#Setup bg_nodes
	node_array_width = int(ceil(LEVEL_SIZE.x / BG_NODE_SIZE))
	node_array_height = int(ceil(LEVEL_SIZE.y / BG_NODE_SIZE))
	
	if LEVEL_SIZE.x > 16000:
		scale_bg_image_by.x = 16000 / LEVEL_SIZE.x
	if LEVEL_SIZE.y > 16000:
		scale_bg_image_by.y = 16000 / LEVEL_SIZE.y
	
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
			bg_node_array[curr_index].connect("update_complete", self, "_on_BGNode_update_complete")
			
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
	if Input.is_action_just_pressed("Dummy_Button"):
		var num_1 = ceil(LEVEL_SIZE.x / BG_NODE_SIZE)
		print(num_1)
	if Input.is_action_just_released("paint"):
		if get_tree().paused == false:
			if bg_nodes_to_process == -1:
				var curr_node = -1
				if bua_1_in_use == false:
					bg_nodes_to_process = bg_updated_array_1.size() - 1
					bua_1_in_use = true
					curr_node = bg_updated_array_1.pop_back()
				else:
					bg_nodes_to_process = bg_updated_array_2.size() - 1
					bua_1_in_use = false
					curr_node = bg_updated_array_2.pop_back()
#				print("Forced Background Update: Release")
#				print("Nodes to Process is ", bg_nodes_to_process + 1)
#				print("Calling node ", curr_node)
				bg_node_array[curr_node].start_sprite_update()
				
				if curr_node < 0:
					print("Curr node < 0: ", curr_node)
				if curr_node >= bg_node_array.size():
					print("curr node > bg_node_array.size(): ", curr_node)
				$TrailHandler.swap_to_buffer()
		
	if Input.is_action_just_pressed("save_background"): #TODO: Move save into a thread
		get_tree().paused = true
		var curr_time = OS.get_datetime()
		var image_name = "../" + str(curr_time.month) + "_" + str(curr_time.day) + "_" + str(curr_time.year) + "_" 
		image_name = image_name + str(curr_time.hour)  + "_" + str(curr_time.minute) + "_" + str(curr_time.second) + ".png"
		var my_bg = bg_from_array(image_array)
		my_bg.save_png(image_name)
		get_tree().paused = false

	if Input.is_action_just_pressed("zoom_out"):
		get_tree().paused = true
		player_camera._tween_zoom(zoom_camera_scale)
		player_camera._tween_position(zoom_camera_position)
		player_camera.limit_top = -1000000
		player_camera.limit_bottom = 1000000
		player_camera.limit_left = -1000000
		player_camera.limit_right = 1000000
		
	if Input.is_action_just_released("zoom_out"):
		get_tree().paused = false
		player_camera._reset()
#		player_camera.limit_top = 0
#		player_camera.limit_bottom = LEVEL_SIZE.y
#		player_camera.limit_left = 0
#		player_camera.limit_right = LEVEL_SIZE.x

# warning-ignore:unused_argument
func percent_calc(num: int):
	var count = 0.0
	var compressed_image = bg_from_array(image_array, true)
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
	if percentage > percent_colored:
		percent_colored = percentage

func _on_Player_paint(mask: Image, mask_pos: Vector2, player_color: Color):
	$TrailHandler.draw_trail(mask, mask_pos, player_color)
	var paint_nodes = check_nodes_to_paint(mask_pos, mask.get_width(), mask.get_height())
	if paint_nodes.size() != 0:
		for idx in range(paint_nodes.size()):
			bg_node_array[paint_nodes[idx]].paint_background(mask, mask_pos, player_color)
			
			if bua_1_in_use == false:
				if bg_updated_array_1.find(paint_nodes[idx]) == -1:
					bg_updated_array_1.push_back(paint_nodes[idx])
			else:
				if bg_updated_array_2.find(paint_nodes[idx]) == -1:
					bg_updated_array_2.push_back(paint_nodes[idx])

	
func _on_TrailHandler_main_empty():
	if bg_nodes_to_process == -1:
		var curr_node = -1
		if bua_1_in_use == false:
			bg_nodes_to_process = bg_updated_array_1.size() - 1
			bua_1_in_use = true
			curr_node = bg_updated_array_1.pop_back()
		else:
			bg_nodes_to_process = bg_updated_array_2.size() - 1
			bua_1_in_use = false
			curr_node = bg_updated_array_2.pop_back()
#		print("Forced Background Update: Trail")
#		print("Nodes to Process is ", bg_nodes_to_process + 1)
#		print("Calling node ", curr_node)
		if curr_node < 0:
			print("Curr node < 0: ", curr_node)
		if curr_node >= bg_node_array.size():
			print("curr node > bg_node_array.size(): ", curr_node)
		bg_node_array[curr_node].start_sprite_update()

#func _on_BGNode_update_start(node_idx: int):
#	print("Node Starting Update: ", node_idx)
#	if bg_nodes_to_process == -1:
#		if bua_1_in_use && bg_updated_array_1.find(node_idx) != -1:
#			bg_updated_array_1.erase(node_idx)
#		if !bua_1_in_use && bg_updated_array_2.find(node_idx) != -1:
#			bg_updated_array_2.erase(node_idx)

func _on_BGNode_update_complete(bg_image:Image, node_idx: int):
#	print("Node Ending Update: ", node_idx)
	image_array[node_idx] = bg_image
	bg_nodes_to_process -= 1
	if bg_nodes_to_process == -1:
		$TrailHandler.hide_trail()
		if !percent_thread.is_active() && get_tree().paused == false: 
			percent_thread.start(self, "percent_calc", 1)
#		print("Node processing complete")
#		print(" ")
	else:
		var curr_node = -1
		if bua_1_in_use:
			curr_node = bg_updated_array_1.pop_back()
		else:
			curr_node = bg_updated_array_2.pop_back()
		
		if curr_node < 0:
			print("Curr node < 0")
		if curr_node >= bg_node_array.size():
			print("curr node > bg_node_array.size()")
#		print("Calling node ", curr_node)
		bg_node_array[curr_node].start_sprite_update()

func bg_from_array(img_array: Array, should_resize = false, resize_width = 100, resize_height = 100) -> Image:
	var my_bg = Image.new()
	if LEVEL_SIZE.x <= 16000 && LEVEL_SIZE.y <= 16000: #16384 is the max height and width of an Image. But rather not push it past 16000.
		my_bg.create(LEVEL_SIZE.x, LEVEL_SIZE.y, false, Image.FORMAT_RGB8)
		for idx in range(img_array.size()):
			if img_array[idx].get_data().size() == 0: #Prevents reading from an image that hasn't been set yet
				continue
			my_bg.blit_rect(img_array[idx], Rect2(0, 0, img_array[idx].get_width(), img_array[idx].get_height()), bg_node_array[idx].position)
	else:
		my_bg.create(16000, 16000, false, Image.FORMAT_RGB8)
		for idx in range(img_array.size()): 
			#Output has seams. Probably difficult to fix.
			my_bg.blit_rect(img_array[idx], Rect2(0, 0, img_array[idx].get_width(), img_array[idx].get_height()), bg_node_array[idx].position * scale_bg_image_by)
	if should_resize:
		my_bg.resize(resize_width, resize_height, Image.INTERPOLATE_NEAREST)
	return my_bg

func check_nodes_to_paint(mask_pos: Vector2, width: float, height: float) -> Array:
	var nodes_to_paint = []
	#Get left, top, right and bottom
	var left = int(floor(mask_pos.x / BG_NODE_SIZE))
	var top = int(floor(mask_pos.y / BG_NODE_SIZE))
	var right = int(floor((mask_pos.x + width) / BG_NODE_SIZE))
	var bottom = int(floor((mask_pos.y + height) / BG_NODE_SIZE))
	
	#Figure out which sprites each of the four corners are in
	var topleft = int(left * node_array_height + top)
	var topright = int(right * node_array_height + top)
	var bottomleft = int(left * node_array_height + bottom)
	var bottomright = int(right * node_array_height + bottom)
	
	#These are just to avoid redundant find calls if two corners are in the same section or one is out of bounds
	var skip_topleft = left < 0 || top < 0 || topleft < 0
	var skip_topright = topleft == topright || right >= node_array_width || top < 0 || topright >= bg_node_array.size()
	var skip_bottomleft = topleft == bottomleft || bottom >= node_array_height || left < 0 || bottomleft >= bg_node_array.size()
	var skip_bottomright = (bottomright == topright) || (bottomright == bottomleft) || right >= node_array_width || bottom >= node_array_height 
	skip_bottomright = skip_bottomright || bottomright >= bg_node_array.size()
	
	if !skip_topleft:
		nodes_to_paint.push_back(topleft)
	if !skip_topright:
		nodes_to_paint.push_back(topright)
	if !skip_bottomleft:
		nodes_to_paint.push_back(bottomleft)
	if !skip_bottomright:
		nodes_to_paint.push_back(bottomright)
	
	return nodes_to_paint