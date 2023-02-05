extends Node

func round_to_dec(mumber: float, digit: int):
	return round(mumber * pow(10.0, digit)) / pow(10.0, digit)

func _process(_delta: float) -> void:
	var memory = float(OS.get_static_memory_usage()) / 1000000
	var fps = Engine.get_frames_per_second()
	
	DebugDraw.set_text("memory (mb)", round_to_dec(memory, 2))
	DebugDraw.set_text("fps", fps)
	
	if Input.is_key_pressed(KEY_1):
		Raycast.debug = !Raycast.debug
		
	if Input.is_key_pressed(KEY_2):
		Engine.max_fps = 10 if Engine.max_fps == 60 else 60
		
	if Input.is_key_pressed(KEY_0):
		Engine.time_scale = 0.1
	
	if Input.is_key_pressed(KEY_9):
		Engine.time_scale = 1
