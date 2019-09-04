extends TextureButton

var color_array = []
onready var my_center = Vector2(texture_normal.get_width() / 2, texture_normal.get_height() / 2)
var curr_top_slice = 0 setget set_top_slice
var curr_player_slice = 0
var slice_size = 360.0
var mouse_click = false

var CCPPopup = preload("res://Scenes/CCPPopup.tscn")
var picker_array = []

#signal top_changed(new_color)
signal color_changed(new_color, position)

# Called when the node enters the scene tree for the first time.
func _ready():
	var my_bitmask = BitMap.new()
	var my_bit_image = load("res://Sprites/big_blank_ball.png")
	my_bitmask.create_from_image_alpha(my_bit_image.get_data())
	texture_click_mask = my_bitmask

	update_shader()
	rect_pivot_offset = my_center
	
	set_process_input(false)

func _notification(what):
	match(what):
		NOTIFICATION_VISIBILITY_CHANGED:
			if is_visible():
				set_process_input(true)
				get_tree().paused = true
			else:
				set_process_input(false)
				get_tree().paused = false
				
func _process(delta):
	$SelectionPointer.position = polar2cartesian(110, deg2rad(-rect_rotation - 90)) + my_center
	$SelectionPointer.rotation_degrees = -rect_rotation
	$CurrentColorPointer.rotation_degrees = -rect_rotation + slice_size * (curr_top_slice - curr_player_slice)

#TODO: Add continuous scroll for holding the button
func _input(event: InputEvent):
	#Rotate Wheel
	if event.is_action("ui_left") && Input.is_action_just_pressed("ui_left") && !$Tween.is_active():
		$Tween.interpolate_property(self, "rect_rotation", null, rect_rotation - slice_size, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		curr_top_slice -= 1
		curr_top_slice = wrapi(curr_top_slice, 0, color_array.size())
		$SelectionPointer.modulate = color_array[curr_top_slice]

	if event.is_action("ui_right") && Input.is_action_just_pressed("ui_right") && !$Tween.is_active():
		$Tween.interpolate_property(self, "rect_rotation", null, rect_rotation + slice_size, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		curr_top_slice += 1
		curr_top_slice = wrapi(curr_top_slice, 0, color_array.size())
		$SelectionPointer.modulate = color_array[curr_top_slice]
	
	#Select Color
	if event.is_action("ui_accept"):
		picker_array[curr_top_slice].popup()
		
		set_process_input(false)
		accept_event()
	
	#Close
	if event.is_action("ui_cancel") && self.is_visible() && Input.is_action_just_pressed("ui_cancel"):
		_close()
	elif event.is_action("ui_end") && self.is_visible() && Input.is_action_just_pressed("ui_end"):
		_force_close()
	elif event.is_action("palette_menu") && Input.is_action_just_pressed("palette_menu"):
		accept_event()
		_close()
	

func _pressed():
	if !$Tween.is_active() && Input.is_action_just_released("left_click"):
		var mouse_pos = get_local_mouse_position()
		var mouse_angle = rad2deg(mouse_pos.angle_to_point(my_center))
		if mouse_angle < 0:
			mouse_angle += 360.0
		mouse_angle = 360.0 - mouse_angle #This is mostly to bring it in line with how the shader handles it.
		var mouse_region = mouse_angle / slice_size
		if int(floor(mouse_region)) != curr_top_slice:
			var rotate_amount = slice_size * (int(floor(mouse_region)) - curr_top_slice)
			rotate_amount = wrapf(rotate_amount, -180, 180)
			$Tween.interpolate_property(self, "rect_rotation", null, rect_rotation + rotate_amount, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Tween.start()
			
			mouse_click = true
			curr_top_slice = int(floor(mouse_region))
			$SelectionPointer.modulate = color_array[curr_top_slice]
			
		else:
			picker_array[curr_top_slice].popup_centered()
			set_process_input(false)

func add_color(new_color: Color):
	var new_idx = color_array.size()
	color_array.append(new_color)
	picker_array.append(CCPPopup.instance())
	call_deferred("add_child", picker_array[new_idx])
	
	picker_array[new_idx].color = new_color
	picker_array[new_idx].rect_min_size = Vector2(50,50)
	picker_array[new_idx].connect("color_changed", self, "_update_color")
	picker_array[new_idx].connect("popup_hide", self, "_on_popup_hide")
	
	slice_size = 360.0 / color_array.size()
	self.rect_rotation = -(90 - slice_size / 2) + curr_top_slice * slice_size
	update_shader()

func set_top_slice(new_top : int):
	curr_top_slice = new_top
	curr_player_slice = new_top
	self.rect_rotation = -(90 - slice_size / 2) + curr_top_slice * slice_size
	var new_col = color_array[curr_top_slice]
	$SelectionPointer.modulate = new_col
	$CurrentColorPointer.modulate = Color(new_col.r, new_col.g, new_col.b, 0.5)
	$CurrentColorPointer.position = polar2cartesian(110, deg2rad(-rect_rotation - 90)) + my_center
	$CurrentColorPointer.rotation_degrees = slice_size

func update_shader():
	for idx in range(color_array.size()):
		material.set_shader_param("color" + String(idx), color_array[idx])
	material.set_shader_param("colors_in_use", color_array.size())
	
func _update_color(new_color: Color):
	color_array[curr_top_slice] = new_color
	update_shader()
	$SelectionPointer.modulate = color_array[curr_top_slice]
	if curr_top_slice == curr_player_slice:
		$CurrentColorPointer.modulate = Color(new_color.r, new_color.g, new_color.b, 0.5)
	emit_signal("color_changed", color_array[curr_top_slice], curr_top_slice)

func _on_Tween_tween_all_completed():
	rect_rotation = wrapf(rect_rotation, 0, 360)
	if mouse_click:
		picker_array[curr_top_slice].popup_centered()
		set_process_input(false)
		mouse_click = false
		
func _on_popup_hide():
	set_process_input(true)

func _close():
	for picker in picker_array:
		if picker.is_visible():
			return
	hide()

func _force_close():
	for picker in picker_array:
		picker.hide()
	hide()