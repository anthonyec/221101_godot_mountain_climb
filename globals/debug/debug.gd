extends Node

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_1):
		Raycast.debug = !Raycast.debug
		
	if Input.is_key_pressed(KEY_2):
		Engine.max_fps = 10 if Engine.max_fps == 60 else 60
		
	if Input.is_key_pressed(KEY_0):
		Engine.time_scale = 0.05
	
	if Input.is_key_pressed(KEY_9):
		Engine.time_scale = 1
