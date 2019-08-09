extends Node

#Colors for shapes
export var color_sequence = [Color(1.0, 1.0, 1.0, 1.0), Color(0.0, 1.0, 1.0, 1.0), Color(1.0, 0.0, 1.0, 1.0), Color(1.0, 1.0, 0.0, 1.0)]

#Default Background Color
var bg_color = Color(0.0,0.0,0.0,1.0)


var bg = Image.new() #Image for background
#Color splotches for coloring
var color1 = Image.new()
var color2 = Image.new()
var color3 = Image.new()
var clear = Image.new() #Should eventually rename this one Color0
var bgTexture = ImageTexture.new()

#Sprite for changing PlayerCopy
var box_sprite = preload("res://box.png")
var ball_sprite = preload("res://ball.png")
enum {BOX_MODE, BALL_MODE}
var current_shape

#Size Changing
var MAX_SIZE = 80
var MIN_SIZE = 22
var curr_size = 75

var base_bg #Holds the original image date to compare how much has changed
var percent_thread = Thread.new() #Thread for processing percent

func _percent_calc(bg_to_check):
	var count = 0.0
	for x in range(bg_to_check.size()):
		if base_bg[x] != bg_to_check[x]:
			count += 1.0

	var percent = count / base_bg.size()
	call_deferred("_percent_calc_done")
	return percent

func _percent_calc_done():
	var percentage = percent_thread.wait_to_finish()
	print(percentage)

# Called when the node enters the scene tree for the first time.
func _ready():
	bg.create(1024, 600, false, Image.FORMAT_RGB8)
	color1.create(75,75, false, Image.FORMAT_RGB8)
	color2.create(75,75, false, Image.FORMAT_RGB8)
	color3.create(75,75, false, Image.FORMAT_RGB8)
	clear.create(75,75, false, Image.FORMAT_RGB8)
	bg.fill(bg_color)
	color1.fill(color_sequence[1])
	color2.fill(color_sequence[2])
	color3.fill(color_sequence[3])
	clear.fill(color_sequence[0])

	bgTexture.create_from_image(bg)
	$Background.set_texture(bgTexture)

	base_bg = bg.get_data()

	$VC/Viewport/PMSprite.texture = box_sprite
	current_shape = BOX_MODE
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _process(delta):
	if Input.is_action_pressed("paint"):
		if $Player.current_shape != BALL_MODE:
			$VC/Viewport/PMSprite.rotation_degrees = $Player.rotation_degrees
			yield(get_tree(), "idle_frame")
		var mask = $VC/Viewport.get_texture().get_data()
		var play_pos = $Player.position - Vector2(35,37)
		if $Player.curr_color == 0:
			bg.blend_rect_mask(clear, mask, Rect2(0,0,75,75), play_pos)
		elif $Player.curr_color == 1:
			bg.blit_rect_mask(color1, mask, Rect2(0,0,75,75), play_pos)
		elif $Player.curr_color == 2:
			bg.blit_rect_mask(color2, mask, Rect2(0,0,75,75), play_pos)
		elif $Player.curr_color == 3:
			bg.blit_rect_mask(color3, mask, Rect2(0,0,75,75), play_pos)
		bgTexture.create_from_image(bg)
		$Background.set_texture(bgTexture)

	if Input.is_action_just_released("paint") && !percent_thread.is_active():
		var bg_bytes = bg.get_data()
		percent_thread.start(self, "_percent_calc", bg_bytes)


	if Input.is_action_just_pressed("swap_shape"):
		if current_shape == BOX_MODE:
			$VC/Viewport/PMSprite.texture = ball_sprite
			current_shape = BALL_MODE
		elif current_shape == BALL_MODE:
			$VC/Viewport/PMSprite.texture = box_sprite
			current_shape = BOX_MODE
			
	#Size Swapping
	if Input.is_action_pressed("decrease_size") && curr_size != MIN_SIZE:
		$Player/CollisionShape2D.scale.x -= 1 * delta
		if $Player/CollisionShape2D.scale.x > 0.1: #Ensure the collision shape doesn't get so small it causes problems
			$Player/CollisionShape2D.scale.y -= 1 * delta
			$Player/Sprite.scale.x -= 1 * delta
			$Player/Sprite.scale.y -= 1 * delta
			$VC/Viewport/PMSprite.scale.x -= 1 * delta
			$VC/Viewport/PMSprite.scale.y -= 1 * delta
			curr_size -= 1
		else:
			$Player/CollisionShape2D.scale.x += 1 * delta
	
	if Input.is_action_pressed("increase_size") && curr_size != MAX_SIZE:
		$Player/CollisionShape2D.scale.x += 1 * delta
		$Player/CollisionShape2D.scale.y += 1 * delta
		$Player/Sprite.scale.x += 1 * delta
		$Player/Sprite.scale.y += 1 * delta
		$VC/Viewport/PMSprite.scale.x += 1 * delta
		$VC/Viewport/PMSprite.scale.y += 1 * delta
		curr_size += 1