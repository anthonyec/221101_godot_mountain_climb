extends Camera3D

var mouse_sensitivity: float = 0.2
var speed: float = 2

var is_aiming: bool = false
var mouse_relative_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	load_camera()

func _process(delta: float) -> void:
	var direction: Vector3 = Vector3.ZERO
	
	if Input.is_action_pressed("ui_left"):
		direction += Vector3.LEFT
		
	if Input.is_action_pressed("ui_right"):
		direction += Vector3.RIGHT
		
	if Input.is_action_pressed("ui_up"):
		direction += Vector3.FORWARD if not is_aiming else Vector3.UP
		
	if Input.is_action_pressed("ui_down"):
		direction += Vector3.BACK if not is_aiming else Vector3.DOWN
		
		
	translate(direction * speed * delta)
	
	if is_aiming:
		rotate_object_local(Vector3.RIGHT, -floor(mouse_relative_position.y) * delta * mouse_sensitivity)
		rotate(Vector3.UP, -floor(mouse_relative_position.x) * delta * mouse_sensitivity)
		mouse_relative_position = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_relative_position = event.relative
		
	if event.is_action_pressed("ui_focus_next"):
		is_aiming = true

	if event.is_action_released("ui_focus_next"):
		is_aiming = false
		
	if event.is_action_pressed("ui_accept"):
		save_camera()
		
	if event.is_action_pressed("ui_cancel"):
		load_camera()

func save_camera() -> void:
	var data = {
		"position": {
			"x": global_transform.origin.x,
			"y": global_transform.origin.y,
			"z": global_transform.origin.z,
		},
		"rotation": {
			"x": global_rotation.x,
			"y": global_rotation.y,
			"z": global_rotation.z,
		},
	}
	
	var file = FileAccess.open("user://debug_cam.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	
func load_camera() -> void:
	var file = FileAccess.open("user://debug_cam.json", FileAccess.READ)
	var json = file.get_as_text()
	var data = JSON.parse_string(json)
	
	global_transform.origin = Vector3(
		data.position.x,
		data.position.y,
		data.position.z,
	)
	
	global_rotation.x = data.rotation.x
	global_rotation.y = data.rotation.y
	global_rotation.z = data.rotation.z
