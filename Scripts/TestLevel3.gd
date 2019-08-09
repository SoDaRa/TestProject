extends Node

var percent_thread = Thread.new() #Thread for processing percent
var percent_colored = 0.0

onready var bg_color = $BG1.bg_color
var BG_SIZE
#TODO: Make level generate BG Nodes with BGHandler script for larger levels
var player_camera

var zoom_camera_position: Vector2
var zoom_camera_scale = Vector2(6.8,6.8)

var wall_width = 50

func _on_Root_ready(): #TODO: Will need to fix this when loading levels
	player_camera = get_node("../Player/RigidBody2D/Camera2D")
	player_camera.limit_top = 0
	player_camera.limit_bottom = BG_SIZE.y
	player_camera.limit_left = 0
	player_camera.limit_right = BG_SIZE.x
	zoom_camera_position = Vector2(BG_SIZE.x/2, BG_SIZE.y/2)
	
	#Set up level walls
	var v_wall_collision = RectangleShape2D.new()
	var h_wall_collision = RectangleShape2D.new()
	
	v_wall_collision.extents = Vector2(wall_width, BG_SIZE.x + (wall_width * 2))
	h_wall_collision.extents = Vector2(BG_SIZE.y, wall_width)
	
	$Borders/LeftWall/CollisionShape2D.shape = v_wall_collision
	$Borders/RightWall/CollisionShape2D.shape = v_wall_collision
	$Borders/Ceiling/CollisionShape2D.shape = h_wall_collision
	$Borders/Floor/CollisionShape2D.shape = h_wall_collision
	
	$Borders/LeftWall.position = Vector2(-50, BG_SIZE.y/2)
	$Borders/Ceiling.position = Vector2(BG_SIZE.x/2, -50)
	$Borders/RightWall.position = Vector2(BG_SIZE.x+50, BG_SIZE.y/2)
	$Borders/Floor.position = Vector2(BG_SIZE.x/2, BG_SIZE.y+50)
	
	get_node("../Player/RigidBody2D").position = $Position2D.position
	
# Called when the node enters the scene tree for the first time.
func _ready():
	BG_SIZE = Vector2($BG1.BG_SIZE, $BG1.BG_SIZE) #NOTE: BG Expansion Point

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_released("paint"):
		if get_tree().paused == false:
			if !percent_thread.is_active():
				percent_thread.start(self, "percent_calc", $BG1.bg) #NOTE: BG Expansion Point
			if !$BG1.is_updating():
				$BG1.start_update_background() #NOTE: BG Expansion Point
		
	if Input.is_action_just_pressed("save_background"):
		var curr_time = OS.get_datetime()
		var image_name = str(curr_time.day) + "_" + str(curr_time.month) + "_" + str(curr_time.year) + "_" + str(curr_time.hour) + "_" + str(curr_time.minute) + "_" + str(curr_time.second) + ".png"
		$BG1.bg.save_png(image_name) #NOTE: BG Expansion Point

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
		player_camera.limit_bottom = BG_SIZE.y
		player_camera.limit_left = 0
		player_camera.limit_right = BG_SIZE.x

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
	if percentage > percent_colored:
		percent_colored = percentage

func _on_Player_paint(mask: Image, mask_pos: Vector2, player_color: Color):
	$BG1.paint_background(mask, mask_pos, player_color) #NOTE: BG Expansion Point
	$TrailHandler.draw_trail(mask, mask_pos, player_color)

func _on_TrailHandler_main_empty():
	$BG1.start_update_background() #NOTE: BG Expansion Point
	if !percent_thread.is_active() && get_tree().paused == false:
		percent_thread.start(self, "percent_calc", $BG1.bg)

func _on_BG1_update_complete(): #NOTE: BG Expansion Point
	$TrailHandler.hide_trail()