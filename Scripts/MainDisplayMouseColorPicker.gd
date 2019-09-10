extends HBoxContainer

#Color data
var picker_color = Color(255, 0, 0, 255) setget set_pick_color, get_pick_color
var hue = 1.0
var saturation = 1.0
var value = 1.0

#For rotating the selector
var wheel_center: Vector2

#Node references
onready var CWheel: TextureRect = get_node("Display/ColorWheel")
onready var Sample: ColorRect = get_node("Display/Sample")
onready var SBar: ColorRect = get_node("Display/Sample/SaturationBar")
onready var VBar: ColorRect = get_node("Display/Sample/ValueBar")
onready var Preview: ColorRect = get_node("Preview")
onready var Selector: Sprite = get_node("Selector")

#Emitted signals
signal main_color_changed(new_color)
signal new_preset_selected(new_color)
signal lose_focus

const WHEEL_RADIUS = 207

# Called when the node enters the scene tree for the first time.
func _ready():
	self.grab_focus()
	picker_color = Color.from_hsv(hue,saturation,value)
	Sample.material.set_shader_param("picker_color", Color.from_hsv(hue, 1.0, 1.0))
	Preview.set_frame_color(picker_color)

	wheel_center = CWheel.rect_position + (CWheel.rect_size / 2) * CWheel.rect_scale

	Selector.position = polar2cartesian(WHEEL_RADIUS, 0) + wheel_center
	SBar.set_frame_color(picker_color.inverted())
	VBar.set_frame_color(picker_color.inverted())
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta): #Joypad axis are handled here instead of gui_input to make more fluid
	if self.has_focus():
		self.modulate = Color(1.0,1.0,1.0,1.0)
		if Input.get_connected_joypads().size() > 0:
			var update_needed = false
			#Color Wheel (Right stick)
			var rXAxis = Input.get_joy_axis(0, JOY_AXIS_2)
			var rYAxis = Input.get_joy_axis(0, JOY_AXIS_3)
			if abs(rXAxis) > .5 || abs(rYAxis) > .5:
				var joy_angle = rad2deg(atan2(rYAxis, rXAxis))
				hue = wrapf(joy_angle, 0, 360) / 360
				update_needed = true

				Selector.position = polar2cartesian(WHEEL_RADIUS, deg2rad(joy_angle)) + wheel_center

			#Saturation and Value (Left Stick)
			var lXAxis = Input.get_joy_axis(0, JOY_AXIS_0)
			var lYAxis = Input.get_joy_axis(0, JOY_AXIS_1)
			if abs(lXAxis) > .14:
				if lXAxis < 0 && saturation > 0:
					saturation -= 1.0/255.0
					if saturation < 0:
						saturation = 0.0
				elif lXAxis > 0 && saturation < 1.0:
					saturation += 1.0/255.0
					if saturation > 1.0:
						saturation = 1.0
				SBar.rect_position.x = saturation * 255
				update_needed = true

			if abs(lYAxis) > .14:
				if lYAxis < 0 && value < 1.0:
					value += 1.0/255.0
					if value > 1.0:
						value = 1.0
				elif lYAxis > 0 && value > 0.0:
					value -= 1.0/255.0
					if value < 0:
						value = 0.0
				VBar.rect_position.y = (1.0 - value) * 255
				update_needed = true

			#Set new color
			if update_needed == true:
				_update_color()

	else:
		self.modulate = Color(1.0,1.0,1.0,0.5)
	Sample.material.set_shader_param("picker_color", Color.from_hsv(hue, 1.0, 1.0))


func _gui_input(event):
	if InputMap.action_has_event("ui_accept", event):
		emit_signal("new_preset_selected", picker_color)
	if InputMap.action_has_event("ui_cancel", event):
		self.accept_event()
		emit_signal("lose_focus")

	if event is InputEventJoypadMotion:
		var update_needed = false
		#Wrap Around functionality
		if event.get_axis() == JOY_AXIS_0:
			if event.get_axis_value() < -0.65 && saturation == 0.0:
				saturation = 1.0
				update_needed = true
			elif event.get_axis_value() > 0.65 && saturation == 1.0:
				saturation = 0.0
				update_needed = true
		if event.get_axis() == JOY_AXIS_1:
			if event.get_axis_value() < -0.65 && value == 1.0:
				value = 0.0
				update_needed = true
			elif event.get_axis_value() > 0.65 && value == 0.0:
				value = 1.0
				update_needed = true

		if update_needed == true:
			_update_color()

func _update_color():
	picker_color = Color.from_hsv(hue,saturation,value)
	emit_signal("main_color_changed", picker_color)
	Sample.material.set_shader_param("picker_color", Color.from_hsv(hue, 1.0, 1.0))
	Preview.set_frame_color(picker_color)
	SBar.set_frame_color(picker_color.inverted())
	VBar.set_frame_color(picker_color.inverted())

func set_pick_color(new_color: Color):
	picker_color = new_color
	hue = picker_color.h
	saturation = picker_color.s
	value = picker_color.v

	#Move everything into place in the display
	SBar.rect_position.x = saturation * 255
	SBar.set_frame_color(picker_color.inverted())
	VBar.rect_position.y = (1.0 - value) * 255
	VBar.set_frame_color(picker_color.inverted())
	Selector.position = polar2cartesian(WHEEL_RADIUS, deg2rad(hue * 360)) + wheel_center
	Sample.material.set_shader_param("picker_color", Color.from_hsv(hue, 1.0, 1.0))
	Preview.set_frame_color(picker_color)

func get_pick_color() -> Color:
	return picker_color

func set_focus():
	self.grab_focus()

func _on_Sample_mouse_input(pos:Vector2):
	self.grab_focus()
	saturation = pos.x / 255
	value = 1.0 - (pos.y / 255)
	SBar.rect_position.x = pos.x
	VBar.rect_position.y = pos.y
	_update_color()
	pass # Replace with function body.

func _on_ColorWheel_wheel_mouse_input(angle):
	self.grab_focus()
	hue = wrapf(angle, 0, 360) / 360
	Selector.position = polar2cartesian(WHEEL_RADIUS, deg2rad(angle)) + wheel_center
	_update_color()
	pass # Replace with function body.
