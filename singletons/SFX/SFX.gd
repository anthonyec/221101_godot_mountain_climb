extends Spatial

var loaded: bool = false
# Type of sounds variable is: "sound_name": ["sound_file.wav": AudioStream]
var sounds = {}

func _ready():
	print("SFX: Started")
		
	var current_directory_path = self.get_script().get_path()
	var base_directory_path = str(current_directory_path).replace("/SFX.gd", "/audio")
	var results = scan_directory(base_directory_path, ".wav")
	
	if results.empty():
		print("SFX: Warning, no sound files were found. These files were found instead: ")
		
		for result in scan_directory(base_directory_path):
			print("SFX: ", result)
	
	for result in results:
		# Remove the leading "/" and remove the trailing file extension including period.
		# E.g, the path "/physics/glass/sound.wav" will become "physics/glass/sound"
		var name = result.replace(base_directory_path, "").trim_prefix("/").replace(result.get_extension(), "").trim_suffix(".")
		
		# TODO: This is a lazy way to get the number at the end. The correct way would be to use
		# regex or going backwards of each char.
		var number = name.to_int()
		var name_without_number_suffix = name.replace(number, "")
		
		sounds[name] = [load(result)]
		
		# TODO: This does not supprt the number "0".
		if number != 0:
			if !sounds.has(name_without_number_suffix):
				sounds[name_without_number_suffix] = []
		
			sounds[name_without_number_suffix].append(load(result))
	
	loaded = true
	
func create(name: String, options = {}) -> AudioStreamPlayer3D:
	if !sounds.has(name.trim_suffix("{%n}")):
		print("SFX: The sound called '", name, "' does not exist.")
		return AudioStreamPlayer3D.new()
		
	var file = get_sound_file(name)
	var player: AudioStreamPlayer3D = spawn_player(file, options)
	
	return player
	
func	 play_attached_to_node(name: String, node: Spatial, options = {}) -> AudioStreamPlayer3D:
	if !sounds.has(name.trim_suffix("{%n}")):
		print("SFX: The sound called '", name, "' does not exist.")
		return AudioStreamPlayer3D.new()
		
	var file = get_sound_file(name)
	var player: AudioStreamPlayer3D = spawn_player(file, options)
	
	node.add_child(player)
	
	player.play()
	
	return player

func play_at_location(name: String, position: Vector3, options = {}) -> AudioStreamPlayer3D:
	if !sounds.has(name.trim_suffix("{%n}")):
		print("SFX: The sound called '", name, "' does not exist.")
		return AudioStreamPlayer3D.new()
		
	var file = get_sound_file(name)
	var player: AudioStreamPlayer3D = spawn_player(file, options)
	
	add_child(player)
	
	player.global_transform.origin = position
	player.play()
	
	return player

# TODO: Match all settings for everywhere to be the same as spatial sound.
func play_everywhere(name: String, options = {}) -> AudioStreamPlayer:
	if !sounds.has(name.trim_suffix("{%n}")):
		print("SFX: The sound called '", name, "' does not exist.")
		return AudioStreamPlayer.new()
		
	var file = get_sound_file(name)
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	var _signal = player.connect("finished", player, "queue_free")
	
	player.set_pause_mode(PAUSE_MODE_PROCESS)
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
	player.unit_db = 0
	player.max_db = 0
	player.max_distance = 30
	
	if options.has("bus"):
		player.bus = options["bus"]
	
	if options.has("unit_db"):
		player.unit_db = options["unit_db"]
		
	if options.has("max_distance"):
		player.max_distance = options["max_distance"]
		
	if options.has("max_db"):
		player.max_db = options["max_db"]
		
	if options.has("pitch_scale"):
		player.pitch_scale = options["pitch_scale"]
		
	if !options.has("loop"):
		var _signal = timer.connect("timeout", self, "on_timer_end", [player])
	
	return player
	
func get_sound_file(name: String) -> AudioStream:
	var file: AudioStream = null
	
	if name.ends_with("{%n}"):
		var name_without_template = name.trim_suffix("{%n}")
		var number_of_sound_files = sounds[name_without_template].size()
		var random_index = floor(rand_range(0, number_of_sound_files))

		file = sounds[name_without_template][random_index] as AudioStream
	else:
		file = sounds[name][0] as AudioStream
		
	return file
	
func scan_directory(path: String, fileNameEndsWith: String = ""):
	var results = []
	var directory = Directory.new()

	if directory.open(path) == OK:
		directory.list_dir_begin(true, true)

		var file_name = directory.get_next()
		
		while file_name != "":
			if directory.current_is_dir():
				var directory_path_to_scan = path + "/" + file_name
				var recursive_results = scan_directory(directory_path_to_scan, fileNameEndsWith)
				results.append_array(recursive_results)
			else:
				if fileNameEndsWith == "":
					results.append(path + "/" + file_name)
				elif file_name.ends_with(fileNameEndsWith + ".import"):
					# When the game is exported, assets no longer exists in their original file form and are instead
					# their binary data is stored in a ".import" file. So we look for those, and then use the original
					# file name by removing the ".import" extension. Godot `load` will work with normal file extensions.
					# https://github.com/godotengine/godot/issues/18390#issuecomment-384041374
					results.append(path + "/" + file_name.replace(".import", ""))
				
			file_name = directory.get_next()
			
	return results
