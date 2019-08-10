extends Button

var JPCP = preload("res://Scenes/JoyPadColorPicker.tscn")
var blank_theme = preload("res://new_theme.tres")
var joypad_picker
var mouse_picker = ColorPicker.new()

var joypad_popup = PopupPanel.new()
var mouse_popup = PopupPanel.new()

export var color = Color(1.0,0.0,0.0,1.0)
var presets: PoolColorArray setget , get_presets

var popup_opened = false setget , is_popup_open

signal color_changed(color)

func is_popup_open() -> bool:
	return popup_opened
func get_presets() -> PoolColorArray:
	return presets

# Called when the node enters the scene tree for the first time.
func _ready():
	self.self_modulate = color
	joypad_picker = JPCP.instance()
	joypad_popup.add_child(joypad_picker)
	mouse_popup.add_child(mouse_picker)
	self.add_child(joypad_popup)
	self.add_child(mouse_popup)
	joypad_picker.connect("lose_focus", self, "_close_joypad_popup")
	joypad_popup.connect("popup_hide", self, "_close_joypad_popup")
	mouse_popup.connect("popup_hide", self, "_close_mouse_popup")
	mouse_picker.set_edit_alpha(false)
	mouse_picker.set_theme(blank_theme)

func _pressed():
	if Input.get_connected_joypads().size() > 0:
		joypad_picker.color = color
		for idx in range(presets.size()):  #TODO: Set a variable to the picker to use to remove redundancy
			joypad_picker.add_preset(presets[idx])
		presets.resize(0)
		joypad_popup.popup()
		joypad_picker.set_focus()
#		hide()
	else:
		mouse_picker.set_pick_color(color)
		for idx in range(presets.size()):
			mouse_picker.add_preset(presets[idx])
		mouse_popup.popup()
#		hide()
	popup_opened = true

func _close_joypad_popup(): #Just to help close the joypad picker
	color = joypad_picker.color
	emit_signal("color_changed", color)
	if presets.size() == 0:
		presets = joypad_picker.get_presets()
		joypad_picker.erase_all_presets()
	joypad_popup.hide()
	_popup_closed()
	
func _close_mouse_popup():
	color = mouse_picker.get_pick_color()
	emit_signal("color_changed", color)
	presets = mouse_picker.get_presets()
	for idx in range(presets.size()):
		mouse_picker.erase_preset(presets[idx]) #Clear it everytime since there's no easy clear
	_popup_closed()
	
func _popup_closed():
	show()
	self.grab_focus() #FIX: Use set_focus_mode() to allow a control to get focus
	self.self_modulate = color
	popup_opened = false
