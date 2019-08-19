extends Node2D


var bg_color: Color			#Default Background Color
var BG_SIZE: Vector2 		#Background size
var BG_SPRITE_SIZE: Vector2	#Sprite size

var bg: Image				#Image for background
var bg_texture_array = [] 	#Array of Textures to apply crops of the bg image onto
var bg_sprite_array = [] 	#Array of sprites to apply image array onto

var array_width		#How many columns there are
var array_height	#How many rows there are
var sprite_rect_array = [] #Holds the rect2 of each sprite

#These arrays hold which sprites have been painted on and are used to determine which ones to update.
#They swap duties so one can be used to update, the other is recording updates so it doesn't get stuck drawing one 
var paint_array_1 = []
var paint_array_2 = []
var paint_1_in_use = false #Refers to which one is being used to update the background.
var images_to_process = -1 #Tracks how many sprites need to be updated in an updating cycle

var updating = false
#var draw_frame = true
#var count = 0

var scale_by = Vector2(1.0,1.0)

var index_id = -1 #Used to signal where it is in the level's bg_node_array

#signal update_start(id)
signal update_complete(bg_copy, id)
	
# warning-ignore:unused_argument
func _process(delta):
	if images_to_process > -1:
		_update_background()

func setup(image_size:Vector2, sprite_size:Vector2, background_color:Color, scale_: Vector2):
	BG_SIZE = image_size
	BG_SPRITE_SIZE = sprite_size
	bg_color = background_color
	scale_by = scale_
#	$VisibilityNotifier2D.rect = Rect2(self.position, Vector2(BG_SIZE.x, BG_SIZE.y))
	
	if bg == null:
		bg = Image.new()
		bg.create(int(BG_SIZE.x), int(BG_SIZE.y), false, Image.FORMAT_RGB8)
		bg.fill(bg_color)
		
	if BG_SPRITE_SIZE.x > BG_SIZE.x:
		BG_SPRITE_SIZE.x = BG_SIZE.x
	if BG_SPRITE_SIZE.y > BG_SIZE.y:
		BG_SPRITE_SIZE.y = BG_SIZE.y
#	if BG_SPRITE_SIZE != sprite_size:
#		print("	Sprite size is ", BG_SPRITE_SIZE)
	
	array_width = int(ceil(bg.get_width() / BG_SPRITE_SIZE.x))
	array_height = int(ceil(bg.get_height() / BG_SPRITE_SIZE.y))
	
	for x in range(array_width):
		for y in range(array_height):
			var curr_index = (x * array_height) + y
			var curr_sprite_position = Vector2(x * BG_SPRITE_SIZE.x, y * BG_SPRITE_SIZE.y)
			var curr_sprite_size = BG_SPRITE_SIZE
			
			if curr_sprite_position.x + BG_SPRITE_SIZE.x > BG_SIZE.x:
				curr_sprite_size.x = BG_SIZE.x - curr_sprite_position.x
			if curr_sprite_position.y + BG_SPRITE_SIZE.y > BG_SIZE.y:
				curr_sprite_size.y = BG_SIZE.y - curr_sprite_position.y
			
			var curr_sprite_rect = Rect2(curr_sprite_position, curr_sprite_size)
			
			bg_texture_array.append(ImageTexture.new())
			bg_texture_array[curr_index].create_from_image(bg.get_rect(curr_sprite_rect), 5) #5 is to set the flags so the texture isn't repeating
			
			bg_sprite_array.append(Sprite.new())
			call_deferred("add_child", bg_sprite_array[curr_index])
			bg_sprite_array[curr_index].position = curr_sprite_position
			bg_sprite_array[curr_index].texture = bg_texture_array[curr_index]
			bg_sprite_array[curr_index].z_index = -2000
			bg_sprite_array[curr_index].centered = false
			
			sprite_rect_array.append(curr_sprite_rect)

func start_sprite_update():
	if !updating:
		if paint_1_in_use == false:
			images_to_process = paint_array_1.size() - 1
			paint_1_in_use = true
			updating = true
			
		else:
			images_to_process = paint_array_2.size() - 1
			paint_1_in_use = false
			updating = true
#		emit_signal("update_start", index_id)
#		print("		Images to Process is ", images_to_process + 1)
		if images_to_process == -1:
			var my_bg_copy = Image.new()
			my_bg_copy.copy_from(bg)
			if scale_by != Vector2(1.0,1.0):
				var width = bg.get_width() * scale_by.x
				var height = bg.get_height() * scale_by.y
				my_bg_copy.resize(width, height, Image.INTERPOLATE_NEAREST)
			emit_signal("update_complete", my_bg_copy, index_id)
			updating = false

func is_updating() -> bool:
	return updating

func _update_background():
	var tile = -1
	while(tile < 0):
		if paint_1_in_use == true:
			if paint_array_1.empty():
				images_to_process = 0
				break
			tile = paint_array_1.pop_back()
		else:
			if paint_array_2.empty():
				images_to_process = 0
				break
			tile = paint_array_2.pop_back()
	if tile <= -1:
		print("		BG tile <= -1!! ", tile)
	if tile >= bg_sprite_array.size():
		tile = 0
		print("		BG tile > bg_sprite_array.size()!!! ", tile)
#	print("Printing tile ", tile)
	bg_texture_array[tile].set_data(bg.get_rect(sprite_rect_array[tile]))
	
	images_to_process -= 1
	
	#When done updating the background, reset the trail_array
	if images_to_process == -1:
		var my_bg_copy = Image.new()
		my_bg_copy.copy_from(bg)
		if scale_by != Vector2(1.0,1.0):
			var width = int(bg.get_width() * scale_by.x)
			var height = int(bg.get_height() * scale_by.y)
			my_bg_copy.resize(width, height, Image.INTERPOLATE_NEAREST)
		emit_signal("update_complete", my_bg_copy, index_id)
		updating = false

#Assumes mask_pos is in global coordiates
func paint_background(mask:Image, mask_pos:Vector2, curr_color:Color):
	var local_mask_pos = mask_pos - self.position
	var player_color = Image.new()
	player_color.create(mask.get_width(),mask.get_height(), false, Image.FORMAT_RGB8)
	player_color.fill(curr_color)
	bg.blend_rect_mask(player_color, mask, Rect2(0,0,mask.get_width(), mask.get_height()), local_mask_pos)
	
	check_painted(local_mask_pos, mask.get_width(), mask.get_height())
	
#Rudimentary "collision" check #NOTE: This will stop working if the mask's size > BG_SPRITE_SIZE!!
#More certain way to do this would be to use sprite_rect_array.clip but worried it'd cause lag if done too often.
func check_painted(mask_pos:Vector2, width:float, height:float):
	#Get left, top, right and bottom
	var left = int(floor(mask_pos.x / BG_SPRITE_SIZE.x))
	var top = int(floor(mask_pos.y / BG_SPRITE_SIZE.y))
	var right = int(floor((mask_pos.x + width) / BG_SPRITE_SIZE.x))
	var bottom = int(floor((mask_pos.y + height) / BG_SPRITE_SIZE.y))
	
	#Figure out which sprites each of the four corners are in
	var topleft = int(left * array_height + top)
	var topright = int(right * array_height + top)
	var bottomleft = int(left * array_height + bottom)
	var bottomright = int(right * array_height + bottom)
	
	#These are just to avoid redundant find calls if two corners are in the same section or one is out of bounds
	var skip_topleft = left < 0 || top < 0 || topleft < 0 || topleft >= bg_sprite_array.size()
	var skip_topright = topleft == topright || right >= array_width || top < 0 || topright < 0 || topright >= bg_sprite_array.size()
	var skip_bottomleft = topleft == bottomleft || bottom >= array_height || left < 0 || bottomleft < 0 || bottomleft >= bg_sprite_array.size()
	var skip_bottomright = (bottomright == topright) || (bottomright == bottomleft) || right >= array_width || bottom >= array_height 
	skip_bottomright = skip_bottomright || bottomright < 0 || bottomright >= bg_sprite_array.size()
	
	if paint_1_in_use == false:
		if !skip_topleft:
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
	else:
		if !skip_topleft:
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
