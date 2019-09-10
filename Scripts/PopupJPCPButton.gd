extends Button

var CCP = preload("res://Scenes/CustomColorPicker.tscn")
var blank_theme = preload("res://new_theme.tres")
var custom_picker
var mouse_picker = ColorPicker.new()

var joypad_popup = PopupPanel.new()
var mouse_popup = PopupPanel.new()

var joy_button_pressed = false #Used to detect if a joypad button triggered the pressed event
var mouse_button_pressed = false

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
	custom_picker = CCP.instance()
	joypad_popup.add_child(custom_picker)
	mouse_popup.add_child(mouse_picker)
	self.add_child(joypad_popup)
	self.add_child(mouse_popup)
	custom_picker.connect("lose_focus", self, "_close_joypad_popup")
	joypad_popup.connect("popup_hide", self, "_close_joypad_popup")
	mouse_popup.connect("popup_hide", self, "_close_mouse_popup")
	mouse_picker.set_edit_alpha(false)
	mouse_picker.set_theme(blank_theme)
	

func _pressed():
	if joy_button_pressed || mouse_button_pressed:
		custom_picker.color = color
		for idx in range(presets.size()):  #todoSet a variable to the picker to use to remove redundancy
			custom_picker.add_preset(presets[idx])
		presets.resize(0)
		joypad_popup.popup_centered()
		joypad_popup.grab_focus() #To guarentee it gets the focus
#		hide()
		joy_button_pressed = false
		mouse_button_pressed = false
	else:
		mouse_picker.set_pick_color(color)
		for idx in range(presets.size()):
			mouse_picker.add_preset(presets[idx])
		mouse_popup.popup_centered()
#	hide()
	popup_opened = true
	
func _gui_input(event:InputEvent):
	if event.is_action("ui_accept") && event is InputEventJoypadButton:
		joy_button_pressed = true
	if event is InputEventMouseButton:
		if event.get_button_mask() & BUTTON_MASK_LEFT:
			mouse_button_pressed = true

func _close_joypad_popup(): #Just to help close the joypad picker
	color = custom_picker.color
	emit_signal("color_changed", color)
	if presets.size() == 0:
		presets = custom_picker.get_presets()
		custom_picker.erase_all_presets()
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
#	show()
	self.grab_focus() #FIX: Use set_focus_mode() to allow a control to get focus
	self.self_modulate = color
	popup_opened = false
