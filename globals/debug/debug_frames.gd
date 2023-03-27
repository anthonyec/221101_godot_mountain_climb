extends Node

const TITLE_KEY = "_title"

signal resized(min: int, max: int)
signal added()

@export var max_recording_size: int = 1024
@export var is_recording: bool = true

var frames: Dictionary = {}

func _ready() -> void:
	added.connect(_on_data_added)

func _on_data_added() -> void:
	var frame_keys = frames.keys()
	
	if frame_keys.size() > max_recording_size:
		var keys_at_state = frame_keys.slice(0, 1)
		
		for key in keys_at_state:
			frames.erase(key)
			resized.emit(frame_keys[0], frame_keys[0] + frame_keys.size() - 1)

func add(data: Dictionary) -> void:
	if not is_recording:
		return
		
	var count = Engine.get_frames_drawn()
	
	if not frames.has(count):
		frames[count] = []
	
	frames[count].append(data)
	added.emit()
	
func record(title: String, data: Dictionary = {}) -> void:
	if not is_recording:
		return
		
	var count = Engine.get_frames_drawn()
	
	if not frames.has(count):
		frames[count] = []
	
	data[TITLE_KEY] = title
	
	frames[count].append(data)
	added.emit()
	
func get_all() -> Array[Dictionary]:
	var keys = frames.keys()
	
	return keys.map(func(key):
		return frames[key]
	)

func reset() -> void:
	frames = {}
