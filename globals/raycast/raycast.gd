extends Node3D

const DEFAULT_COLLISION_MASK = 4294967295

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

func fan_out(start_position: Vector3, direction: Vector3, length: float = 1.0, angle_range: float = 90.0, total: int = 10, up: Vector3 = Vector3.UP, collision_mask: int = DEFAULT_COLLISION_MASK, exclude: Array = []):
	var angle_diff = deg_to_rad(angle_range)
	var angle_segment = angle_diff / total
	
	var shortest_distance_squared = INF
	var shortest_hit = {}
	
	for index in total:
		var angle = (angle_segment * index) - (angle_diff / 2)
		var hit = cast_in_direction(start_position, direction.rotated(up, angle), length, collision_mask, exclude)
		
		if hit:
			var distance_squared = start_position.distance_to(hit.position)
			
			if distance_squared < shortest_distance_squared:
				shortest_distance_squared = distance_squared
				shortest_hit = hit

	return shortest_hit

func intersect_ray(start_position: Vector3, end_position: Vector3, collision_mask: int = DEFAULT_COLLISION_MASK, exclude: Array = [], hit_back_faces: bool = false):
	var space_state = get_world_3d().direct_space_state 
	
	if debug:
		DebugDraw.draw_line_3d(start_position, end_position, debug_color)
		
	var query = PhysicsRayQueryParameters3D.create(start_position, end_position, collision_mask, exclude)
	
	# TODO: Change params to options dictionary!
	query.hit_back_faces = hit_back_faces
	
	return space_state.intersect_ray(query)
	
# TODO: Fix return type. Should be Dictionary[] but couldn't get it working.
func intersect_cylinder(position: Vector3, height: float = 2.0, radius: float = 0.5, collision_mask: int = DEFAULT_COLLISION_MASK, exclude: Array = []) -> Array:
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsShapeQueryParameters3D.new()
	var shape = CylinderShape3D.new()
	
	shape.height = height
	shape.radius = radius
	
	params.shape = shape
	params.transform.origin = position
	params.collision_mask = collision_mask
	params.exclude = exclude

	if debug:
		DebugDraw.draw_box(params.transform.origin, Vector3(radius * 2, height, radius * 2), debug_color)
	
	return space_state.intersect_shape(params)
	
class CollideCylinderParams:
	var collision_mask = DEFAULT_COLLISION_MASK
	var exclude: Array
	var max_results: int = 32
	
func collide_cylinder(
	position: Vector3, 
	height: float = 2.0, 
	radius: float = 0.5, 
	params: CollideCylinderParams = CollideCylinderParams.new()
# TODO: Using the correct return type, https://github.com/godotengine/godot/issues/73182
) -> PackedVector3Array:
	var space_state = get_world_3d().direct_space_state
	
	var physics = PhysicsShapeQueryParameters3D.new()
	var shape = CylinderShape3D.new()
	
	shape.height = height
	shape.radius = radius
	
	physics.shape = shape
	physics.transform.origin = position
	physics.collision_mask = params.collision_mask
	physics.exclude = params.exclude
	
	if debug:
		DebugDraw.draw_box(physics.transform.origin, Vector3(radius * 2, height, radius * 2), debug_color)
	
	# TODO: I am unsure why this returns Vector2 when the results are Vector3. Seems like a Godot bug.
	return space_state.collide_shape(physics, params.max_results)

func cast_in_direction(start_position: Vector3, direction: Vector3, length: float = 1.0, collision_mask: int = DEFAULT_COLLISION_MASK, exclude: Array = [], hit_back_faces: bool = false) -> Dictionary:
	return intersect_ray(start_position, start_position + (direction * length), collision_mask, exclude, hit_back_faces)

# Sweep a raycast in a direction until it no longer intersects with anything, 
# then return the last intersection.
func sweep_find_edge(start_position: Vector3, end_position: Vector3, direction: Vector3, length: float = 1.0, options: Dictionary = {}) -> Dictionary:
	var iterations = options.get("iterations", 15)
	var exclude = options.get("exclude", [])
	var collision_mask = options.get("collision_mask", DEFAULT_COLLISION_MASK)
	
	var edge_hit = {}
	
	for index in iterations:
		var percent = float(index) / float(iterations)
		var check_position = start_position.lerp(end_position, percent)
		var hit = cast_in_direction(check_position, direction, length, collision_mask, exclude)
		
		if hit.is_empty():
			break
		
		edge_hit = hit
			
	return edge_hit
