extends Camera3D

signal select_into_world(position)

@export var target_path: NodePath
@export var orbit: bool
@export var look_at: bool

var speed_slow: float = 2
var speed_normal: float = 15
var speed: float = speed_normal
var rotate_speed: float = 5
var is_aiming: bool = false
var mouse_relative_position: Vector2
var mouse_sensitivity: float = 1

var target_object: Node = null
var target_distance: float = 5
var target_position: Vector3 = Vector3.ZERO

var keys = {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"camera_slow_mod": KEY_SHIFT,
	"change_projection": KEY_P,
	"save": KEY_I,
	"load": KEY_L
}

var mouseButtons = {
	"camera_aim": MOUSE_BUTTON_RIGHT
}

func add_input_actions():
	for key in keys:
		var eventKey = InputEventKey.new()
		eventKey.set_keycode(keys[key])
		InputMap.add_action(key)
		InputMap.action_add_event(key, eventKey)
		
	for mouseButton in mouseButtons:
		var eventButton = InputEventMouseButton.new()
		eventButton.button_index = mouseButtons[mouseButton]
		InputMap.add_action(mouseButton)
		InputMap.action_add_event(mouseButton, eventButton)

func _ready():
	load_camera()
	add_input_actions()

	target_object = get_node_or_null(target_path)
	
	if target_object != null and target_position != null:
		target_position = target_object.global_transform.origin
		target_distance = target_position.distance_to(self.global_transform.origin)

func _process(delta):
	if look_at and !is_aiming and !orbit:
		self.global_transform.origin.y = target_object.global_transform.origin.y + 8
		self.look_at_from_position(self.global_transform.origin, target_object.global_transform.origin, Vector3.UP)
		
	if (!is_aiming and !orbit):
		return
		
	var horizontal_axis = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var vertical_axis = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var camera_horizontal_axis = Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left")
	var camera_vertical_axis = Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up")

	if orbit:		
		self.translate(Vector3.RIGHT * delta * speed * horizontal_axis)
		self.translate(Vector3.DOWN * delta * speed * vertical_axis)
		# self.set_position(target_position * target_distance) # does not work yet
#		self.look_at(target_object.global_transform.origin, Vector3.UP) # TODO: Fix for Godot 4.x
	else:
		self.translate(Vector3.FORWARD * delta * speed * -vertical_axis)
		self.translate(Vector3.RIGHT * delta * speed * horizontal_axis)
		self.rotate_object_local(Vector3.RIGHT, -camera_vertical_axis * delta * rotate_speed)
		self.rotate(Vector3.UP, -camera_horizontal_axis * delta * rotate_speed)

		if is_aiming:
			self.rotate_object_local(Vector3.RIGHT, -floor(mouse_relative_position.y) * delta * mouse_sensitivity)
			self.rotate(Vector3.UP, -floor(mouse_relative_position.x) * delta * mouse_sensitivity)

			# Reset to zero because when mouse stops moving, relative position does
			# not always return to zero.
			# https://godotengine.org/qa/61349/how-to-detect-if-the-mouse-has-stopped-moving
			mouse_relative_position = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_relative_position = event.relative
		
	if event.is_action_pressed("ui_select"):
		select_into_world_space()
		
	if event.is_action_pressed("camera_slow_mod"):
		speed = speed_slow

	if event.is_action_released("camera_slow_mod"):
		speed = speed_normal

	if event.is_action_pressed("camera_aim"):
		is_aiming = true

	if event.is_action_released("camera_aim"):
		is_aiming = false
		
	if event.is_action_pressed("change_projection"):
		if self.projection == 0:
			self.projection = 1
			self.size = 20
		else:
			self.projection = 0
			self.size = 70
			
	if event.is_action_pressed("save"):
		self.save_camera()
		
	if event.is_action_pressed("load"):
		self.load_camera()

func get_save_filename() -> String:
	var scene_id = str(get_parent().get_instance_id())
	return "user://dev_cam_" + scene_id + ".save"

func save_camera():
	var save_game = FileAccess.open(get_save_filename(), FileAccess.WRITEREAD)
	
	var data = JSON.new().stringify({
		"pos_x": self.global_transform.origin.x,
		"pos_y": self.global_transform.origin.y,
		"pos_z": self.global_transform.origin.z,
		"rot_x": self.rotation.x,
		"rot_y": self.rotation.y,
		"rot_z": self.rotation.z
	})
	
	save_game.store_line(data);
	
	save_game.close()	

func load_camera():
	var save_game = FileAccess.open(get_save_filename(), FileAccess.READ)
	
	if not save_game.file_exists("user://dev_cam.save"):
		print("No saved data for dev cam")
		return
	
	while save_game.get_position() < save_game.get_length():
		var test_json_conv = JSON.new()
		test_json_conv.parse(save_game.get_line())
		var node_data = test_json_conv.get_data()
		self.global_transform.origin = Vector3(node_data["pos_x"], node_data["pos_y"], node_data["pos_z"])
		self.rotation = Vector3(node_data["rot_x"], node_data["rot_y"], node_data["rot_z"])
	
	save_game.close()
	
func select_into_world_space():
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			global_transform.origin, 
			global_transform.origin + (-global_transform.basis.z) * 1000
			)
		)
	
	if result:
		emit_signal("select_into_world", result.position)
