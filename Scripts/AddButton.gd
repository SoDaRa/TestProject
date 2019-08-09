extends TextureButton

signal lose_focus

func _gui_input(event):
	if InputMap.action_has_event("ui_cancel", event) && Input.is_action_just_pressed("ui_cancel"):
		self.accept_event()
		emit_signal("lose_focus")