extends Control
#This controls is primarily made to link together the Main display and the preset buttons, as well as bridge this scene to the other scenes.

#The selected color of this picker. This is what is shown in the preview pane
export var picker_color = Color(255, 0, 0, 255) setget set_pick_color, get_pick_color 
var preset_colors = [] setget add_preset, get_presets
onready var PresetBar: HBoxContainer = get_node("VBox/PresetBar")
onready var MainDisplay: HBoxContainer = get_node("VBox/Main")
var preset_color_button_array = []
const PRESET_MAX = 10

signal color_changed(new_color)
signal lose_focus

func _ready():
	for index in range(PRESET_MAX):
		preset_color_button_array.append(PresetBar.get_node(str(index))) #All but AddButton
	if MainDisplay.color != picker_color:
		MainDisplay.color = picker_color

#Public Functions
func set_pick_color(new_color, internal = false): #Internal is just to check if it's a call from inside the scene
	picker_color = new_color
	if internal:
		emit_signal("color_changed", picker_color)
	else:
		if MainDisplay != null: #Prevents writing before it's setup
			MainDisplay.color = picker_color

func get_pick_color() -> Color:
	return picker_color

func get_presets() -> PoolColorArray:
	var preset_pool = PoolColorArray(preset_colors)
	return preset_pool

func add_preset(new_color: Color):
	#If already at the max or color already in array, do nothing
	if preset_colors.size() != PRESET_MAX && preset_colors.find(new_color) == -1: 
		preset_colors.push_back(new_color)

		#Hide AddButton if full of presets
		if preset_colors.size() == PRESET_MAX:
			$VBox/PresetBar/AddButton.hide()

		#Change main display's bottom focus
		if preset_colors.size() >= 1:
			MainDisplay.focus_neighbour_bottom = NodePath("../PresetBar/0")

		preset_color_button_array[preset_colors.size()-1].modulate = new_color
		preset_color_button_array[preset_colors.size()-1].show()

func erase_preset(remove_preset: Color):
	var num = preset_colors.find(remove_preset) #Check to ensure the color is valid and find position
	if num != -1:
		self._on_preset_removed(remove_preset, num)

func erase_all_presets():
	for idx in range(preset_colors.size()):
		preset_color_button_array[idx].hide()

	if preset_colors.size() == PRESET_MAX:
		$VBox/PresetBar/AddButton.show()

	preset_colors.clear()

#Private Functions
func _on_Main_main_color_changed(new_color): #When display updated, update color and emit signal
	self.set_pick_color(new_color, true)

func _on_Main_new_preset_selected(new_color: Color):
	add_preset(new_color)

func _on_preset_selected(selected_color: Color): #When a preset is selected, update the color, display and emit signal
	self.set_pick_color(selected_color, true)
	MainDisplay.color = selected_color
	MainDisplay.grab_focus()

func _on_preset_removed(removed_color: Color, index: int):
	while index != preset_colors.size() - 1: #Operate on all but the last one
		preset_color_button_array[index].modulate = preset_color_button_array[index+1].modulate #Move colors up the line
		index += 1

	preset_color_button_array[index].hide() #Hide the last one
	if preset_colors.size() == PRESET_MAX:  #Show AddButton if it was hidden
		$VBox/PresetBar/AddButton.show()
	preset_colors.erase(removed_color)  #Remove the preset
	
	#Change main display's bottom focus if nothing else left
	if preset_colors.size() == 0:
		MainDisplay.focus_neighbour_bottom = NodePath("../PresetBar/AddButton")

	if self.get_focus_owner() == null:  #Focus is usually lost if done on the last one, so best to put it back on the AddButton
		$VBox/PresetBar/AddButton.grab_focus()

func _on_AddButton_pressed():
	add_preset(picker_color)
	if get_focus_owner() == null:  #Prevents losing the focus completely if AddButton was hidden
		get_node("VBox/PresetBar/9").grab_focus()

func _on_lose_focus():  #HACK: Have to connect to something to help get the focus off it
	emit_signal("lose_focus")
