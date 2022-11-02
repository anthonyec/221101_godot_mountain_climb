#warning-ignore:RETURN_VALUE_DISCARDED
extends KinematicBody

export var player_index: int = 0
export var gravity: float = 20
export var jump_strength: float = 9
export var rotation_speed: float = 10
export var walk_speed: float = 4
export var climb_speed: float = 2
export var state: String = "move"

var movement: Vector3 = Vector3.ZERO
var snap_vector: Vector3 = Vector3.ZERO
var input_direction: Vector2 = Vector2.ZERO
var is_jump_action: bool = false
var objects_in_possession = []

func _process(delta: float) -> void:
	match state:
		"abseil_host":
			abseil_host_state(delta)
		
		"abseil_climb":
			abseil_climb_state(delta)
			
		"move":
			move_state(delta)

func abseil_host_state(delta: float):
	pass	
	
func abseil_climb_state(delta: float):
	movement.x = 0
	movement.z = 0
	movement.y = (-input_direction.y) * climb_speed
	movement = move_and_slide(movement, Vector3.UP)
	print(input_direction, ", ", movement.y)
	pass	

func move_state(delta: float):
	var just_landed = is_on_floor() and snap_vector == Vector3.ZERO
	var is_jumping = is_on_floor() and is_jump_action
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = direction.x * walk_speed
	movement.z = direction.z * walk_speed
	movement.y -= gravity * delta
	
	if is_jumping:
		movement.y = jump_strength
		snap_vector = Vector3.ZERO
	elif just_landed:
		snap_vector = Vector3.DOWN
	
	var current_facing_direction = global_transform.basis.z
	var angle_difference = current_facing_direction.signed_angle_to((direction * -1), Vector3.UP)
	
	rotate(global_transform.basis.y, angle_difference * rotation_speed * delta)
	movement = move_and_slide_with_snap(movement, snap_vector, Vector3.UP, true)
	
#	DebugDraw.draw_ray_3d(global_transform.origin, -global_transform.basis.z, 1, Color.red)
#	DebugDraw.draw_ray_3d(global_transform.origin - global_transform.basis.z, -Vector3.UP, 2, Color.red)
#	DebugDraw.draw_ray_3d(global_transform.origin - global_transform.basis.z - (Vector3.UP * 2), global_transform.basis.z, 1, Color.red)

func end_abseil(end_position: Vector3) -> void:
	if state == "abseil_climb":
		global_transform.origin = end_position
		state = "move"
		
func start_abseil(start_position: Vector3, rotation: Vector3) -> void:
	if state == "move":
		movement = Vector3.ZERO
		global_rotation = rotation
		global_transform.origin = start_position
		state = "abseil_climb"
		
func start_hosting_abseil() -> void:
	if state == "abseil_host":
		state = "move"
		remove_objects_in_posession()
		return
	
	if state != "move" or !is_on_floor():
		return
	
	var space_state = get_world().direct_space_state
	var result_down = space_state.intersect_ray(global_transform.origin - global_transform.basis.z, global_transform.origin - global_transform.basis.z - (Vector3.UP * 2))
	var result_in = space_state.intersect_ray(global_transform.origin - global_transform.basis.z - (Vector3.UP * 2), (global_transform.origin - global_transform.basis.z - (Vector3.UP * 2) + global_transform.basis.z))
	
	DebugDraw.draw_line_3d(global_transform.origin - global_transform.basis.z, global_transform.origin - global_transform.basis.z - (Vector3.UP * 2), Color.red)
	DebugDraw.draw_line_3d(global_transform.origin - global_transform.basis.z - (Vector3.UP * 2), (global_transform.origin - global_transform.basis.z - (Vector3.UP * 2) + global_transform.basis.z), Color.red)
	
	if result_down.empty() and not result_in.empty():
		var abseil = load("res://AbseilRope.tscn")
		var abseil_instance: Spatial = abseil.instance()
		
		get_parent().add_child(abseil_instance)
		
		var vertical_distance_from_player = global_transform.origin.y - result_in.position.y
		
		abseil_instance.global_transform.origin = result_in.position
		abseil_instance.global_transform.origin.y = abseil_instance.global_transform.origin.y + vertical_distance_from_player
		
		objects_in_possession.append(abseil_instance)
		state = "abseil_host"
		
func set_input_direction(direction: Vector2) -> void:
	input_direction = direction
	
func set_jump(jump: bool) -> void:
	is_jump_action = jump
	
func remove_objects_in_posession() -> void:
	for index in objects_in_possession.size():
		var object = objects_in_possession[index]
		
		object.queue_free()
		objects_in_possession.remove(index)

# Get the active cameras global Y axis rotation and use that to rotate the
# direction vector.
func transform_direction_to_camera_angle(direction: Vector3) -> Vector3:
	var camera = get_viewport().get_camera()
	var camera_angle_y = camera.global_transform.basis.get_euler().y

	return direction.rotated(Vector3.UP, camera_angle_y)
