extends Node2D


var bg_color: Color			#Default Background Color
var BG_SIZE: Vector2 		#Background size
var BG_SPRITE_SIZE: Vector2	#Sprite size

var bg: Image				#Image for background
var MY_FORMAT = Image.FORMAT_RGBA8
var bg_texture_array = [] 	#Array of Textures to apply crops of the bg image onto
var bg_sprite_array = [] 	#Array of sprites to apply image array onto

var array_width: int		#How many columns there are
var array_height: int	#How many rows there are
var sprite_rect_array = [] #Holds the rect2 of each sprite

var paint_log = []			#Which sprites have been painted on since starting the last update
var sprite_update_list = []	#Which sprites to update during the update
var sprites_to_update = -1	#Tracks how many sprites need to be updated in an updating cycle

var updating = false setget , is_updating

var scale_by = Vector2(1.0,1.0)

var index_id = -1 #Used to signal where it is in the level's bg_node_array

#signal update_start(id)
signal update_complete(bg_copy, id)
	
# warning-ignore:unused_argument
func _process(delta):
	if sprites_to_update > -1:
		update_background()

func setup(image_size:Vector2, sprite_size:Vector2, background_color:Color, scale_ = Vector2(1.0,1.0)):
	BG_SIZE = image_size
	BG_SPRITE_SIZE = sprite_size
	bg_color = background_color
	scale_by = scale_
	
	if bg == null:
		bg = Image.new()
		bg.create(int(BG_SIZE.x), int(BG_SIZE.y), false, MY_FORMAT)
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
			bg_texture_array[curr_index].create_from_image(bg.get_rect(curr_sprite_rect), 5) #5 prevents texture repeating
			
			bg_sprite_array.append(Sprite.new())
			call_deferred("add_child", bg_sprite_array[curr_index])
			bg_sprite_array[curr_index].position = curr_sprite_position
			bg_sprite_array[curr_index].texture = bg_texture_array[curr_index]
			bg_sprite_array[curr_index].z_index = -2000
			bg_sprite_array[curr_index].centered = false
			
			sprite_rect_array.append(curr_sprite_rect)

func start_sprite_update():
	if !updating:
		sprites_to_update = paint_log.size() - 1
		if sprites_to_update == -1:
			print("Cancel Update: No sprites to process")
			end_update() #Must signal that the update is complete
			return
		while paint_log.size() > 0:
			sprite_update_list.push_back(paint_log.pop_front())
#		emit_signal("update_start", index_id)
#		print("		Images to Process is ", sprites_to_update + 1)

func update_background():
	var tile = -1
	while(tile < 0):	#Get the index to work on
		if sprite_update_list.empty():	#If there's no more nodes to update, then break the loop
			sprites_to_update = 0
			break
		tile = sprite_update_list.pop_back()
	assert(tile != null)
	assert(tile > -1)
	assert(tile < bg_sprite_array.size())
#	print("Printing tile ", tile)
	bg_texture_array[tile].set_data(bg.get_rect(sprite_rect_array[tile]))
	sprites_to_update -= 1
	
	if sprites_to_update == -1:
		end_update()

func end_update():
	var my_bg_copy = Image.new()
	my_bg_copy.copy_from(bg)
	if scale_by != Vector2(1.0,1.0):
		var width = int(bg.get_width() * scale_by.x)
		var height = int(bg.get_height() * scale_by.y)
		my_bg_copy.resize(width, height, Image.INTERPOLATE_NEAREST)
	emit_signal("update_complete", my_bg_copy, index_id)
	updating = false

#Assumes mask_pos is in parent's local coordiates
func paint_background(mask:Image, mask_pos:Vector2):
	var local_mask_pos = mask_pos - self.position
#	print(local_mask_pos)
	bg.blend_rect(mask, mask.get_used_rect(), local_mask_pos)
	var painted_sprites = check_painted(local_mask_pos, mask.get_width(), mask.get_height())
	for sprite in painted_sprites:
		if paint_log.find(sprite) == -1:
			paint_log.push_back(sprite)
	
#Rudimentary "collision" check #NOTE: This will stop working if the mask's size, aka Player/PlayerMask/Viewport, is > BG_SPRITE_SIZE!! 
#More certain way to do this would be to use sprite_rect_array.clip but worried it'd cause lag if done too often.
func check_painted(mask_pos:Vector2, width:float, height:float) -> Array:
	var sprites_painted = []
	#Get left, top, right and bottom
	var left = int(floor(mask_pos.x / BG_SPRITE_SIZE.x))
	var top = int(floor(mask_pos.y / BG_SPRITE_SIZE.y))
	var right = int(floor((mask_pos.x + width) / BG_SPRITE_SIZE.x))
	var bottom = int(floor((mask_pos.y + height) / BG_SPRITE_SIZE.y))
	
	var left_bad = left < 0 || left >= array_width
	var top_bad = top < 0 || top >= array_height
	var right_bad = right < 0 || right >= array_width
	var bottom_bad = bottom < 0 || bottom >= array_width
	#Figure out which sprites each of the four corners are in
	var topleft = -1
	var topright = -1
	var bottomleft = -1
	var bottomright = -1
	if !top_bad && !left_bad:
		topleft = left * array_height + top
	if !top_bad && !right_bad:
		topright = right * array_height + top
	if !bottom_bad && !left_bad:
		bottomleft = left * array_height + bottom
	if !bottom_bad && !right_bad:
		bottomright = right * array_height + bottom
	
	#These are just to avoid redundant find calls if two corners are in the same section or one is out of bounds
	var skip_topleft = left_bad || top_bad || topleft < 0 || topleft >= bg_sprite_array.size()
	var skip_topright = topleft == topright || right_bad || top_bad || topright < 0 || topright >= bg_sprite_array.size()
	var skip_bottomleft = topleft == bottomleft || left_bad || bottom_bad || bottomleft < 0 || bottomleft >= bg_sprite_array.size()
	var skip_bottomright = bottomright == topright || bottomright == bottomleft || right_bad || bottom_bad || \
							bottomright < 0 || bottomright >= bg_sprite_array.size()
	
	if !skip_topleft:
		sprites_painted.push_back(topleft)
	if !skip_topright:
		sprites_painted.push_back(topright)
	if !skip_bottomleft:
		sprites_painted.push_back(bottomleft)
	if !skip_bottomright:
		sprites_painted.push_back(bottomright)
	return sprites_painted

func is_updating() -> bool:
	return updating