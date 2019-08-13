extends GridContainer

var CCPB = preload("res://Scenes/CustomColorPickerButton.tscn")
var color_picker_array = []
onready var player: RigidBody2D = get_parent().get_parent().get_parent()

signal show

func _ready():
	for new_color in range(player.color_sequence.size()):
		color_picker_array.append(CCPB.instance())
		call_deferred("add_child", color_picker_array[new_color])
		color_picker_array[new_color].color = player.color_sequence[new_color]
		color_picker_array[new_color].rect_min_size = Vector2(50,50)
		color_picker_array[new_color].name = str(new_color)

		color_picker_array[new_color].connect("color_changed", player, "_color_picker_changed", [color_picker_array[new_color].name])
		
func _add_color():
	var new_idx = color_picker_array.size()
	color_picker_array.append(CCPB.instance())
	call_deferred("add_child", color_picker_array[new_idx])
	color_picker_array[new_idx].color = player.color_sequence[new_idx]
	color_picker_array[new_idx].rect_min_size = Vector2(50,50)
	color_picker_array[new_idx].name = str(new_idx)

# warning-ignore:unused_argument
func _process(delta):
	if self.has_focus():
		color_picker_array[0].grab_focus()
			
func _unhandled_input(event):
	if event.is_action("palette_menu") && !self.is_visible() && Input.is_action_just_pressed("palette_menu"):
		show()
		emit_signal("show")
		color_picker_array[0].grab_focus()
		return
	
	if event.is_action("ui_cancel") && self.is_visible() && Input.is_action_just_pressed("ui_cancel"):
		_close()
	elif event.is_action("palette_menu") && Input.is_action_just_pressed("palette_menu") && not event is InputEventJoypadButton:
		_close() #TODO: Rig so will do if the event isn't a UI_left,right,etc.
			
func _close():
	for idx in range(color_picker_array.size()):
		if color_picker_array[idx].is_popup_open():
			return
	hide()
	emit_signal("hide")