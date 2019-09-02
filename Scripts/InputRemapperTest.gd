extends Control

var input_action : String

func _ready():
	set_process_input(false)
	$Tree.grab_focus()

func _on_Tree_item_activated():
	var selected_action = $Tree.get_selected()
	if selected_action.get_metadata(0) != null:
		input_action = selected_action.get_metadata(0)
	else:
		return
	print(input_action)
	if not InputMap.has_action(input_action):
		print("Action not in InputMap!!!")
		return
	$Panel.show()
	set_process_input(true)
	
func _input(event: InputEvent):
	accept_event()
	if not event.is_pressed():
		return
	if InputMap.action_has_event(input_action, event): #TODO: Check for more things to prevent the player from removing
		if input_action == "ui_accept" && InputMap.get_action_list("ui_accept").size() == 2:
			print("Can't remove final accept")
			
		if input_action == "ui_up" && event is InputEventKey && event.get_scancode() == KEY_UP:
			print("Can't unbind up")
		elif input_action == "ui_down" && event is InputEventKey && event.get_scancode() == KEY_DOWN:
			print("Can't unbind down")
		else:
			InputMap.action_erase_event(input_action, event)
	else: #TODO: Check for things to prevent the player from binding together
		InputMap.action_add_event(input_action, event)
	$Tree.update_item()
	$Panel.hide()
	set_process_input(false)
