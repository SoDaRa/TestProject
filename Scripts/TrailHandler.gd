extends Node

#Trail
export var TRAIL_LENGTH = 300
var trail_array = []  				#Main Trail array
var trail_idx = TRAIL_LENGTH - 1 	#Keeps track of which main trail sprite is to be used next

export var BUFFER_LENGTH = 200
var buffer_1 = []
var buffer_2 = []
var buffer_idx = BUFFER_LENGTH - 1 	#Keeps track of which buffer trail sprite is to be used next
var buffer_1_in_use = false 		#Refers to if buffer_1 is currently displayed

signal main_empty

# Called when the node enters the scene tree for the first time.
func _ready():
	#Setup Trail
	for x in range(TRAIL_LENGTH):
		trail_array.append(Sprite.new())
		call_deferred("add_child", trail_array[x])
		trail_array[x].z_index = -x - BUFFER_LENGTH - 1
		trail_array[x].centered = false
	#Wrote Code here
	#Setup buffer
	for x in range(BUFFER_LENGTH):
		buffer_1.append(Sprite.new())
		buffer_2.append(Sprite.new())
		call_deferred("add_child", buffer_1[x])
		call_deferred("add_child", buffer_2[x])
		buffer_1[x].z_index = -x
		buffer_1[x].centered = false
		buffer_2[x].z_index = -x
		buffer_2[x].centered = false

func hide_trail():
	for x in range(TRAIL_LENGTH):
		if x < BUFFER_LENGTH:
			if buffer_1_in_use == true:	#If buffer 1 was being used, hide it and put buffer 2 beneath main trail
				buffer_1[x].position = Vector2(-1000,-1000)
				buffer_1[x].z_index = -x
				buffer_2[x].z_index = -TRAIL_LENGTH - BUFFER_LENGTH - x 
			else:
				buffer_2[x].position = Vector2(-1000,-1000)
				buffer_2[x].z_index = -x
				buffer_1[x].z_index = -TRAIL_LENGTH - BUFFER_LENGTH - x
		trail_array[x].position = Vector2(-1000,-1000)
	trail_idx = TRAIL_LENGTH - 1
	buffer_idx = BUFFER_LENGTH - 1
	if buffer_1_in_use == false:
		buffer_1_in_use = true
	else:
		buffer_1_in_use = false
	print("Clear")
	print(" ")

func draw_trail(mask: Image, mask_pos:Vector2, player_color:Color):
	var mask_info = {"pos": mask_pos, "image": mask, "color": player_color}
	if trail_idx != -1:
		_draw_main(mask_info)
	else:
		_draw_buffer(mask_info)
	
#Trail Code
func _draw_main(mask_info: Dictionary):
	#Putting at player position
	_update_sprite(trail_array[trail_idx], mask_info)
	trail_idx -= 1
	
	#Start setting the background sprites
	if trail_idx == -1:
		emit_signal("main_empty")

func _draw_buffer(mask_info: Dictionary):
	if buffer_1_in_use == false:
		_update_sprite(buffer_1[buffer_idx], mask_info)
	else:
		_update_sprite(buffer_2[buffer_idx], mask_info)
	buffer_idx -= 1
	
	if buffer_idx == -1:
		print("Buffer_idx is negative!!")

func _update_sprite(to_update: Sprite, mask_info: Dictionary):
	var player_color = Image.new()
	var player_image = Image.new()
	
	player_color.create(mask_info["image"].get_width(),mask_info["image"].get_height(), false, Image.FORMAT_RGBA8)
	player_image.create(mask_info["image"].get_width(),mask_info["image"].get_height(), false, Image.FORMAT_RGBA8)
	player_color.fill(mask_info["color"])
	player_image.fill(Color(mask_info["color"].r,mask_info["color"].g,mask_info["color"].b,0.0))
	
	player_image.blit_rect_mask(player_color, mask_info["image"], Rect2(0,0,mask_info["image"].get_width(), mask_info["image"].get_height()), Vector2(0,0))
	
	var sprite_texture = ImageTexture.new()
	sprite_texture.create_from_image(player_image)
	
	to_update.position = mask_info["pos"]
	to_update.texture = sprite_texture