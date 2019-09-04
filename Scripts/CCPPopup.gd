extends Popup

var CCP = preload("res://Scenes/CustomColorPicker.tscn")
var custom_picker

export var color = Color(1,0,0,1)

signal color_changed(color)

func get_presets() -> PoolColorArray:
	return custom_picker.get_presets()

# Called when the node enters the scene tree for the first time.
func _ready():
	custom_picker = CCP.instance()
	add_child(custom_picker)
	custom_picker.connect("lose_focus", self, "close_picker")
	set_process_input(false)

func _notification(what):
	match(what):
		NOTIFICATION_POST_POPUP:
			custom_picker.color = color
			set_process_input(true)
		NOTIFICATION_POPUP_HIDE:
			emit_signal("color_changed", color)
			set_process_input(false)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if !custom_picker.get_rect().has_point(event.position) && event.button_mask != 0:
			custom_picker._on_lose_focus()

func close_picker(): #Just to help close the picker
	color = custom_picker.color
	emit_signal("color_changed", color)
	hide()

