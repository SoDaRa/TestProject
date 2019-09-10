extends Control

#TODO: Add defaults to restore to

var selected_action : String

var default_inputmap_dict = {
	up = ["w","up","joy_b","joy_l_stick_up"],
	left = ["a","left","joy_l_stick_left"],
	down = ["s","down","joy_l_stick_down"],
	right = ["d","right","joy_l_stick_right"],
	paint = ["space","mouse_left","joy_r2","joy_l2"],
	next_color = ["l","mouse_right","joy_r1"],
	previous_color = ["j","joy_l1"],
	swap_shape = ["r","joy_a"],
	swap_physics = ["z","joy_d_left"],
	interact = ["x","joy_y"],
	palette_menu = ["t","joy_d_up"],
	rotate_ccw = ["q"],
	rotate_cw = ["e"],
	zoom_out = ["v"],
#	save_background = ["g"],
	increase_size = ["i"],
	decrease_size = ["k"],
	ccp_hue_cw = ["e","o"],
	ccp_hue_ccw = ["q","u"],
	ccp_saturation_up = ["d","l"],
	ccp_saturation_down = ["a","j"],
	ccp_value_up = ["w","i"],
	ccp_value_down = ["s","k"],
	ui_up = ["up","w","joy_l_stick_up","joy_d_up"],
	ui_down = ["down","s","joy_l_stick_down","joy_d_down"],
	ui_left = ["left","a","joy_l_stick_left","joy_d_left"],
	ui_right = ["right","d","joy_l_stick_right","joy_d_right"],
	ui_accept = ["enter","space","joy_a"],
	ui_cancel = ["backspace","joy_b"],
	ui_select = ["space"],
#	"" = [""]
}
onready var MyTree = get_node("VBoxContainer/Tree")

func _ready():
	MyTree.grab_focus()

func _on_Tree_item_activated():
	var selected_item = MyTree.get_selected()
	if selected_item.get_metadata(0) != null:
		selected_action = selected_item.get_metadata(0)
	else:
		return
	print("KeyBindingControl: Rebinding ", selected_action)
	assert(InputMap.has_action(selected_action))
	$InputPrompt.show()

func _input(event: InputEvent):
	if !$InputPrompt.is_visible():
		if event is InputEventMouseButton:
			if event.is_action("left_click") && Input.is_action_just_pressed("left_click"):
				if !get_rect().has_point(get_global_mouse_position()):
					accept_event()
					hide()
	else:
		accept_event()
		if not event.is_pressed():
			return
		#Forbidden rebinds
		if event is InputEventKey && action_category(selected_action) == "UI":
			if event.get_scancode() == KEY_ENTER:
				print("Can't rebind enter")
				close_prompt()
				return
			elif event.get_scancode() == KEY_UP:
				print("Can't rebind up")
				close_prompt()
				return
			elif event.get_scancode() == KEY_DOWN:
				print("Can't rebind down")
				close_prompt()
				return
		if event is InputEventMouseMotion:
			return
	
		#Remove action
		if InputMap.action_has_event(selected_action, event):
			InputMap.action_erase_event(selected_action, event) #TODO: Add check for if no InputEvent is associated with action
			close_prompt()
			return
		#Rebind action
		for remove_action in InputMap.get_actions():
			if InputMap.action_has_event(remove_action, event) && action_category(remove_action) == action_category(selected_action):
				InputMap.action_erase_event(remove_action, event)
				MyTree.update_item(remove_action, action_category(remove_action))
		InputMap.action_add_event(selected_action, event)
		close_prompt()

func close_prompt():
	MyTree.update_selected_item()
	$InputPrompt.hide()

func restore_defaults():
	for action in InputMap.get_actions():
		if action == "left_click" || action == "Dummy_Button" || action == "ui_home" || action == "ui_end" || \
			action == "ui_focus_next" || action == "ui_focus_prev" || action == "ui_page_up" || action == "ui_page_down":
			continue
		InputMap.action_erase_events(action)
	var input_dict = get_input_dict()
	for action in default_inputmap_dict:
		for input in default_inputmap_dict[action]:
			InputMap.action_add_event(action, input_dict[input])
	for action in InputMap.get_actions():
		MyTree.update_item(action, action_category(action))
	
func action_category(action:String):
	match(action):
		"up": return "Gameplay"
		"down": return "Gameplay"
		"left": return "Gameplay"
		"right": return "Gameplay"
		"paint": return "Gameplay"
		"next_color": return "Gameplay"
		"previous_color": return "Gameplay"
		"swap_shape": return "Gameplay"
		"swap_physics": return "Gameplay"
		"interact": return "Gameplay"
		"palette_menu": return "Gameplay"
		"increase_size": return "Gameplay"
		"decrease_size": return "Gameplay"
		"rotate_cw": return "Gameplay"
		"rotate_ccw": return "Gameplay"
		"zoom_out": return "Gameplay"
#		"save_background": return "Gameplay"
		
		"ui_up": return "UI"
		"ui_down": return "UI"
		"ui_left": return "UI"
		"ui_right": return "UI"
		"ui_accept": return "UI"
		"ui_cancel": return "UI"
		"ui_select": return "UI"
		"ui_page_up": return "UI"
		"ui_page_down": return "UI"
		"ui_focus_next": return "UI"
		"ui_focus_prev": return "UI"
#		"ui_home": return "UI"
#		"ui_end": return "UI"
		
		"ccp_hue_cw": return "Color Picker"
		"ccp_hue_ccw": return "Color Picker"
		"ccp_saturation_up": return "Color Picker"
		"ccp_saturation_down": return "Color Picker"
		"ccp_value_up": return "Color Picker"
		"ccp_value_down": return "Color Picker"
		
		_: return "NULL"
func get_input_dict() -> Dictionary:
	var input_dict = {}
	#Keyboard input
	input_dict["w"] = InputEventKey.new()
	input_dict["a"] = InputEventKey.new()
	input_dict["s"] = InputEventKey.new()
	input_dict["d"] = InputEventKey.new()
	input_dict["q"] = InputEventKey.new()
	input_dict["e"] = InputEventKey.new()
	input_dict["r"] = InputEventKey.new()
	input_dict["t"] = InputEventKey.new()
	input_dict["z"] = InputEventKey.new()
	input_dict["x"] = InputEventKey.new()
	input_dict["v"] = InputEventKey.new()
	input_dict["left"] = InputEventKey.new()
	input_dict["right"] = InputEventKey.new()
	input_dict["up"] = InputEventKey.new()
	input_dict["down"] = InputEventKey.new()
	input_dict["space"] = InputEventKey.new()
	input_dict["enter"] = InputEventKey.new()
	input_dict["backspace"] = InputEventKey.new()
	input_dict["i"] = InputEventKey.new()
	input_dict["k"] = InputEventKey.new()
	input_dict["l"] = InputEventKey.new()
	input_dict["j"] = InputEventKey.new()
	input_dict["u"] = InputEventKey.new()
	input_dict["o"] = InputEventKey.new()
	
	input_dict["w"].set_scancode(KEY_W)
	input_dict["a"].set_scancode(KEY_A)
	input_dict["s"].set_scancode(KEY_S)
	input_dict["d"].set_scancode(KEY_D)
	input_dict["q"].set_scancode(KEY_Q)
	input_dict["e"].set_scancode(KEY_E)
	input_dict["r"].set_scancode(KEY_R)
	input_dict["t"].set_scancode(KEY_T)
	input_dict["z"].set_scancode(KEY_Z)
	input_dict["x"].set_scancode(KEY_X)
	input_dict["v"].set_scancode(KEY_V)
	input_dict["left"].set_scancode(KEY_LEFT)
	input_dict["right"].set_scancode(KEY_RIGHT)
	input_dict["up"].set_scancode(KEY_UP)
	input_dict["down"].set_scancode(KEY_DOWN)
	input_dict["space"].set_scancode(KEY_SPACE)
	input_dict["enter"].set_scancode(KEY_ENTER)
	input_dict["backspace"].set_scancode(KEY_BACKSPACE)
	input_dict["i"].set_scancode(KEY_I)
	input_dict["k"].set_scancode(KEY_K)
	input_dict["l"].set_scancode(KEY_L)
	input_dict["j"].set_scancode(KEY_J)
	input_dict["u"].set_scancode(KEY_U)
	input_dict["o"].set_scancode(KEY_O)
	
	#Joypad input
	input_dict["joy_d_left"] = InputEventJoypadButton.new()
	input_dict["joy_d_up"] = InputEventJoypadButton.new()
	input_dict["joy_d_right"] = InputEventJoypadButton.new()
	input_dict["joy_d_down"] = InputEventJoypadButton.new()
	input_dict["joy_a"] = InputEventJoypadButton.new() #Nintendo A
	input_dict["joy_b"] = InputEventJoypadButton.new() #Nintendo B
	input_dict["joy_x"] = InputEventJoypadButton.new() #Nintendo X
	input_dict["joy_y"] = InputEventJoypadButton.new() #Nintendo Y
	input_dict["joy_l1"] = InputEventJoypadButton.new()
	input_dict["joy_l2"] = InputEventJoypadButton.new()
	input_dict["joy_r1"] = InputEventJoypadButton.new()
	input_dict["joy_r2"] = InputEventJoypadButton.new()
	input_dict["joy_start"] = InputEventJoypadButton.new()
	input_dict["joy_select"] = InputEventJoypadButton.new()
	
	input_dict["joy_l_stick_up"] = InputEventJoypadMotion.new()
	input_dict["joy_l_stick_down"] = InputEventJoypadMotion.new()
	input_dict["joy_l_stick_left"] = InputEventJoypadMotion.new()
	input_dict["joy_l_stick_right"] = InputEventJoypadMotion.new()
	input_dict["joy_r_stick_up"] = InputEventJoypadMotion.new()
	input_dict["joy_r_stick_down"] = InputEventJoypadMotion.new()
	input_dict["joy_r_stick_left"] = InputEventJoypadMotion.new()
	input_dict["joy_r_stick_right"] = InputEventJoypadMotion.new()
	
	input_dict["joy_d_left"].set_button_index(JOY_DPAD_LEFT)
	input_dict["joy_d_up"].set_button_index(JOY_DPAD_UP)
	input_dict["joy_d_right"].set_button_index(JOY_DPAD_RIGHT)
	input_dict["joy_d_down"].set_button_index(JOY_DPAD_DOWN)
	input_dict["joy_a"].set_button_index(JOY_DS_A)
	input_dict["joy_b"].set_button_index(JOY_DS_B)
	input_dict["joy_x"].set_button_index(JOY_DS_X)
	input_dict["joy_y"].set_button_index(JOY_DS_Y)
	input_dict["joy_l1"].set_button_index(JOY_L)
	input_dict["joy_l2"].set_button_index(JOY_L2)
	input_dict["joy_r1"].set_button_index(JOY_R)
	input_dict["joy_r2"].set_button_index(JOY_R2)
	input_dict["joy_start"].set_button_index(JOY_START)
	input_dict["joy_select"].set_button_index(JOY_SELECT)
	
	input_dict["joy_l_stick_up"].set_axis(JOY_AXIS_1)
	input_dict["joy_l_stick_up"].set_axis_value(-1.0)
	input_dict["joy_l_stick_down"].set_axis(JOY_AXIS_1)
	input_dict["joy_l_stick_down"].set_axis_value(1.0)
	input_dict["joy_l_stick_left"].set_axis(JOY_AXIS_0)
	input_dict["joy_l_stick_left"].set_axis_value(-1.0)
	input_dict["joy_l_stick_right"].set_axis(JOY_AXIS_0)
	input_dict["joy_l_stick_right"].set_axis_value(1.0)
	input_dict["joy_r_stick_up"].set_axis(JOY_AXIS_3)
	input_dict["joy_r_stick_up"].set_axis_value(-1.0)
	input_dict["joy_r_stick_down"].set_axis(JOY_AXIS_3)
	input_dict["joy_r_stick_down"].set_axis_value(1.0)
	input_dict["joy_r_stick_left"].set_axis(JOY_AXIS_2)
	input_dict["joy_r_stick_left"].set_axis_value(-1.0)
	input_dict["joy_r_stick_right"].set_axis(JOY_AXIS_2)
	input_dict["joy_r_stick_right"].set_axis_value(1.0)
	
	#Mouse Input
	input_dict["mouse_left"] = InputEventMouseButton.new()
	input_dict["mouse_right"] = InputEventMouseButton.new()
	input_dict["mouse_left"].set_button_index(BUTTON_LEFT)
	input_dict["mouse_right"].set_button_index(BUTTON_RIGHT)
	return input_dict