extends Node2D

#Default Background Color
var bg_color = Color(0.0,0.0,0.0,1.0)

var bg = Image.new() #Image for background
var bg_array = [] #Image Array for backgrounds
var bg_texture_array = [] #Array of Textures to apply crops of the bg image onto
var bg_sprite_array = [] #Array of sprites to apply image array onto
var images_to_process = -1
export var BG_SIZE = 4000 #NOTE: Must be wholly divisible by BG_CROP_DIMEN
var BG_CROP_DIMEN = 500 # BG sprite dimensions. For now x and y length will be equal
var array_width
var array_height

var sprite_rect_array = []
var paint_array_1 = []
var paint_array_2 = []
var paint_1_in_use = false #Refers to if it should write to painted_1 or 2

var updating = false

signal update_complete

# Called when the node enters the scene tree for the first time.
func _ready():
	bg.create(BG_SIZE, BG_SIZE, false, Image.FORMAT_RGB8)
	bg.fill(bg_color)
	
	array_width = bg.get_width() / BG_CROP_DIMEN
	array_height = bg.get_height() / BG_CROP_DIMEN
	
	for x in range(array_width): #HACK Consider ways to divide up background for non-1000x1000 sizes
		for y in range(array_height):
			var curr_index = (x * array_height) + y
			var sprite_rect = Rect2(Vector2(x * BG_CROP_DIMEN, y * BG_CROP_DIMEN), Vector2(BG_CROP_DIMEN, BG_CROP_DIMEN))
			bg_array.append(bg.get_rect(sprite_rect))
			
			bg_texture_array.append(ImageTexture.new())
			bg_texture_array[curr_index].create_from_image(bg_array[curr_index], 5) #5 is to set the flags so the texture isn't repeating
			
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
		_update_background()
		
func start_update_background():
	if !updating:
		if paint_1_in_use == false:
			images_to_process = paint_array_1.size() - 1
			paint_1_in_use = true
			print("Images to Process is ", images_to_process + 1)
		else:
			images_to_process = paint_array_2.size() - 1
			paint_1_in_use = false
			print("Images to Process is ", images_to_process + 1)

func is_updating() -> bool:
	return updating

func _update_background():
	var tile = -1
	if paint_1_in_use == true:
		tile = paint_array_1.pop_back()
	else:
		tile = paint_array_2.pop_back()
	if tile <= -1:
		print("BG tile <= -1!!")
	if tile >= bg_array.size():
		tile = 0
		print("BG tile > bg_array.size()!!!")
	
	bg_array[tile] = bg.get_rect(sprite_rect_array[tile])
	bg_texture_array[tile].set_data(bg_array[tile])
	
	images_to_process -= 1
	
	#When done updating the background, reset the trail_array
	if images_to_process == -1:
		emit_signal("update_complete")
		updating = false
		
func paint_background(mask:Image, mask_pos:Vector2, curr_color:Color):
	var player_color = Image.new()
	player_color.create(mask.get_width(),mask.get_height(), false, Image.FORMAT_RGB8)
	player_color.fill(curr_color)
	bg.blend_rect_mask(player_color, mask, Rect2(0,0,mask.get_width(), mask.get_height()), mask_pos)
	
	check_painted(mask_pos, mask.get_width(), mask.get_height())
	
#Rudimentary "collision" check #NOTE: This will stop working if the mask's size > BG_CROP_DIMEN!!
#More certain way to do this would be to use sprite_rect_array.clip but worried it'd cause lag if done too often.
func check_painted(mask_pos:Vector2, width:float, height:float):
	#Get left, top, right and bottom
	var left = int(floor(mask_pos.x / BG_CROP_DIMEN))
	var top = int(floor(mask_pos.y / BG_CROP_DIMEN))
	var right = int(floor((mask_pos.x + width) / BG_CROP_DIMEN))
	var bottom = int(floor((mask_pos.y + height) / BG_CROP_DIMEN))
	
	#Figure out which sprites each of the four corners are in
	var topleft = int(left * array_height + top)
	var topright = int(right * array_height + top)
	var bottomleft = int(left * array_height + bottom)
	var bottomright = int(right * array_height + bottom)
	
	#These are just to avoid redundant find calls if two corners are in the same section or one is out of bounds
	var skip_topleft = left < 0 || top < 0 || topleft < 0
	var skip_topright = topleft == topright || right > array_width || top < 0 || topright >= bg_array.size()
	var skip_bottomleft = topleft == bottomleft || bottom > array_height || left < 0 || bottomleft >= bg_array.size()
	var skip_bottomright = (bottomright == topright) || (bottomright == bottomleft) || right > array_width || bottom > array_height 
	skip_bottomright = skip_bottomright || bottomright >= bg_array.size()
	
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