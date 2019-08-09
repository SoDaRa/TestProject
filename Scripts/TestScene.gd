extends Node

export var color_sequence = [Color(1.0, 1.0, 1.0, 1.0), Color(0.0, 1.0, 1.0, 1.0), Color(1.0, 0.0, 1.0, 1.0), Color(1.0, 1.0, 0.0, 1.0)]

var bg = Image.new()
var color1 = Image.new()
var color2 = Image.new()
var color3 = Image.new()
var clear = Image.new()
var bgTexture = ImageTexture.new()
var mask 
# Called when the node enters the scene tree for the first time.
func _ready():
	bg.create(1024, 600, false, Image.FORMAT_RGBA8)
	color1.create(75,75, false, Image.FORMAT_RGBA8)
	color2.create(75,75, false, Image.FORMAT_RGBA8)
	color3.create(75,50, false, Image.FORMAT_RGBA8)
	clear.create(75,75, false, Image.FORMAT_RGBA8)
	bg.fill(Color(0.99,1.0,1.0,1.0))
	color1.fill(color_sequence[1])
	color2.fill(color_sequence[2])
	color3.fill(color_sequence[3])
	clear.fill(color_sequence[0])
	
	bgTexture.create_from_image(bg)
	$Background.set_texture(bgTexture)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _process(delta):
	if Input.is_action_pressed("left_click"):
		mask = $Player/PlayerCopy.get_texture().get_data()
		print(mask.get_size())
		var play_pos = $Player.position - Vector2(25,25)
		bg.blend_rect_mask(clear, mask, Rect2(0,0,75,75), play_pos)
		if $Player.curr_color == 1:
			bg.blit_rect_mask(color1, mask, Rect2(0,0,75,75), play_pos)
		elif $Player.curr_color == 2:
			bg.blit_rect_mask(color2, mask, Rect2(0,0,75,75), play_pos)
		elif $Player.curr_color == 3:
			bg.blit_rect_mask(color3, mask, Rect2(0,0,75,75), play_pos)
		bgTexture.create_from_image(bg)
		$Background.set_texture(bgTexture)
	
#	if Input.is_action_just_pressed("right_click"):
#		var imgArray = ball.get_data()
#		var imgString = imgArray.get_string_from_ascii()
#		print(imgString)
#		print(imgArray.size())
	
