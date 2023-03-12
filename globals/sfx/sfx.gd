extends Node3D

const RANDOM_NUMBER_PLACEHOLDER = "[%n]"

@export var sounds_directory: String = "res://globals/sfx/audio"

var number_suffix_regex: RegEx = null
var is_loaded: bool = false
var sounds: Dictionary = {}

# TODO: Add all the audio params here.
class Parameters extends RefCounted:
	# General params
	var bus: String = "Master"
	var volume_db: float = 0
	var pitch_scale: float = 1
	var loop: bool = false # Custom param
	
	# 3D only params
	var attenuation_filter_cutoff_hz: int = 20500
	var max_db: float = 0
	var max_distance: float = 30
	
	# 2D only params
	var max_polyphony: int = 1
	
func _ready() -> void:
	number_suffix_regex = RegEx.new()
	number_suffix_regex.compile("\\d+$")
		
	var sound_files = get_files_with_extension(sounds_directory, ".wav")
	
	if sound_files.is_empty():
		push_warning("SFX: Warning, no sound files were found.")
		
	sounds = build_sound_library_from_files(sound_files)
	is_loaded = true

func create_player_3d(sound_name: String, parameters: Parameters = Parameters.new()) -> AudioStreamPlayer3D:
	if !sounds.has(sound_name.trim_suffix(RANDOM_NUMBER_PLACEHOLDER)):
		push_error("SFX: The sound called '", sound_name, "' does not exist.")
		return AudioStreamPlayer3D.new()
		
	var file = get_sound_file(sound_name)
	var player: AudioStreamPlayer3D = spawn_player(file, parameters)
	
	return player
	
func play_at_location(sound_name: String, location: Vector3, parameters: Parameters = Parameters.new()) -> AudioStreamPlayer3D:
	var player = create_player_3d(sound_name, parameters)
	
	add_child(player)
	player.global_transform.origin = location
	player.play()
	
	return player
	
func play_attached_to_node(sound_name: String, node: Node3D, parameters: Parameters = Parameters.new()) -> AudioStreamPlayer3D:
	var player = create_player_3d(sound_name, parameters)
	
	node.add_child(player)
	player.play()
	
	return player
	
func play_everywhere(sound_name: String, parameters: Parameters = Parameters.new()) -> AudioStreamPlayer2D:
	if !sounds.has(sound_name.trim_suffix(RANDOM_NUMBER_PLACEHOLDER)):
		push_error("SFX: The sound called '", sound_name, "' does not exist.")
		return AudioStreamPlayer2D.new()
		
	var sound_file = get_sound_file(sound_name)
	var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	
	var _signal = player.connect("finished", func(): player.queue_free())
	
	player.set_process_mode(PROCESS_MODE_ALWAYS)
	player.stream = sound_file
	player.bus = parameters.bus
	player.volume_db = parameters.volume_db
	player.pitch_scale = parameters.pitch_scale
	player.max_polyphony = parameters.max_polyphony
	
	add_child(player)
	player.play()
	
	return player

func spawn_player(stream: AudioStream, parameters: Parameters = Parameters.new()) -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	var timer: SceneTreeTimer = get_tree().create_timer(float(stream.get_length()), false)
	
	player.stream = stream
	player.bus = parameters.bus
	player.attenuation_filter_cutoff_hz = parameters.attenuation_filter_cutoff_hz
	player.volume_db = parameters.volume_db
	player.max_db = parameters.max_db
	player.max_distance = parameters.max_distance
	player.pitch_scale = parameters.pitch_scale
	
	# TODO: Loop seems to be broken. Fix it one day.
	if parameters.loop:
		var _signal = timer.connect("timeout", on_timer_end.bind(player))
	
	return player
	
func on_timer_end(player: AudioStreamPlayer3D) -> void:
	player.queue_free()

func get_sound_file(sound_name: String) -> AudioStream:
	var file: AudioStream = null
	
	if sound_name.ends_with(RANDOM_NUMBER_PLACEHOLDER):
		var sound_collection_name = sound_name.trim_suffix(RANDOM_NUMBER_PLACEHOLDER)
		var number_of_sound_files = sounds[sound_collection_name].size()
		var random_index = floor(randf_range(0, number_of_sound_files))
		
		file = sounds[sound_collection_name][random_index] as AudioStream
	else:
		file = sounds[sound_name] as AudioStream
		
	return file
	
func build_sound_library_from_files(sound_files: Array[String]) -> Dictionary:
	var collection: Dictionary = {}
	
	for sound_file in sound_files:
		# Turn the full sound file path int oa name, e.g "res://globals/sfx/audio/physics/glass/sound.wav" -> "physics/glass/sound".
		var sound_name = sound_file.replace(sounds_directory, "").trim_prefix("/").replace("." + sound_file.get_extension(), "")
		var number_suffix_match = number_suffix_regex.search(sound_name)
		
		if number_suffix_match:
			var number = number_suffix_match.get_string()
			var sound_collection_name = sound_name.trim_suffix(number)
			
			if not collection.has(sound_collection_name):
				collection[sound_collection_name] = []

			collection[sound_collection_name].append(load(sound_file))
		
		# Add all sounds to the collection, even if they contain a number as
		# this will be faster to lookup (probably). Though it does waste a 
		# bit of memory.
		collection[sound_name] = load(sound_file)
		
	return collection
	
# Perform a recursive scan of a directory and return all the files of a certain type.
func get_files_with_extension(path: String, file_extension: String) -> Array[String]:
	var directory = DirAccess.open(path)
	
	if directory == null:
		push_error("Failed to open directory: " + path)
		return []
		
	directory.list_dir_begin()
	
	var results: Array[String] = []
	var file_name = directory.get_next()
	
	while file_name != "":
		if directory.current_is_dir():
			var recursive_results = get_files_with_extension(path + "/" + file_name, file_extension)
			results.append_array(recursive_results)
		
		if not directory.current_is_dir():
			# When the game is exported, assets no longer exists in their original file form and are instead
			# their binary data is stored in a ".import" file. So we look for those, and then use the original
			# file name by removing the ".import" extension. Godot `load` will work with normal file extensions.
			# https://github.com/godotengine/godot/issues/18390#issuecomment-384041374
			if file_name.ends_with(file_extension + ".import"):
				var file_path_without_import = path + "/" + file_name.replace(".import", "")
				results.append(file_path_without_import)
				
		file_name = directory.get_next()
	
	return results
