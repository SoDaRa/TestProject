extends Camera2D

onready var tween = $CameraTween
var initial_pos = Vector2(0,0)
var initial_zoom = Vector2(1,1)
export var TWEEN_SPEED = 1.0

func _tween_zoom(new_zoom: Vector2):
	tween.interpolate_property(self, "zoom", null, new_zoom, TWEEN_SPEED, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()
	pass

func _tween_position(new_pos: Vector2): #NOTE: New_pos must be in global coordinate. Otherwise will be thrown way off
	self.drag_margin_h_enabled = false
	self.drag_margin_v_enabled = false
	
	var target_pos = get_parent().to_local(new_pos) #Convert the given point from global coordiate to a local coordinate
	tween.interpolate_property(self, "position", null, target_pos, TWEEN_SPEED, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()

func _reset(): #This must be called to put the camera back where it started
	self.drag_margin_h_enabled = true
	self.drag_margin_v_enabled = true
	self.position = initial_pos
	self.zoom = initial_zoom
	tween.remove_all()