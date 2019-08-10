extends Node

var percent_thread = Thread.new() #Thread for processing percent
var percent_colored = 0.0

var bg_color = Color(0.0,0.0,0.0,1.0)

export var LEVEL_SIZE = Vector2(16000,16000)	#Total size of the level and background
export var BG_NODE_SIZE = 4000 		 #Size of an individual background node's image
export var BG_NODE_SPRITE_SIZE = 250 #Size of the sprites that make up the background node's. See BGHandler.gd for more

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
var zoom_camera_scale = Vector2(25,25)

var wall_width = 50

func _on_Root_ready(): #TODO: Will need to fix this when loading levels
	player_camera = get_node("../Player/RigidBody2D/Camera2D")
	player_camera.limit_top = 0
	player_camera.limit_bottom = LEVEL_SIZE.y
	player_camera.limit_left = 0
	player_camera.limit_right = LEVEL_SIZE.x
	zoom_camera_position = Vector2(LEVEL_SIZE.x/2, LEVEL_SIZE.y/2)
	
	get_node("../Player/RigidBody2D").position = $Position2D.position
	
# Called when the node enters the scene tree for the first time.
func _ready():
	#Setup bg_nodes
	node_array_width = int(LEVEL_SIZE.x / BG_NODE_SIZE)
	node_array_height = int(LEVEL_SIZE.y / BG_NODE_SIZE)
	
	for x in range(node_array_width): #HACK Consider ways to divide up background for non-1000x1000 sizes
		for y in range(node_array_height):
			var curr_index = (x * node_array_height) + y
			var node_position = Vector2(x * BG_NODE_SIZE, y * BG_NODE_SIZE)
			
			bg_node_array.append(bg_node.instance())
			call_deferred("add_child", bg_node_array[curr_index])
			bg_node_array[curr_index].position = node_position
			bg_node_array[curr_index].setup(BG_NODE_SIZE, BG_NODE_SPRITE_SIZE, bg_color)
			bg_node_array[curr_index].connect("update_complete", self, "_on_BGNode_update_complete")
	
	#Set up level walls
	var v_wall_collision = RectangleShape2D.new()
	var h_wall_collision = RectangleShape2D.new()
	
	v_wall_collision.extents = Vector2(wall_width, LEVEL_SIZE.x + (wall_width * 2))
	h_wall_collision.extents = Vector2(LEVEL_SIZE.y, wall_width)
	
	$Borders/LeftWall/CollisionShape2D.shape = v_wall_collision
	$Borders/RightWall/CollisionShape2D.shape = v_wall_collision
	$Borders/Ceiling/CollisionShape2D.shape = h_wall_collision
	$Borders/Floor/CollisionShape2D.shape = h_wall_collision
	
	$Borders/LeftWall.position = Vector2(-50, LEVEL_SIZE.y/2)
	$Borders/Ceiling.position = Vector2(LEVEL_SIZE.x/2, -50)
	$Borders/RightWall.position = Vector2(LEVEL_SIZE.x+50, LEVEL_SIZE.y/2)
	$Borders/Floor.position = Vector2(LEVEL_SIZE.x/2, LEVEL_SIZE.y+50)

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_released("paint"):
		if get_tree().paused == false:
#			if !percent_thread.is_active(): #TODO: Make this not consume so much time. 
#				var bg_array = []
#				for idx in range(bg_node_array.size()):
#					bg_array.append(Image.new())
#					bg_array[idx].copy_from(bg_node_array[idx].bg)
#				percent_thread.start(self, "percent_calc", bg_array)
				
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
				print("Nodes to Process is ", bg_nodes_to_process + 1)
				if curr_node < 0:
					print("Curr node < 0: ", curr_node)
				if curr_node >= bg_node_array.size():
					print("curr node > bg_node_array.size(): ", curr_node)
				print("	Processing node ", curr_node)
				
				bg_node_array[curr_node].start_sprite_update()
		
	if Input.is_action_just_pressed("save_background"): #TODO: Move save into a thread
		var curr_time = OS.get_datetime()
		var image_name = str(curr_time.day) + "_" + str(curr_time.month) + "_" + str(curr_time.year) + "_" + str(curr_time.hour) + "_" + str(curr_time.minute) + "_" + str(curr_time.second) + ".png"
#		get_full_bg_image().save_png(image_name) #NOTE: BG Expansion Point

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
		player_camera.limit_top = 0
		player_camera.limit_bottom = LEVEL_SIZE.y
		player_camera.limit_left = 0
		player_camera.limit_right = LEVEL_SIZE.x

func percent_calc(bg_image_array: Array):
	var count = 0.0
	var compressed_image = make_bg_image_from_array(bg_image_array)
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
		print("Nodes to Process is ", bg_nodes_to_process + 1)
		if curr_node < 0:
			print("Curr node < 0: ", curr_node)
		if curr_node >= bg_node_array.size():
			print("curr node > bg_node_array.size(): ", curr_node)
		print("	Processing node ", curr_node)
		
		bg_node_array[curr_node].start_sprite_update()
	
	if !percent_thread.is_active() && get_tree().paused == false:
		var bg_array = []
		for idx in range(bg_node_array.size()):
			bg_array.append(Image.new())
			bg_array[idx].copy_from(bg_node_array[idx].bg)
		percent_thread.start(self, "percent_calc", bg_array)

func _on_BGNode_update_complete(): #NOTE: BG Expansion Point
	bg_nodes_to_process -= 1
	if bg_nodes_to_process == -1:
		$TrailHandler.hide_trail()
		print("Node processing complete")
		print(" ")
		print($Cloud.get_viewport_rect())
	else:
		var curr_node = -1
		if bua_1_in_use == true:
			curr_node = bg_updated_array_1.pop_back()
		else:
			curr_node = bg_updated_array_2.pop_back()
		
		if curr_node < 0:
			print("Curr node < 0")
		if curr_node >= bg_node_array.size():
			print("curr node > bg_node_array.size()")
		print("	Processing node ", curr_node)
		bg_node_array[curr_node].start_sprite_update()

func make_bg_image_from_array(image_array: Array) -> Image:
	var my_bg = Image.new()
	my_bg.create(LEVEL_SIZE.x, LEVEL_SIZE.y, false, Image.FORMAT_RGB8) #FIXME: Must adapt if LEVEL_SIZE > 16000
	for idx in range(image_array.size()):
		my_bg.blit_rect(image_array[idx], Rect2(0, 0, BG_NODE_SIZE, BG_NODE_SIZE), bg_node_array[idx].position)
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