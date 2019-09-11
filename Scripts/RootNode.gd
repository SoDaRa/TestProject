extends Node

onready var PlayerCamera = get_node("Player/PlayerBody/Camera2D")
onready var main_level_rect = Rect2($Level.position, $Level.LEVEL_SIZE)
var mission_rect: Rect2
var curr_rect : Rect2
const ZOOM_FACTOR = 5.8/4000.0 #Just found this fraction works well for zoom outs
var self_paused = false
var on_mission = false #NOTE: Add to singleton
var pos_holder: Vector2
onready var MyOptionsMenu = get_node("OptionsLayer/OptionsMenu")

# Called when the node enters the scene tree for the first time.
func _ready():
	#Setup Player Camera
	curr_rect = main_level_rect
	fix_camera_bounds()
	
	$Player.set_new_bounds(curr_rect, $Level/PlayerStart.position)
	
	var err = 0
	err = $Player/PlayerTrail.connect("main_empty", $Level, "_on_Trail_main_empty")
	assert(err == 0)
	err = $Level.connect("update_started", $Player/PlayerTrail, "swap_to_buffer")
	assert(err == 0)
	err = $Level.connect("update_completed", $Player/PlayerTrail, "hide_trail")
	assert(err == 0)
	err = $Player.connect("painted", $Level, "_on_Player_paint")
	assert(err == 0)
	err = MyOptionsMenu.connect("bg_save_requested", $Level, "save_background")
	assert(err == 0)
	err = MyOptionsMenu.connect("mission_end_requested", self, "end_mission")
	assert(err == 0)
	curr_rect = main_level_rect
	$Level.set_process(true)
	$Mission.set_process(false)

func _input(event):
#	elif event.is_action("Dummy_Button") && Input.is_action_just_pressed("Dummy_Button"):
#		var new_type = $CanvasLayer/Colorblindness.Type
#		new_type += 1
#		new_type = wrapi(new_type, 0, 4)
#		$CanvasLayer/Colorblindness.set_type(new_type)
	if event.is_action("zoom_out"):
		if Input.is_action_just_pressed("zoom_out") && !get_tree().paused:
			get_tree().paused = true
			self_paused = true
			var zoom_scale = Vector2(curr_rect.size.x * ZOOM_FACTOR, curr_rect.size.y * ZOOM_FACTOR)
			var zoom_camera_pos = Vector2(curr_rect.position.x + curr_rect.size.x/2, curr_rect.position.y + curr_rect.size.y/2)
			PlayerCamera._tween_zoom(zoom_scale)
			PlayerCamera._tween_position(zoom_camera_pos)
			unfix_camera_bounds()
		elif Input.is_action_just_released("zoom_out") && get_tree().paused && self_paused:
			get_tree().paused = false
			self_paused = false
			PlayerCamera._reset()
			fix_camera_bounds() #BUG: Zooming out in mission locks camera in weird way
	if event.is_action("ui_end") && Input.is_action_just_pressed("ui_end") && !get_tree().paused:
		if !$DialogueLayer/DialogueUI.is_visible() && !$OptionsLayer/OptionsMenu.is_visible():
			get_tree().set_input_as_handled()
			$OptionsLayer/OptionsMenu.show()

func _on_MyMan_start_mission(m_overlay_path : String):
	mission_rect = $Mission.mission_start(m_overlay_path)
	pos_holder = $Player/PlayerBody.position
	$Player.set_new_bounds(mission_rect, $Mission.position + $Mission/PlayerStart.position)
	$Player/PlayerTrail.hide_trail()
	var err = 0
	err = $Player/PlayerTrail.connect("main_empty", $Mission, "_on_Trail_main_empty")
	$Player/PlayerTrail.disconnect("main_empty", $Level, "_on_Trail_main_empty")
	assert(err == 0)
	err = $Mission.connect("update_started", $Player/PlayerTrail, "swap_to_buffer")
	$Level.disconnect("update_started", $Player/PlayerTrail, "swap_to_buffer")
	assert(err == 0)
	err = $Mission.connect("update_completed", $Player/PlayerTrail, "hide_trail")
	$Level.disconnect("update_completed", $Player/PlayerTrail, "hide_trail")
	assert(err == 0)
	err = $Player.connect("painted", $Mission, "_on_Player_paint")
	$Player.disconnect("painted", $Level, "_on_Player_paint")
	assert(err == 0)
	curr_rect = mission_rect
	unfix_camera_bounds() #FIXME: Figure out how to scale camera into small space properly
	on_mission = true
	$Level.set_process(false)
	$Mission.set_process(true)
	MyOptionsMenu.in_mission = true
	
func end_mission():
	$Player.set_new_bounds(main_level_rect, pos_holder)
	var err = 0
	err = $Player/PlayerTrail.connect("main_empty", $Level, "_on_Trail_main_empty")
	$Player/PlayerTrail.disconnect("main_empty", $Mission, "_on_Trail_main_empty")
	assert(err == 0)
	err = $Level.connect("update_started", $Player/PlayerTrail, "swap_to_buffer")
	$Mission.disconnect("update_started", $Player/PlayerTrail, "swap_to_buffer")
	assert(err == 0)
	err = $Level.connect("update_completed", $Player/PlayerTrail, "hide_trail")
	$Mission.disconnect("update_completed", $Player/PlayerTrail, "hide_trail")
	assert(err == 0)
	err = $Player.connect("painted", $Level, "_on_Player_paint")
	$Player.disconnect("painted", $Mission, "_on_Player_paint")
	assert(err == 0)
	curr_rect = main_level_rect
	fix_camera_bounds()
	
	var glasses = $Mission.get_result()
	var new_texture = ImageTexture.new()
	new_texture.create_from_image(glasses)
	$Level/MyMan/Sprite/Glasses.texture = new_texture
	$Level/MyMan.mission_finished()
	on_mission = false
	$Level.set_process(true)
	$Mission.set_process(false)
	MyOptionsMenu.in_mission = false
	
func fix_camera_bounds():
	PlayerCamera.limit_top = curr_rect.position.y
	PlayerCamera.limit_bottom = curr_rect.end.y
	PlayerCamera.limit_left = curr_rect.position.x
	PlayerCamera.limit_right = curr_rect.end.x
	
func unfix_camera_bounds():
	PlayerCamera.limit_top = -1000000
	PlayerCamera.limit_bottom = 1000000
	PlayerCamera.limit_left = -1000000
	PlayerCamera.limit_right = 1000000
