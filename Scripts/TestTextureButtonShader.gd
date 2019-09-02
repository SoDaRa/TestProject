extends TextureButton

var color_sequence = [Color(1,0,0,1)]
var new_color_array = [Color(0,0,1,1), Color(0,1,0,1), Color(1,1,1,1), Color(0,0,0,1), Color(1,0,1,1), Color(1,1,0,1), Color(0,1,1,1), Color(0.8,0,1,1)]
onready var my_center = Vector2(texture_normal.get_width() / 2, texture_normal.get_height() / 2)
var curr_top_arc = 0
var arc_size = 360.0

# Called when the node enters the scene tree for the first time.
func _ready():
	material.set_shader_param("color0", color_sequence[0])
	material.set_shader_param("colors_in_use", color_sequence.size())
	rect_pivot_offset = my_center
	
	var my_bitmask = BitMap.new()
	var my_bit_image = load("res://Sprites/big_blank_ball.png")
	my_bitmask.create_from_image_alpha(my_bit_image.get_data())
	texture_click_mask = my_bitmask

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent):
	if event.is_action("ui_up") && Input.is_action_just_pressed("ui_up"):
		if new_color_array.empty():
			return
			
		color_sequence.append(new_color_array.pop_front())
		match(color_sequence.size()):
			2: material.set_shader_param("color1", color_sequence[1])
			3: material.set_shader_param("color2", color_sequence[2])
			4: material.set_shader_param("color3", color_sequence[3])
			5: material.set_shader_param("color4", color_sequence[4])
			6: material.set_shader_param("color5", color_sequence[5])
			7: material.set_shader_param("color6", color_sequence[6])
			8: material.set_shader_param("color7", color_sequence[7])
			9: material.set_shader_param("color8", color_sequence[8])
			_: return
		material.set_shader_param("colors_in_use", color_sequence.size())
		self.rect_rotation = -(90 - ((360.0 / color_sequence.size()) / 2))
		curr_top_arc = 0
		arc_size = 360.0 / color_sequence.size()
	if event.is_action("ui_down") && Input.is_action_just_pressed("ui_down"):
		if color_sequence.size() == 1:
			return
		new_color_array.append(color_sequence.pop_back())
		material.set_shader_param("colors_in_use", color_sequence.size())
		self.rect_rotation = -(90 - ((360.0 / color_sequence.size()) / 2))
		curr_top_arc = 0
		arc_size = 360.0 / color_sequence.size()

	if event.is_action("ui_left") && Input.is_action_just_pressed("ui_left") && !$Tween.is_active():
		$Tween.interpolate_property(self, "rect_rotation", null, rect_rotation - arc_size, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		curr_top_arc -= 1
		curr_top_arc = wrapi(curr_top_arc, 0, color_sequence.size())
	if event.is_action("ui_right") && Input.is_action_just_pressed("ui_right") && !$Tween.is_active():
		$Tween.interpolate_property(self, "rect_rotation", null, rect_rotation + arc_size, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		curr_top_arc += 1
		curr_top_arc = wrapi(curr_top_arc, 0, color_sequence.size())

func pressed():
	if !$Tween.is_active():
		var mouse_pos = get_local_mouse_position()
		var mouse_angle = rad2deg(mouse_pos.angle_to_point(my_center))
		if mouse_angle < 0:
			mouse_angle += 360.0
		mouse_angle = 360.0 - mouse_angle #This is mostly to bring it in line with how the shader handles it.
		var mouse_region = mouse_angle / arc_size
		if int(floor(mouse_region)) != curr_top_arc:
			var rotate_amount = arc_size * (int(floor(mouse_region)) - curr_top_arc)
			rotate_amount = wrapf(rotate_amount, -180, 180)
			$Tween.interpolate_property(self, "rect_rotation", null, rect_rotation + rotate_amount, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			curr_top_arc = int(floor(mouse_region))