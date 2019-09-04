extends HBoxContainer

#Color data
var color = Color(255, 0, 0, 255) setget set_pick_color, get_pick_color
var hue = 1.0
var saturation = 1.0
var value = 1.0

var wheel_center: Vector2 #Point to rotate the selector around

#Node references
onready var CWheel: TextureRect = get_node("Display/ColorWheel")
onready var Sample: ColorRect = get_node("Display/Sample")
onready var SBar: ColorRect = get_node("Display/Sample/SaturationBar")
onready var VBar: ColorRect = get_node("Display/Sample/ValueBar")
onready var Preview: ColorRect = get_node("VBoxContainer/Preview")
onready var Selector: Sprite = get_node("Selector")

#Emitted signals
signal main_color_changed(new_color)
signal new_preset_selected(new_color)
signal lose_focus

# Called when the node enters the scene tree for the first time.
func _ready():
	self.grab_focus()
	wheel_center = CWheel.rect_position + (CWheel.rect_size / 2) * CWheel.rect_scale
	_update_color()

# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta): #Joypad axis are handled here instead of gui_input to make more fluid
	if self.has_focus():
		var update_needed = false
		#Joypad Input Handler
		if Input.get_connected_joypads().size() > 0:
			#Right stick #TODO: Stick Switch Point
			var rXAxis = Input.get_joy_axis(0, JOY_AXIS_2)
			var rYAxis = Input.get_joy_axis(0, JOY_AXIS_3)
			#Hue/Color Wheel
			if abs(rXAxis) > .5 || abs(rYAxis) > .5:
				var joy_angle = rad2deg(atan2(rYAxis, rXAxis))
				hue = wrapf(joy_angle, 0, 360) / 360
				update_needed = true
			
			#Left Stick #TODO: Stick Switch Point
			var lXAxis = Input.get_joy_axis(0, JOY_AXIS_0)
			var lYAxis = Input.get_joy_axis(0, JOY_AXIS_1)
			#Saturation
			if abs(lXAxis) > .14:
				if lXAxis < 0 && saturation > 0:
					saturation -= 1.0/255.0
					if saturation < 0:
						saturation = 0.0
				elif lXAxis > 0 && saturation < 1.0:
					saturation += 1.0/255.0
					if saturation > 1.0:
						saturation = 1.0
				update_needed = true
			
			#Value (Left Stick)
			if abs(lYAxis) > .14:
				if lYAxis < 0 && value < 1.0:
					value += 1.0/255.0
					if value > 1.0:
						value = 1.0
				elif lYAxis > 0 && value > 0.0:
					value -= 1.0/255.0
					if value < 0:
						value = 0.0
				update_needed = true
		
		#Keyboard Input
		var hue_cw = Input.is_action_pressed("ccp_hue_cw")
		var hue_ccw = Input.is_action_pressed("ccp_hue_ccw")
		var sat_up = Input.is_action_pressed("ccp_saturation_up")
		var sat_down = Input.is_action_pressed("ccp_saturation_down")
		var val_up = Input.is_action_pressed("ccp_value_up")
		var val_down = Input.is_action_pressed("ccp_value_down")
		if hue_cw || hue_ccw || sat_up || sat_down || val_up || val_down: #This is just to make the code collapsable
			#Hue
			if hue_cw || hue_ccw:
				var new_hue = hue * 360
				if hue_cw:
					new_hue = new_hue + 1
				if hue_ccw:
					new_hue = new_hue - 1
				#Wrap to other side of circle (for convenience)
				if Input.is_action_just_pressed("ccp_hue_cw") && Input.is_action_just_pressed("ccp_hue_ccw"):
					new_hue = new_hue + 180
				if (hue_cw && Input.is_action_just_pressed("ccp_hue_ccw")) || (hue_ccw && Input.is_action_just_pressed("ccp_hue_cw")):
					new_hue = new_hue + 180
				
				hue = wrapf(new_hue, 0, 360) / 360
				update_needed = true
			
			#Saturation
			if sat_up || sat_down:
				if sat_up && saturation < 1.0:
					saturation = saturation + 1.0/255.0
					if saturation > 1.0:
						saturation = 1.0
				if sat_down && saturation > 0:
					saturation -= 1.0/255.0
					if saturation < 0:
						saturation = 0.0
				#Wrap around handlers
				if Input.is_action_just_pressed("ccp_saturation_up") && saturation == 1.0:
					saturation = 0.0
				if Input.is_action_just_pressed("ccp_saturation_down") && saturation == 0.0:
					saturation = 1.0
				update_needed = true
				
			#Value
			if val_up || val_down:
				if val_up && value < 1.0:
					value = value + 1.0/255.0
					if value > 1.0:
						value = 1.0
				if val_down && value > 0:
					value -= 1.0/255.0
					if value < 0:
						value = 0.0
				#Wrap around handlers
				if Input.is_action_just_pressed("ccp_value_up") && value == 1.0:
					value = 0.0
				if Input.is_action_just_pressed("ccp_value_down") && value == 0.0:
					value = 1.0
				update_needed = true
		
		#Set new color
		if update_needed == true:
			_update_color()


func _gui_input(event):
	if event.is_action("ui_accept") && Input.is_action_just_pressed("ui_accept"):
		emit_signal("new_preset_selected", color)
		accept_event()
	if event.is_action("ui_cancel") && Input.is_action_just_pressed("ui_cancel"):
		accept_event()
		emit_signal("lose_focus")

	if event is InputEventJoypadMotion:
		var update_needed = false
		#Wrap Around functionality for joypad #TODO: Stick Switch Point
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

func _notification(what):
	match(what):
		NOTIFICATION_FOCUS_ENTER:
			self.modulate = Color(1.0,1.0,1.0,1.0)
		NOTIFICATION_FOCUS_EXIT:
			self.modulate = Color(1.0,1.0,1.0,0.5)


func _update_color():
	color = Color.from_hsv(hue,saturation,value)
	emit_signal("main_color_changed", color)
	
	#Update Display
	Sample.material.set_shader_param("picker_color", Color.from_hsv(hue, 1.0, 1.0))
	Preview.set_frame_color(color)
	
		
	SBar.set_frame_color(color.inverted())
	VBar.set_frame_color(color.inverted())
	
	Selector.position = polar2cartesian(210, deg2rad(hue * 360)) + wheel_center #NOTE 207 is center of ring distance from center at (1,1) scale
	SBar.rect_position.x = saturation * 255
	VBar.rect_position.y = (1.0 - value) * 255
	

func set_pick_color(new_color: Color):
	hue = new_color.h
	saturation = new_color.s
	value = new_color.v
	_update_color()

func get_pick_color() -> Color:
	return color

func set_focus():
	self.grab_focus()

func _on_Sample_mouse_input(pos:Vector2):
	self.grab_focus()
	saturation = pos.x / 255
	value = 1.0 - (pos.y / 255)
	SBar.rect_position.x = pos.x
	VBar.rect_position.y = pos.y
	_update_color()

func _on_ColorWheel_wheel_mouse_input(angle):
	self.grab_focus()
	hue = wrapf(angle, 0, 360) / 360
	Selector.position = polar2cartesian(207, deg2rad(angle)) + wheel_center
	_update_color()