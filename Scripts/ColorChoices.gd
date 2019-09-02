extends GridContainer

var CCPB = preload("res://Scenes/CustomColorPickerButton.tscn")
var color_picker_array = []

func _ready():
	set_process(false)
	set_process_unhandled_input(false)
	
func _notification(what):
	match(what):
		NOTIFICATION_VISIBILITY_CHANGED: 
			if is_visible():
				color_picker_array[0].grab_focus()
				set_process(true)
				set_process_unhandled_input(true)
				get_tree().paused = true
			else:
				set_process(false)
				set_process_unhandled_input(false)
				get_tree().paused = false
		_: return
		
func _add_color(new_color: Color, my_owner: Object):
	var new_idx = color_picker_array.size()
	color_picker_array.append(CCPB.instance())
	call_deferred("add_child", color_picker_array[new_idx])
	color_picker_array[new_idx].color = new_color
	color_picker_array[new_idx].rect_min_size = Vector2(50,50)
	color_picker_array[new_idx].name = str(new_idx)
	
	if my_owner.has_method("_color_picker_changed"):
		color_picker_array[new_idx].connect("color_changed", my_owner, "_color_picker_changed", [color_picker_array[new_idx].name])
	assert(my_owner.has_method("_color_picker_changed") == true)

# warning-ignore:unused_argument
func _process(delta):
	if self.has_focus():
		color_picker_array[0].grab_focus()
func _unhandled_input(event):
	#This is just so the default button for palette menu on joypad doesn't close it, but 
	var event_is_ui_direction = event.is_action("ui_up") || event.is_action("ui_down") || event.is_action("ui_left") || \
								event.is_action("ui_right") 
	if event.is_action("ui_cancel") && self.is_visible() && Input.is_action_just_pressed("ui_cancel"):
		_close()
	elif event.is_action("ui_end") && self.is_visible() && Input.is_action_just_pressed("ui_end"):
		_close()
	elif event.is_action("palette_menu") && Input.is_action_just_pressed("palette_menu") && !event_is_ui_direction:
		accept_event()
		_close()
			
func _close():
	for idx in range(color_picker_array.size()):
		if color_picker_array[idx].is_popup_open():
			return
	hide()