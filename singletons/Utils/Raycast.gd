extends Node3D

@export var debug = false
@export var debug_color = Color.RED

# TODO: Add a general "sweep" function that can sweep any kind of raycast or shape cast.
# It could use the new lambda feature of GDScript 2. Something like:
# Raycast.sweep(direction, iterations, (index, position) => {
#   return Raycast.fan_out(position, fan_direction
# })
# Then there could be conditions based on if it's a hit or if it's the shortest hit.
# Maybe params or other functions like `sweep_first_hit` or `sweep_shortest_hit`?

func offset_by(radius: float, angle: float, distance: float):
	return Vector2(cos(angle) * (radius + distance), sin(angle) * (radius + distance))

func fan_out(start_position: Vector3, direction: Vector3, length: float = 1.0, angle_range: float = 90.0, total: int = 10, up: Vector3 = Vector3.UP):
	var angle_diff = deg_to_rad(angle_range)
	var angle_segment = angle_diff / total
	
	var shortest_distance_squared = INF
	var shortest_hit = {}
	
	for index in total:
		var angle = (angle_segment * index) - (angle_diff / 2)
		var hit = cast_in_direction(start_position, direction.rotated(up, angle), length)
		
		if hit:
			var distance_squared = start_position.distance_to(hit.position)
			
			if distance_squared < shortest_distance_squared:
				shortest_distance_squared = distance_squared
				shortest_hit = hit

	return shortest_hit

# TODO: Actually implement exlucde lmao.
func intersect_ray(start_position: Vector3, end_position: Vector3, exclude: Array = []):
	var space_state = get_world_3d().direct_space_state
	
	if debug:
		DebugDraw.draw_line_3d(start_position, end_position, debug_color)
	
	return space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(start_position, end_position)
	)
	
# TODO: Fix return type. Should be Dictionary[] but couldn't get it working.
func intersect_cylinder(position: Vector3, height: float = 2.0, radius: float = 0.5, exclude: Array = []) -> Array:
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsShapeQueryParameters3D.new()
	var shape = CylinderShape3D.new()
	
	shape.height = height
	shape.radius = radius
	
	params.shape = shape
	params.transform.origin = position

	if debug:
		DebugDraw.draw_box(params.transform.origin, Vector3(radius * 2, height, radius * 2), debug_color)
	
	return space_state.intersect_shape(params)

func cast_in_direction(start_position: Vector3, direction: Vector3, length: float = 1.0, exclude: Array = []) -> Dictionary:
	return intersect_ray(start_position, start_position + (direction * length), exclude)
