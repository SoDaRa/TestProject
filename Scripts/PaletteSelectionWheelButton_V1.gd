extends TextureButton
#Version 1/Prototype
var color_sequence = [Color(1,0,0,1), Color(0,0,1,1), Color(0,1,0,1)]
var new_color_array = [ Color(1,1,1,1), Color(0,0,0,1), Color(1,0,1,1), Color(1,1,0,1), Color(0,1,1,1), Color(0.8,0,1,1)]
onready var my_center = Vector2(texture_normal.get_width() / 2, texture_normal.get_height() / 2)
var curr_top_slice = 0
var slice_size = 360.0
var mouse_click = false

var CCPPopup = preload("res://Scenes/CCPPopup.tscn")
var picker_array = []

signal top_changed(new_color)
signal color_changed(new_color, position)
#NOTE: Add function to set curr_top_position based on curr_color

# Called when the node enters the scene tree for the first time.
func _ready():
	var my_bitmask = BitMap.new()
	var my_bit_image = load("res://Sprites/big_blank_ball.png")
	my_bitmask.create_from_image_alpha(my_bit_image.get_data())
	texture_click_mask = my_bitmask

	update_shader()
	rect_pivot_offset = my_center

	emit_signal("top_changed", color_sequence[curr_top_slice])
	for idx in range(color_sequence.size()):
		picker_array.append(CCPPopup.instance())
		add_child(picker_array[idx])
		picker_array[idx].connect("color_changed", self, "_update_color")
		picker_array[idx].connect("popup_hide", self, "_on_popup_hide")
		picker_array[idx].color = color_sequence[idx]
	slice_size = 360.0 / color_sequence.size()
	self.rect_rotation = -(90 - slice_size / 2)
	curr_top_slice = 0

func _input(event: InputEvent):
	if event.is_action("ui_up") && Input.is_action_just_pressed("ui_up"):
		if new_color_array.empty():
			return

		color_sequence.append(new_color_array.pop_front())
		if picker_array.size() < color_sequence.size():
			var idx = picker_array.size()
			picker_array.append(CCPPopup.instance())
			add_child(picker_array[idx])
			picker_array[idx].connect("color_changed", self, "_update_color")
			picker_array[idx].connect("popup_hide", self, "_on_popup_hide")
			picker_array[idx].color = color_sequence[idx]
		else:
			picker_array[color_sequence.size() - 1].color = color_sequence[color_sequence.size() - 1]
		update_shader()

		slice_size = 360.0 / color_sequence.size()
		self.rect_rotation = -(90 - slice_size / 2) + curr_top_slice * slice_size
		emit_signal("top_changed", color_sequence[curr_top_slice])

	if event.is_action("ui_down") && Input.is_action_just_pressed("ui_down"):
		if color_sequence.size() == 1:
			return
		new_color_array.append(color_sequence.pop_back())
		material.set_shader_param("colors_in_use", color_sequence.size())

		slice_size = 360.0 / color_sequence.size()
		if curr_top_slice >= color_sequence.size():
			curr_top_slice = color_sequence.size() - 1
		self.rect_rotation = -(90 - slice_size / 2) + curr_top_slice * slice_size
		emit_signal("top_changed", color_sequence[curr_top_slice])

	if event.is_action("ui_left") && Input.is_action_just_pressed("ui_left") && !$Tween.is_active():
		$Tween.interpolate_property(self, "rect_rotation", null, rect_rotation - slice_size, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		curr_top_slice -= 1
		curr_top_slice = wrapi(curr_top_slice, 0, color_sequence.size())
		emit_signal("top_changed", color_sequence[curr_top_slice])

	if event.is_action("ui_right") && Input.is_action_just_pressed("ui_right") && !$Tween.is_active():
		$Tween.interpolate_property(self, "rect_rotation", null, rect_rotation + slice_size, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		curr_top_slice += 1
		curr_top_slice = wrapi(curr_top_slice, 0, color_sequence.size())
		emit_signal("top_changed", color_sequence[curr_top_slice])

	if event.is_action("ui_accept"):
		picker_array[curr_top_slice].popup()

		set_process_input(false)
		accept_event()

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
			emit_signal("top_changed", color_sequence[curr_top_slice])
		else:
			picker_array[curr_top_slice].popup_centered()
			set_process_input(false)

func _add_color(new_color: Color, my_owner: Object):
	var new_idx = color_sequence.size()
	picker_array.append(CCPPopup.instance())
	call_deferred("add_child", picker_array[new_idx])
	picker_array[new_idx].color = new_color
	picker_array[new_idx].rect_min_size = Vector2(50,50)


func update_shader():
	for idx in range(color_sequence.size()):
		material.set_shader_param("color" + String(idx), color_sequence[idx])
	material.set_shader_param("colors_in_use", color_sequence.size())

func _update_color(new_color: Color):
	color_sequence[curr_top_slice] = new_color
	update_shader()
	emit_signal("top_changed", color_sequence[curr_top_slice])
	emit_signal("color_changed", color_sequence[curr_top_slice], curr_top_slice)

func _on_Tween_tween_all_completed():
	if mouse_click:
		picker_array[curr_top_slice].popup_centered()
		set_process_input(false)
		mouse_click = false

func _on_popup_hide():
	set_process_input(true)