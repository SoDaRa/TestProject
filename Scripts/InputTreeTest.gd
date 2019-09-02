extends Tree

class CustomSorter:
	static func my_sort(str_1: String, str_2: String) -> bool:
		if string_priority(str_1) < string_priority(str_2):
			return true
		else:
			return false
	static func string_priority(my_string:String) -> int:
		match my_string:
			"up": return 0
			"down": return 1
			"left": return 2
			"right": return 3
			"paint": return 4
			"next_color": return 5
			"previous_color": return 6
			"swap_shape": return 7
			"swap_player_physics": return 8
			"interact": return 9
			"palette_menu": return 10
			"increase_size": return 11
			"decrease_size": return 12
			"rotate_cw": return 13
			"rotate_ccw": return 14
			"zoom_out": return 15
			"save_background": return 16
#			"Dummy_Button": return 17
			
			"ui_up": return 0
			"ui_down": return 1
			"ui_left": return 2
			"ui_right": return 3
			"ui_accept": return 4
			"ui_cancel": return 5
			"ui_select": return 6
			"ui_page_up": return 7
			"ui_page_down": return 8
			"ui_focus_next": return 9
			"ui_focus_prev": return 10
#			"ui_home": return 11
#			"ui_end": return 12

			"ccp_hue_cw": return 0
			"ccp_hue_ccw": return 1
			"ccp_saturation_up": return 2
			"ccp_saturation_down": return 3
			"ccp_value_up": return 4
			"ccp_value_down": return 5

			_: return 37


#Actual variables
onready var input_actions = InputMap.get_actions()
var action_input_dict = {}
var delay = 0.0
var count = 0

func _ready():
	set_process(false)
	input_actions.sort_custom(CustomSorter, "my_sort") #Sort the array of InputMap Actions so they display consistently
	#Removing unused actions
	input_actions.erase("Dummy_Button")
	input_actions.erase("ui_end")
	input_actions.erase("ui_home")
	#Create Root and designated sections
	var root = self.create_item()
	
	var gameplay_section = self.create_item(root)
	var ui_section = self.create_item(root)
	var color_picker_section = self.create_item(root)
	#Create Column titles
	self.set_column_title(0, "Action")
	self.set_column_title(1, "Keyboard/Mouse Input")
	self.set_column_title(2, "Joypad Input")
	self.set_column_titles_visible(true)
	#Set Sections titles
	gameplay_section.set_text(0, " Gameplay")
	ui_section.set_text(0, " UI / Menus")
	color_picker_section.set_text(0, " Color Picker")
	
	#Get the actions for each input
	for action in input_actions:
		action_input_dict[action] = InputMap.get_action_list(action)
		
		#UI Actions
		if action.begins_with("ui"):
			var ui_item = self.create_item(ui_section)
			#Set row name
			var row_text = " " + action.capitalize()
			row_text = row_text.replace("Ui ", "")
			
			ui_item.set_text(0, row_text)
			#Text for keyboard and joypad columns
			var keyboard_mouse_text = keyboard_mouse_controls(action)
			var joypad_text = joypad_controls(action)
			#Set into column
			ui_item.set_text(1, keyboard_mouse_text)
			ui_item.set_text(2, joypad_text)
			#Set metadata so it can be used to reference which action this corresponds to
			ui_item.set_metadata(0, action)
		#Custom Color Picker Actions
		elif action.begins_with("ccp"):
			var ccp_item = self.create_item(color_picker_section)
			#Set row name
			var row_text = action.replace("ccp_", "")
			row_text = " " + row_text.capitalize()
			if row_text.find("Cw") != -1:
				row_text = row_text.replace("Cw", "CW")
			if row_text.find("Ccw") != -1:
				row_text = row_text.replace("Ccw", "CCW")
			
			ccp_item.set_text(0, row_text)
			#Text for keyboard and joypad columns
			var keyboard_mouse_text = keyboard_mouse_controls(action)
			var joypad_text = joypad_controls(action)
			
			#Set into column
			ccp_item.set_text(1, keyboard_mouse_text)
			ccp_item.set_text(2, joypad_text)
			#Set metadata so it can be used to reference which action this corresponds to
			ccp_item.set_metadata(0, action)
		#Gameplay/Misc Actions
		else:
			var gameplay_item = self.create_item(gameplay_section)
			#Set row name
			var row_text = " " + action.capitalize()
			if row_text.find("Cw") != -1:
				row_text = row_text.replace("Cw", "CW")
			if row_text.find("Ccw") != -1:
				row_text = row_text.replace("Ccw", "CCW")
			if row_text.find("Up") != -1:
				row_text = row_text.replace("Up", "Up / Jump")
			
			gameplay_item.set_text(0, row_text)
			#Text for keyboard and joypad columns
			var keyboard_mouse_text = keyboard_mouse_controls(action)
			var joypad_text = joypad_controls(action)
			#Set into column
			gameplay_item.set_text(1, keyboard_mouse_text)
			gameplay_item.set_text(2, joypad_text)
			#Set metadata so it can be used to reference which action this corresponds to
			gameplay_item.set_metadata(0, action)
		

func update_item():
	var action_item = get_selected()
	var action = action_item.get_metadata(0)
	action_input_dict[action] = InputMap.get_action_list(action)
	var keyboard_mouse_text = keyboard_mouse_controls(action)
	var joypad_text = joypad_controls(action)
	action_item.set_text(1, keyboard_mouse_text)
	action_item.set_text(2, joypad_text)

func joypad_controls(action:String) -> String:
	var joypad_controls = "  "
	for input in action_input_dict[action]:
		if input is InputEventJoypadButton:
			joypad_controls = joypad_controls + joy_button_string(input) + ", "
	if joypad_controls.length() > 0:
		joypad_controls = joypad_controls.substr(0, joypad_controls.length() - 2)
	return joypad_controls

func keyboard_mouse_controls(action:String) -> String:
	var kbm_controls = "  "
	for input in action_input_dict[action]:
		if input is InputEventMouseButton:
			kbm_controls = kbm_controls + mouse_button_string(input) + ", "
		elif input is InputEventKey:
			kbm_controls = kbm_controls + OS.get_scancode_string(input.get_scancode()) + ", "
	if kbm_controls.length() > 0:
		kbm_controls = kbm_controls.substr(0, kbm_controls.length() - 2)
	return kbm_controls

func joy_button_string(button: InputEventJoypadButton) -> String:
	match button.get_button_index():
		0: return "Xbox A / Nintendo B / Sony Cross"
		1: return "Xbox B / Nintendo A / Sony Circle"
		2: return "Xbox X / Nintendo Y / Sony Square"
		3: return "Xbox Y / Nintendo X / Sony Triangle"
		4: return "L1"
		5: return "R1"
		6: return "L2"
		7: return "R2"
		8: return "L3"
		9: return "R3"
		10: return "Select"
		11: return "Start"
		12: return "DPad Up"
		13: return "DPad Down"
		14: return "DPad Left"
		15: return "DPad Right"
		_: return "Unknown"

func mouse_button_string(button: InputEventMouseButton) -> String:
	match button.get_button_index():
		1: return "Left Mouse"
		2: return "Right Mouse"
		3: return "Middle Mouse"
		4: return "Wheel Up"
		5: return "Wheel Down"
		6: return "Wheel Left"
		7: return "Wheel Right"
		8: return "Mouse 4"
		9: return "Mouse 5"
		_: return "Unknown"

func _gui_input(event):
	if get_selected() == null:
		return
	if event.is_echo() && (event.is_action("ui_up") || event.is_action("ui_down")):
		if event.echo:
			return
	if event.is_pressed() && (event.is_action("ui_up") || event.is_action("ui_down")):
		delay = 0
		count = 0
		set_process(true)
	else:
		set_process(false)

func _process(delta):
	if Input.is_action_pressed("ui_up") && get_selected() != null && delay == 0 && !Input.is_key_pressed(KEY_UP):
		if get_selected().get_prev_visible() != null && get_selected().get_prev_visible().is_selectable(0):
			get_selected().get_prev_visible().select(0)
	if Input.is_action_pressed("ui_down") && get_selected() != null && delay == 0 && !Input.is_key_pressed(KEY_DOWN):
		if get_selected().get_next_visible() != null && get_selected().get_next_visible().is_selectable(0):
			get_selected().get_next_visible().select(0)
	if !Input.is_action_pressed("ui_up") && !Input.is_action_pressed("ui_down"):
		set_process(false)
		print("exit process in process")
		return 
	ensure_cursor_is_visible()
	if delay == 0:
		count += 1
		delay = (1 - count/ 4)
	elif delay > 0:
		delay = delay - delta * 4
		if delay < 0:
			delay = 0.0
	else: delay = 0.0