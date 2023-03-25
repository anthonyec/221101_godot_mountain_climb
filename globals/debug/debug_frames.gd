extends Node

signal resized(min: int, max: int)
signal added()

var is_recording: bool = false
var frame_count: int = 0
var frames: Dictionary = {}

func _process(_delta: float) -> void:
	DebugDraw.set_text("Recording frames: ", is_recording)
	DebugDraw.set_text("Recording size: ", frames.size())
	
	if not is_recording:
		return
		
	frame_count += 1
	
	var frame_keys = frames.keys()
	
	if frame_keys.size() > 1024:
		var keys_at_state = frame_keys.slice(0, 1)
		
		for key in keys_at_state:
			frames.erase(key)
			resized.emit(frame_keys[0], frame_keys[0] + frame_keys.size() - 1)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_record"):
		if not is_recording:
			frames.clear()
			
		is_recording = !is_recording

func add(data: Dictionary) -> void:
	if not is_recording:
		return
	
	if not frames.has(frame_count):
		frames[frame_count] = []
	
	frames[frame_count].append(data)
	added.emit()
