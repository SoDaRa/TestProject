extends Control

signal bg_save_requested
signal mission_end_requested
var in_mission = false

func _ready():
	pass # Replace with function body.

func _notification(what):
	match(what):
		NOTIFICATION_VISIBILITY_CHANGED:
			if is_visible():
				set_process_unhandled_input(true)
				get_tree().paused = true
				if in_mission:
					$CenterContainer/VBoxContainer/SaveBG.hide()
					$CenterContainer/VBoxContainer/EndMission.show()
				else:
					$CenterContainer/VBoxContainer/SaveBG.show()
					$CenterContainer/VBoxContainer/EndMission.hide()
			else:
				set_process_unhandled_input(false)
				get_tree().paused = false

func _unhandled_input(event):
	if event.is_action("ui_end") && Input.is_action_just_pressed("ui_end"):
		$InputEditor.hide()
		hide()
		accept_event()
	if event.is_action("ui_cancel") && Input.is_action_just_pressed("ui_cancel"):
		if $InputEditor.is_visible():
			$InputEditor.hide()
			accept_event()
			return
		hide()
	

func _on_Resume_pressed():
	hide()

func _on_KeyBindings_pressed():
	$InputEditor.show()

func _on_SaveBG_pressed():
	$WaitLabel.text = "Save in progress\nPlease Wait"
	$WaitLabel.show()
	$DelayTimer.start(0.1)
func _on_DelayTimer_timeout():
	emit_signal("bg_save_requested")
	$WaitLabel.text = "Save Complete"
	$WaitLabel/Tween.interpolate_property($WaitLabel, "modulate", null, Color(0,0,0,0), 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$WaitLabel/Tween.start()

func _on_EndMission_pressed():
	hide()
	emit_signal("mission_end_requested")

func _on_Exit_pressed():
	hide()




