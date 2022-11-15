extends Node3D

@export var debug = false
@export var debug_color = Color.RED

func fan_out(
	parameters: PhysicsRayQueryParameters3D,
	angle: float, 
	count: int
):
	pass

func intersect_ray(start_position: Vector3, end_position: Vector3):
	var space_state = get_world_3d().direct_space_state
	
	if debug:
		DebugDraw.draw_line_3d(start_position, end_position, debug_color)
	
	return space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(start_position, end_position)
	)
