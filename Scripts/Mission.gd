extends Node2D
#TODO: Find way to have this and Level extend the same class
var percent_thread = Thread.new() 			#Thread for processing percent
var percent_colored = 0.0

var bg_color = Color(0,0,0,0)
var bg_copy: Image

#export var mission_bg = preload("res://Sprites/MissionBG.png") #TODO: Have this be editable
var MISSION_SIZE: Vector2		#Total size of the level and background
var BG_NODE_SIZE: Vector2 		#Size of an individual background node's image #TODO: Remove this if I'm not going to use it
var BG_SPRITE_SIZE = 250 		#Size of the sprites that make up the background node's. See BGHandler.gd for more



var bg_node = preload("res://Scenes/BGNode.tscn")
var my_bg_node

const wall_width = 50	#How thick the borders of the level are.

signal update_started
signal update_completed
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func mission_start(mission_bg : String) -> Rect2:
	var m_texture = load(mission_bg)
	MISSION_SIZE = Vector2(m_texture.get_data().get_width(), m_texture.get_data().get_height())
	BG_NODE_SIZE = MISSION_SIZE
	var sprite_size_vector = Vector2(BG_SPRITE_SIZE, BG_SPRITE_SIZE)
	#Setup bg_nodes
	my_bg_node = bg_node.instance()
	call_deferred("add_child", my_bg_node)
	my_bg_node.position = Vector2(0,0)
	my_bg_node.index_id = 0
	my_bg_node.setup(MISSION_SIZE, sprite_size_vector, bg_color)
	my_bg_node.connect("update_complete", self, "_on_BGNode_update_complete")
	$Overlay.texture = m_texture
	
	#Set up mission walls
	var v_wall_collision = RectangleShape2D.new()
	var h_wall_collision = RectangleShape2D.new()
	
	v_wall_collision.extents = Vector2(wall_width, (MISSION_SIZE.y + (wall_width * 4)) / 2)
	h_wall_collision.extents = Vector2(MISSION_SIZE.x / 2, wall_width)
	
	$Borders/LeftWall/CollisionShape2D.shape = v_wall_collision
	$Borders/RightWall/CollisionShape2D.shape = v_wall_collision
	$Borders/Ceiling/CollisionShape2D.shape = h_wall_collision
	$Borders/Floor/CollisionShape2D.shape = h_wall_collision

	$Borders/LeftWall.position = Vector2(-wall_width, MISSION_SIZE.y/2)
	$Borders/Ceiling.position = Vector2(MISSION_SIZE.x/2, -wall_width)
	$Borders/RightWall.position = Vector2(MISSION_SIZE.x+wall_width, MISSION_SIZE.y/2)
	$Borders/Floor.position = Vector2(MISSION_SIZE.x/2, MISSION_SIZE.y+wall_width)
	
	var my_rect = Rect2(position, MISSION_SIZE)
	return my_rect

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_released("paint"):
		if get_tree().paused == false:
			start_update()
#			print("Background Update: Release")

# warning-ignore:unused_argument
func percent_calc(my_img: Image):
	var count = 0
	var compressed_image = Image.new()
	compressed_image.copy_from(my_img)
	compressed_image.resize(100,100, Image.INTERPOLATE_NEAREST)
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
	print("Mission: ", percentage, "%")
	if percentage > percent_colored:
		percent_colored = percentage

func _on_Player_paint(mask: Image, mask_pos: Vector2):
	var new_pos = mask_pos - self.position
	my_bg_node.paint_background(mask, new_pos)


func _on_Trail_main_empty():
	start_update()
#		print("Background Update: Trail")


func _on_BGNode_update_complete(bg_image:Image, node_idx: int):
	bg_copy = bg_image
#	print("Node Ending Update: ", node_idx)
	end_update()

func start_update():
	my_bg_node.start_sprite_update()
	emit_signal("update_started")
	
func end_update():
	if !percent_thread.is_active() && get_tree().paused == false: 
		var thread_copy = Image.new()
		thread_copy.copy_from(bg_copy)
		percent_thread.start(self, "percent_calc", thread_copy) #BUG: Percent calculation not returning. Why?
	emit_signal("update_completed")
#	print("Node processing complete")
#	print(" ")

func get_result() -> Image:
	return bg_copy

#func _private_set(value = null):
#	print("Cannot set private variable")
#	return value
#
#func _private_get(value = null):
#	print("Cannot get private variable")
#	return value