extends Node

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_0):
		Engine.time_scale = 0.05
	
	if Input.is_key_pressed(KEY_9):
		Engine.time_scale = 1
