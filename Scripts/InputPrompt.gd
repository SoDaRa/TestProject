extends Panel

signal input_received(event)

func _ready():
	set_process(false)

func _notification(what):
	match(what):
		NOTIFICATION_VISIBILITY_CHANGED:
			if is_visible():
				set_process(true)
			else:
				set_process(false)

func _process(delta):
	if get_focus_owner() != self:
		grab_focus()

func _gui_input(event : InputEvent):
	accept_event()
	if not event.is_pressed():
		return
	if event is InputEventMouseMotion:
		return
	if event is InputEventWithModifiers:
		if $VBox/Modifiers/HBox/ShiftButton.pressed:
			event.set_shift(true)
		if $VBox/Modifiers/HBox/AltButton.pressed:
			event.set_alt(true)
		if $VBox/Modifiers/HBox/CtrlButton.pressed:
			event.set_control(true)
		if $VBox/Modifiers/HBox/MetaButton.pressed:
			event.set_metakey(true)
	print(event)
	emit_signal("input_received", event)