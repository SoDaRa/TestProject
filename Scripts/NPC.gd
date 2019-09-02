extends RigidBody2D

onready var home = self.position
var player_in_range = false
var mission_accepted = false
var mission_completed = false
var mission_overlay_path = "res://Sprites/MissionBG.png"
var my_font: DynamicFont
var dialogue_ui: Panel
var text_tween: Tween	
#Could have had tween node in the NPC scene to do the same thing, but referencing the one in the ui guarentees a consistent reference
#if this NPC doesn't need a tween
var chars_per_sec = 50.0
var in_choice = false

signal start_mission(overlay_path)


func _ready():
	my_font = DynamicFont.new()
	my_font.font_data = load("res://Comfortaa-Bold.ttf")
	my_font.size = 64
	my_font.outline_color = Color(0,0,0,1)
	my_font.outline_size = 5
	set_process(false)
	set_process_input(false)

func _draw():
	#This ensures the string is drawn upright
	var g_transform = Transform2D(-1 * deg2rad(self.rotation_degrees), get_viewport_rect().position) 
	draw_set_transform_matrix(g_transform)
	if player_in_range && !mission_completed:
		self.draw_string(my_font, Vector2(0, -70), "!")
	elif player_in_range && mission_completed:
		self.draw_string(my_font, Vector2(-25,-70), "...")

# warning-ignore:unused_argument
func _process(delta):
	if player_in_range:
		update() #This is just to update the transform


func _input(event):
	#TODO: Only enable when visible enough. Should it be a signal?
	if event.is_action("interact") && Input.is_action_just_pressed("interact") && player_in_range == true && dialogue_ui == null: 
		$Dialogue.start_dialogue() 
		return
	
	if $Dialogue.in_dialogue == true:
		if (event.is_action("ui_accept") && Input.is_action_just_pressed("ui_accept") || \
		   event.is_action("interact") && Input.is_action_just_pressed("interact")) && !in_choice:
			if text_tween.is_active() == false:
				$Dialogue.next_dialogue()
			else:
# warning-ignore:return_value_discarded
				text_tween.seek(text_tween.get_runtime())


func _integrate_forces(state: Physics2DDirectBodyState):
	if self.position.distance_to(home) > 100:
		state.apply_central_impulse(self.position.direction_to(home) * self.position.distance_to(home) * .3)

func _on_Area2D_body_entered(body):
	if body.get("name") == "PlayerBody": #NOTE: Player's body must be named PlayerBody to work!!
		player_in_range = true
		set_process(true)			#To allow it to update the mark over it's head
		set_process_input(true)
		update()

func _on_Area2D_body_exited(body):
	if body.get("name") == "PlayerBody":
		player_in_range = false
		set_process(false)
		set_process_input(false)
		update()

func mission_finished():
	mission_completed = true
	player_in_range = true
	set_process(true)			#To allow it to update the mark over it's head
	set_process_input(true)
	update()
	$Dialogue.start_dialogue()

func _on_Dialogue_Started():
	get_tree().paused = true
	dialogue_ui = get_tree().get_nodes_in_group("Dialogue")[0]
	dialogue_ui.show()
	text_tween = dialogue_ui.get_node("Dialogue/Text/TextTween")
	assert(text_tween != null)


func _on_Dialogue_Next(ref, actor, d_text):
#	print("Dialogue ref ", ref)
	if ref == "Accept":
		mission_accepted = true
	display_dialogue(actor, d_text)

#This is so I can later make NPC a more abstract class so this general functionality can be inherit and specific stuff can be hard coded
func display_dialogue(actor, d_text):
	dialogue_ui.get_node("Dialogue").show()
	dialogue_ui.get_node("Choices").hide()
	dialogue_ui.get_node("Dialogue/Name").text = actor
	dialogue_ui.get_node("Dialogue/Text").text = d_text
	var tween_length = float(d_text.length()) / chars_per_sec
	var err
	err = text_tween.interpolate_property(dialogue_ui.get_node("Dialogue/Text"), "visible_characters", 0, d_text.length(), tween_length, \
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	assert(err == true)
	err = text_tween.start()
	assert(err == true)


func _on_Dialogue_Ended():
	if mission_accepted:
		emit_signal("start_mission", mission_overlay_path)
	dialogue_ui.hide()
	dialogue_ui = null		#Remove attachments to dialogue gui
	text_tween = null
	get_tree().paused = false
#	mission_completed = true


func _on_Dialogue_Conditonal_Data_Needed(ref):
	print(ref)
	if !mission_completed:
		$Dialogue.send_conditonal_data({"mission_status" : "not completed"})
	else:
		if mission_accepted == true: #FIXME: Use a different variable for this. Currently here to decide if the mission was just done or not.
			$Dialogue.send_conditonal_data({"mission_status" : "just completed"})
			mission_accepted = false
		else:
			$Dialogue.send_conditonal_data({"mission_status" : "completed"})


func _on_Dialogue_Choice_Next(ref, choices):
#	print("Choice ref: ", ref)
	dialogue_ui.get_node("Dialogue").hide()
	dialogue_ui.get_node("Choices").show()
	
	for i in dialogue_ui.get_node("Choices").get_children():
		i.free()
	
	for i in range(0, choices.size()):
		var newButton = Button.new()
		newButton.text = choices[i].Dialogue
		newButton.connect("pressed", self, "_on_choice_pressed", [i])
		newButton.disabled = !choices[i]["PassCondition"] #NOTE: May change this to hide disabled options
		newButton.hint_tooltip = choices[i]["ToolTip"]
		newButton.theme = load("res://Themes_Shaders/ChoiceButtonTheme.tres")
		dialogue_ui.get_node("Choices").add_child(newButton)
		if newButton.get_focus_owner() == null:
			newButton.grab_focus()
		newButton.set_anchors_preset(Control.PRESET_CENTER)
		newButton.rect_min_size.y = dialogue_ui.get_node("Choices").rect_size.y / choices.size()
	in_choice = true

func _on_choice_pressed(id):
	$Dialogue.next_dialogue(id)
	in_choice = false