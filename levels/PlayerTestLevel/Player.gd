#warning-ignore:RETURN_VALUE_DISCARDED
extends KinematicBody

export var player_index: int = 2
export var gravity: float = 20
export var jump_strength: float = 9
export var rotation_speed: float = 20
export var walk_speed: float = 4
export var climb_speed: float = 2
export var state: String = "move"

var movement: Vector3 = Vector3.ZERO
var snap_vector: Vector3 = Vector3.ZERO
var input_direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	var input_direction = Input.get_vector(
		"move_left_" + String(player_index),
		"move_right_" + String(player_index),
		"move_forward_" + String(player_index),
		"move_backward_" + String(player_index)
	)
	
#	var just_landed = is_on_floor() and snap_vector == Vector3.ZERO
#	var is_jumping = is_on_floor() and Input.is_action_just_pressed("jump_" + String(player_index))
	var direction: Vector3 = transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y))
#
#	movement.x = direction.x * walk_speed
#	movement.z = direction.z * walk_speed
#	movement.y -= gravity * delta
#
#	if is_jumping:
#		movement.y = jump_strength
#		snap_vector = Vector3.ZERO
#	elif just_landed:
#		snap_vector = Vector3.DOWN
	
	var current_facing_direction = global_transform.basis.z
	var angle_difference = current_facing_direction.signed_angle_to((direction * -1), Vector3.UP)
	
	rotate(global_transform.basis.y, angle_difference * rotation_speed * delta)
#	movement = move_and_slide_with_snap(movement, snap_vector, Vector3.UP, true)


# Get the active cameras global Y axis rotation and use that to rotate the
# direction vector.
func transform_direction_to_camera_angle(direction: Vector3) -> Vector3:
	var camera = get_viewport().get_camera()
	var camera_angle_y = camera.global_transform.basis.get_euler().y

	return direction.rotated(Vector3.UP, camera_angle_y)
