extends Panel

var dialogue_node = null
func _ready():
	hide()

# warning-ignore:unused_argument
func show_dialogue(dialogue, caller): #Caller will be what should supply information for conditionals
	show()
	get_tree().paused = true  #TODO Consider ways to have game coming to a screeching halt less annoying.
	$Button.grab_focus()
	dialogue_node = dialogue
	for c in dialogue_node.get_signal_connection_list("Dialogue_Ended"):
		if self == c.target:
			dialogue_node.start_dialogue()
			return
	dialogue_node.connect("Dialogue_Ended", self, "hide")
	dialogue_node.connect("Dialogue_Ended", self, "_on_dialogue_finished")
	dialogue_node.connect("Dialogue_Next", self, "_next_dialogue")
	#TODO Add conditional signal setup
	#TODO Add choice signal setup
	dialogue_node.start_dialogue()


func _on_Button_button_up(): #Won't fire if node is paused
	dialogue_node.next_dialogue()

# warning-ignore:unused_argument
func _next_dialogue(ref, name, text):
	$Name.text = name
	$Text.text = text
	#TODO: Display dialogue one character at a time. Probably by using Label's Visible Characters.

func _on_dialogue_finished():
	dialogue_node.disconnect("Dialogue_Ended", self, "hide")
	dialogue_node.disconnect("Dialogue_Ended", self, "_on_dialogue_finished")
	dialogue_node.disconnect("Dialogue_Next", self, "_next_dialogue")
	get_tree().paused = false
