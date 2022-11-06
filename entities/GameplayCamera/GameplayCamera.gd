extends Spatial

export var target_paths: Array
export var distance: float = 10
export var pitch: float = 0
export var yaw: float = 0
export var speed: float = 5

onready var rig: Spatial = $"%Rig"
onready var camera: Camera = $"%Camera"

var targets: Array

func _ready() -> void:
	for target_path in target_paths:
		if !target_path:
			set_process(false)
			return

		targets.append(get_node_or_null(target_path))

func _process(delta: float) -> void:
	# Get the average position of all targets.
	var average_target_position: Vector3 = Vector3.ZERO
	
	for target in targets:
		average_target_position = average_target_position + target.global_transform.origin
		
	average_target_position = average_target_position / targets.size()
		
	# Moving.
	global_transform.origin = global_transform.origin.linear_interpolate(
		average_target_position, 
		delta * 10
	)
	
	# Zooming.
	camera.transform.origin.z = lerp(camera.transform.origin.z, clamp(distance, 1, 100), delta * speed)
	
	# Roation.
	global_rotation.y = lerp_angle(global_rotation.y, deg2rad(yaw), delta * speed)
	rig.global_rotation.x = lerp_angle(rig.global_rotation.x, deg2rad(-pitch), delta * speed)

func _input(event: InputEvent) -> void:
	if event.is_action("rotate_camera_left"):
		yaw = yaw + 5
	
	if event.is_action("rotate_camera_right"):
		yaw = yaw - 5
		
	if event.is_action("zoom_out") and distance != 0:
		distance = distance - 1
	
	if event.is_action("zoom_in")  and distance != 100:
		distance = distance + 1
