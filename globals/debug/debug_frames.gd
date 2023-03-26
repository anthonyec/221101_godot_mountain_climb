extends Node

signal resized(min: int, max: int)
signal added()

@export var max_recording_size: int = 1024

var is_recording: bool = true
var frame_count: int = 0
var frames: Dictionary = {}

func _process(_delta: float) -> void:
	if not is_recording:
		return
		
	frame_count += 1
	
	var frame_keys = frames.keys()
	
	if frame_keys.size() > max_recording_size:
		var keys_at_state = frame_keys.slice(0, 1)
		
		for key in keys_at_state:
			frames.erase(key)
			resized.emit(frame_keys[0], frame_keys[0] + frame_keys.size() - 1)

func add(data: Dictionary) -> void:
	if not is_recording:
		return
	
	if not frames.has(frame_count):
		frames[frame_count] = []
	
	frames[frame_count].append(data)
	added.emit()
