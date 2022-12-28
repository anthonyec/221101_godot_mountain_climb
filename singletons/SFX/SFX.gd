extends Node3D

var loaded: bool = false

# Type/shape of the sounds dictionary is: "sound_name": ["sound_file.wav": AudioStream]
var sounds: Dictionary = {}

func _ready():
	var current_directory_path = self.get_script().get_path()
	var base_directory_path = str(current_directory_path).replace("/SFX.gd", "/audio")
	var results = scan_directory(base_directory_path, ".wav")
	
	if results.is_empty():
		push_warning("SFX: Warning, no sound files were found.")
		
		for result in scan_directory(base_directory_path):
			push_warning("SFX: Non-sound file found: ", result)
			
	for result in results:
		# Remove the leading "/" and remove_at the trailing file extension including period.
		# E.g, the path "/physics/glass/sound.wav" will become "physics/glass/sound"
		var sound_name = result.replace(base_directory_path, "").trim_prefix("/").replace(result.get_extension(), "").trim_suffix(".")
		
		# TODO: This is a lazy way to get the number at the end. The correct way would be to use
		# regex or going backwards of each char.
		var number = sound_name.to_int()
		var sound_name_without_number_suffix = sound_name.replace(str(number), "")
		
		sounds[sound_name] = [load(result)]
		
		# TODO: This does not supprt the number "0".
		if number != 0:
			if !sounds.has(sound_name_without_number_suffix):
				sounds[sound_name_without_number_suffix] = []
		
			sounds[sound_name_without_number_suffix].append(load(result))
	
	loaded = true
	
func create(sound_name: String, options = {}) -> AudioStreamPlayer3D:
	if !sounds.has(sound_name.trim_suffix("{%n}")):
		push_error("SFX: The sound called '", sound_name, "' does not exist.")
		return AudioStreamPlayer3D.new()
		
	var file = get_sound_file(sound_name)
	var player: AudioStreamPlayer3D = spawn_player(file, options)
	
	return player
	
func play_attached_to_node(sound_name: String, node: Node3D, options = {}) -> AudioStreamPlayer3D:
	if !sounds.has(sound_name.trim_suffix("{%n}")):
		push_error("SFX: The sound called '", sound_name, "' does not exist.")
		return AudioStreamPlayer3D.new()
		
	var file = get_sound_file(sound_name)
	var player: AudioStreamPlayer3D = spawn_player(file, options)
	
	node.add_child(player)
	
	player.play()
	
	return player

func play_at_location(sound_name: String, position_in_world: Vector3, options = {}) -> AudioStreamPlayer3D:
	if !sounds.has(sound_name.trim_suffix("{%n}")):
		push_error("SFX: The sound called '", sound_name, "' does not exist.")
		return AudioStreamPlayer3D.new()
		
	var file = get_sound_file(sound_name)
	var player: AudioStreamPlayer3D = spawn_player(file, options)
	
	add_child(player)
	
	player.global_transform.origin = position_in_world
	player.play()
	
	return player

# TODO: Match all settings for everywhere to be the same as spatial sound.
func play_everywhere(sound_name: String, options = {}) -> AudioStreamPlayer:
	if !sounds.has(sound_name.trim_suffix("{%n}")):
		push_error("SFX: The sound called '", sound_name, "' does not exist.")
		return AudioStreamPlayer.new()
		
	var file = get_sound_file(sound_name)
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	var _signal = player.connect("finished",Callable(player,"queue_free"))
	
	player.set_process_mode(PROCESS_MODE_ALWAYS)
	player.stream = file
	
	if options.has("bus"):
		player.bus = options["bus"]
	
	if options.has("volume_db"):
		player.volume_db = options["volume_db"]
	
	add_child(player)
	player.play()
	
	return player

func on_timer_end(player: AudioStreamPlayer3D) -> void:
	player.queue_free()

func spawn_player(file: AudioStream, options = {}) -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	var timer: SceneTreeTimer = get_tree().create_timer(float(file.get_length()), false)
	
	player.attenuation_filter_cutoff_hz = 20500
	player.stream = file
	player.volume_db = 0
	player.max_db = 0
	player.max_distance = 30
	
	if options.has("bus"):
		player.bus = options["bus"]
	
	if options.has("volume_db"):
		player.volume_db = options["volume_db"]
		
	if options.has("max_distance"):
		player.max_distance = options["max_distance"]
		
	if options.has("max_db"):
		player.max_db = options["max_db"]
		
	if options.has("pitch_scale"):
		player.pitch_scale = options["pitch_scale"]
		
	if !options.has("loop"):
		var _signal = timer.connect("timeout",Callable(self,"on_timer_end").bind(player))
	
	return player
	
func get_sound_file(sound_name: String) -> AudioStream:
	var file: AudioStream = null
	
	if sound_name.ends_with("{%n}"):
		var sound_name_without_template = sound_name.trim_suffix("{%n}")
		var number_of_sound_files = sounds[sound_name_without_template].size()
		var random_index = floor(randf_range(0, number_of_sound_files))

		file = sounds[sound_name_without_template][random_index] as AudioStream
	else:
		file = sounds[sound_name][0] as AudioStream
		
	return file
	
func scan_directory(path: String, fileNameEndsWith: String = ""):	
	var directory = DirAccess.open(path)
	
	if directory == null:
		push_error("SFX: Failed to open path: " + path)
		return []

	var results = []

	directory.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	var file_name = directory.get_next()

	while file_name != "":
		if directory.current_is_dir():
			var directory_path_to_scan = path + "/" + file_name
			var recursive_results = scan_directory(directory_path_to_scan, fileNameEndsWith)

			results.append_array(recursive_results)
		else:
			if fileNameEndsWith == "":
				# TODO: Why is this `file_path` var not used?
				var _file_path = path + "/" + file_name
				results.append(path)
			elif file_name.ends_with(fileNameEndsWith + ".import"):
				# When the game is exported, assets no longer exists in their original file form and are instead
				# their binary data is stored in a ".import" file. So we look for those, and then use the original
				# file name by removing the ".import" extension. Godot `load` will work with normal file extensions.
				# https://github.com/godotengine/godot/issues/18390#issuecomment-384041374
				var file_path_without_import = path + "/" + file_name.replace(".import", "")
				results.append(file_path_without_import)

		file_name = directory.get_next()

	return results
