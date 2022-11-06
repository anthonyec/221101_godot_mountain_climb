#warning-ignore:RETURN_VALUE_DISCARDED
extends KinematicBody

export var player_index: int = 0
export var gravity: float = 20
export var jump_strength: float = 9
export var rotation_speed: float = 20
export var walk_speed: float = 4
export var climb_speed: float = 2
export var state: String = "move"

onready var model: Spatial = $Model

var movement: Vector3 = Vector3.ZERO
var snap_vector: Vector3 = Vector3.ZERO
var input_direction: Vector2 = Vector2.ZERO
var objects_in_possession = []

func _process(delta: float) -> void:
	input_direction = Input.get_vector(
		"move_left_" + String(player_index),
		"move_right_" + String(player_index),
		"move_forward_" + String(player_index),
		"move_backward_" + String(player_index)
	)
	
	match state:
		"abseil_host": abseil_host_state(delta)
		"abseil_climb": abseil_climb_state(delta)
		"move": move_state(delta)
		"falling": falling_state(delta)
		"jumping": jumping_state(delta)
		"grab": grab_state(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start_hosting_abseil_" + String(player_index)):
		start_hosting_abseil()

func abseil_host_state(delta: float):
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = direction.x * walk_speed
	movement.z = direction.z * walk_speed
	movement.y -= gravity * delta
	
	movement = move_and_slide_with_snap(movement, snap_vector, Vector3.UP, true)
	
	var segment: RigidBody = objects_in_possession[0].get_middle_segment()
	
	face_towards(segment.global_transform.origin)
	
func abseil_climb_state(delta: float):
	movement.x = 0
	movement.z = 0
	movement.y = (-input_direction.y) * climb_speed
	movement = move_and_slide(movement, Vector3.UP)
	print(input_direction, ", ", movement.y)
	
func grab_state(delta):
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement = move_and_slide_with_snap(movement, snap_vector, Vector3.UP, true)
	
	if Input.is_action_just_pressed("jump_" + String(player_index)):
		model.transform.origin.z = 0
		model.transform.origin.y = 0
		state = "move"
		
	if !Input.is_action_pressed("grab_" + String(player_index)):
		global_transform.origin = model.global_transform.origin
		model.transform.origin.z = 0
		model.transform.origin.y = 0
		state = "falling"

var into_jump_movement: Vector3 = Vector3.ZERO

func jumping_state(delta: float):
	if into_jump_movement == Vector3.ZERO:
		into_jump_movement = movement * 1.2
	
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = into_jump_movement.x + direction.x
	movement.z = into_jump_movement.z + direction.z
	movement.y -= gravity * delta
	movement = move_and_slide_with_snap(movement, snap_vector, Vector3.UP, true)
		
	if movement.y < 0:
		state = "falling"
		
func falling_state(delta):
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = into_jump_movement.x + direction.x
	movement.z = into_jump_movement.z + direction.z
	movement.y -= (gravity * 2) * delta
	movement = move_and_slide_with_snap(movement, snap_vector, Vector3.UP, true)
	
	var space_state = get_world().direct_space_state
	var result_down = space_state.intersect_ray(global_transform.origin - global_transform.basis.z + (Vector3.UP * 1.5), global_transform.origin - global_transform.basis.z)
	var result_down_2 = space_state.intersect_ray(global_transform.origin - (global_transform.basis.z * 1.5) + Vector3.UP, global_transform.origin - (global_transform.basis.z * 1.5))
	var result_front = space_state.intersect_ray(global_transform.origin + (Vector3.UP * 0.5), global_transform.origin + (Vector3.UP * 0.5) - global_transform.basis.z * 2)
	
	DebugDraw.draw_line_3d(global_transform.origin - global_transform.basis.z + (Vector3.UP * 1.5), global_transform.origin - global_transform.basis.z, Color.red)
	DebugDraw.draw_line_3d(global_transform.origin - (global_transform.basis.z * 1.5) + Vector3.UP, global_transform.origin - (global_transform.basis.z * 1.5), Color.red)
	DebugDraw.draw_line_3d(global_transform.origin + (Vector3.UP * 0.5), global_transform.origin + (Vector3.UP * 0.5) - global_transform.basis.z * 2, Color.red)
	
	if (!result_down.empty() or !result_down_2.empty()) and !result_front.empty() and Input.is_action_pressed("grab_" + String(player_index)):
		var final_result_down = result_down if not result_down.empty() else result_down_2
		global_transform.origin = final_result_down.position + Vector3.UP
		look_at(global_transform.origin - result_front.normal, Vector3.UP)
		global_rotation.x = 0
		global_rotation.z = 0
		model.transform.origin.z = 1
		model.transform.origin.y = -1.5
		into_jump_movement = Vector3.ZERO
		movement = Vector3.ZERO
		state = "grab"
	
	if is_on_floor() and snap_vector == Vector3.ZERO:
		into_jump_movement = Vector3.ZERO
		state = "move"

func move_state(delta: float):
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
	
	movement.x = direction.x * walk_speed
	movement.z = direction.z * walk_speed
	movement.y -= gravity * delta
	
	var current_facing_direction = global_transform.basis.z
	var angle_difference = current_facing_direction.signed_angle_to((direction * -1), Vector3.UP)
	
	if is_on_floor() and Input.is_action_just_pressed("jump_" + String(player_index)):
		movement.y = jump_strength
		snap_vector = Vector3.ZERO
		state = "jumping"
		
	rotate(global_transform.basis.y, angle_difference * rotation_speed * delta)
	movement = move_and_slide_with_snap(movement, snap_vector, Vector3.UP, true)

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
	
	
	var abseil = load("res://entities/Rope/Rope.tscn")
	var abseil_instance: Spatial = abseil.instance()
	
	abseil_instance.global_rotation = global_rotation
	abseil_instance.root_attachment = get_path()
	get_parent().add_child(abseil_instance)
	
	abseil_instance.global_transform.origin = global_transform.origin
	
	objects_in_possession.append(abseil_instance)
	state = "abseil_host"
	
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

func face_towards(target: Vector3) -> void:
	look_at(target, Vector3.UP)
	global_rotation.x = 0
	global_rotation.z = 0
