extends Button

signal preset_removed(color, number)
signal color_pressed(color)

func _gui_input(event):
	if InputMap.action_has_event("ui_cancel", event) && Input.is_action_just_pressed("ui_cancel"): #Prevents from losing multiple presets from one press
		self.accept_event() #Consume event to prevent closing entire picker
		emit_signal("preset_removed", self.modulate, int(self.name))

func _pressed():
	emit_signal("color_pressed", self.modulate)
