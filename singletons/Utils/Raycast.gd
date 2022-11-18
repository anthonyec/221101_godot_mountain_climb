extends Node3D

@export var debug = false
@export var debug_color = Color.RED

func offset_by(radius: float, angle: float, distance: float):
	return Vector2(cos(angle) * (radius + distance), sin(angle) * (radius + distance))

func fan_out(parameters: PhysicsRayQueryParameters3D, angle: float, count: int):
	var start_angle: float = 0
	var end_angle: float = 90

	var direction = parameters.from.direction_to(parameters.to)
	pass

func intersect_ray(start_position: Vector3, end_position: Vector3):
	var space_state = get_world_3d().direct_space_state
	
	if debug:
		DebugDraw.draw_line_3d(start_position, end_position, debug_color)
	
	return space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(start_position, end_position)
	)

func cast_in_direction(start_position: Vector3, direction: Vector3, length: float = 1.0) -> Dictionary:
	return intersect_ray(start_position, start_position + (direction * length))
