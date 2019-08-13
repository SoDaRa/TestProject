extends RigidBody2D

onready var home = self.position
var player_in_range = false
var quest_complete = false
var my_font: DynamicFont
var dialogue_ui

func _ready():
	my_font = DynamicFont.new()
	my_font.font_data = load("res://Comfortaa-Bold.ttf")
	my_font.size = 64

func _draw():
	#This ensures the string is drawn upright
	var g_transform = Transform2D(-1 * deg2rad(self.rotation_degrees), get_viewport_rect().position) 
	draw_set_transform_matrix(g_transform)
	if player_in_range && !quest_complete:
		self.draw_string(my_font, Vector2(0, -70), "!")
	elif player_in_range && quest_complete:
		self.draw_string(my_font, Vector2(-25,-70), "...")

# warning-ignore:unused_argument
func _process(delta):
	if player_in_range:
		update() #This is just to update the transform
	if dialogue_ui == null:
		dialogue_ui = get_tree().get_nodes_in_group("Dialogue")[0]


func _unhandled_input(event):
	#TODO: Only enable when visible enough. Should it be a signal?
	if event.is_action("interact") && Input.is_action_just_pressed("interact") && player_in_range == true: 
		dialogue_ui.get_child(0).show_dialogue($Dialogue, self) 
		quest_complete = true

func _integrate_forces(state: Physics2DDirectBodyState):
	if self.position.distance_to(home) > 100:
		state.apply_central_impulse(self.position.direction_to(home) * self.position.distance_to(home) * .3)

func _on_Area2D_body_entered(body):
	if body.get("name") == "Player": #NOTE: Player must be named Player to work!!
		player_in_range = true #TODO: Add an ! and ... sprite to NPC to show they are able to be talked to.
		update()

func _on_Area2D_body_exited(body):
	if body.get("name") == "PlayerBody":
		player_in_range = false
		update()
