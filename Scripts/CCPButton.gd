extends Button

var CCP = preload("res://Scenes/CustomColorPicker.tscn")
var custom_picker

var custom_popup = PopupPanel.new()

export var color = Color(1,0,0,1)
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
	custom_picker = CCP.instance()
	custom_popup.add_child(custom_picker)
	self.add_child(custom_popup)
	custom_picker.connect("lose_focus", self, "_close_custom_popup")
	custom_popup.connect("popup_hide", self, "_close_custom_popup")

func _pressed():
	custom_picker.color = color
	for idx in range(presets.size()):  #Set a variable to the picker to use to remove redundancy
		custom_picker.add_preset(presets[idx])
	presets.resize(0)
	custom_popup.popup_centered()
	custom_popup.grab_focus() #To guarentee it gets the focus
#		hide()
	popup_opened = true

func _close_custom_popup(): #Just to help close the joypad picker
	color = custom_picker.color
	emit_signal("color_changed", color)
	if presets.size() == 0:
		presets = custom_picker.get_presets()
		custom_picker.erase_all_presets()
	custom_popup.hide()
	_popup_closed()

func _popup_closed():
#	show()
	self.grab_focus() #FIX: Use set_focus_mode() to allow a control to get focus
	self.self_modulate = color
	popup_opened = false
