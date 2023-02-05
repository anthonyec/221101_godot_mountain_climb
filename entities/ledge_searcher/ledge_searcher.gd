class_name LedgeSearcher
extends Node3D

@export var debug: bool = false
@export var max_floor_angle: float = 40
@export var hang_distance_from_wall: float = 0.3
@export var grab_height: float = 1.2
@export var search_distance: float = 0.7

var path: Array[Vector3] = []
var normals: Array[Vector3] = []
var min_length: float = 0
var max_length: float = 0
var total_length: float = 0

func _ready() -> void:
	Raycast.debug = true

func _process(_delta: float) -> void:
	total_length = max_length - min_length
	
	if not debug:
		return
		
	for index in range(path.size()):
		var point = path[index]
		DebugDraw.draw_cube(point, 0.05, Color.PURPLE)
		
		if index < path.size() - 1:
			var next_point = path[index + 1]
			DebugDraw.draw_ray_3d(point.lerp(next_point, 0.5), normals[index], 1, Color.WHITE)
		
		if index > 0:
			var previous_point = path[index - 1]
			DebugDraw.draw_line_3d(previous_point, point, Color.PURPLE)

func reset() -> void:
	path = []
	normals = []
	min_length = 0
	max_length = 0
	total_length = 0
	
func clean() -> void:
	pass

# TODO: Interpolate the normals to avoid snappiness.
func get_normal_on_ledge(length: float) -> Vector3:
	var progress = Utils.get_progress_on_path(path, clamp(length, min_length, max_length), min_length)
	var index = progress.index
	
	if index < path.size() - 1:
		var point_a = path[index]
		var point_b = path[index + 1]
		var mid_point = point_a.lerp(point_b, 0.5)
		
		if debug:
			DebugDraw.draw_cube(mid_point, 0.1, Color.RED)
	
	var clamped_index = clamp(index, 0, normals.size() - 1)
	return normals[clamped_index]

func get_position_on_ledge(length: float) -> Vector3:
	return Utils.get_position_on_path(path, clamp(length, min_length, max_length), min_length)

func find_path(direction: int = 1, is_continuation: bool = false) -> void:
	# TODO: Make this not tied to player? Or maybe kee it??
	var ledge: Dictionary
	
	if not is_continuation:
		ledge = get_ledge_info(global_transform.origin, -global_transform.basis.z)
		
	if is_continuation:
		if direction == 1:
			var normal = normals[normals.size() - 1]
			ledge = get_ledge_info(path[path.size() - 1] + (normal * 0.1) + (Vector3.DOWN * 0.1), -normal)
		else:
			var normal = normals[0]
			ledge = get_ledge_info(path[0] + (normal * 0.1) + (Vector3.DOWN * 0.1), -normal)
	
	if ledge.has("error"):
		push_warning(ledge.get("error"))
		return
		
	var points = search(
		ledge.position + (ledge.normal * 0.1) + (Vector3.DOWN * 0.1), 
		ledge.direction * direction, 
		-ledge.normal,
		direction
	)
	
	if direction == 1:
		var new_points_length = Utils.get_path_length(points)
		
		max_length += new_points_length
		path.append_array(points)
	else:
		var new_points_length = Utils.get_path_length(points)
		
		min_length -= new_points_length
		# TODO: Tehe, maybe there's a better to preprend_array to front. 
		# Or maybe this is genius.
		path.reverse()
		path.append_array(points)
		path.reverse()
	
	# TODO: This can actually be done when appending to avoid
	# the path changing. However, I'm doing it here to avoid positioning
	# doubling up and messing up normals.
	path = simplify_path(path)
	
	# Calculate normals.
	normals = []
		
	for index in range(path.size() - 1):
		var point_a = path[index]
		var point_b = path[index + 1]
		var direction_a_to_b = point_a.direction_to(point_b)
		var cross = direction_a_to_b.cross(Vector3.UP)
		
		normals.append(cross)
	
	# Smooth normals.
	for index in range(normals.size() - 2):
		var normal_a = normals[index]
		var normal_c = normals[index + 2]
		var averaged_b = (normal_a + normal_c) / 2

		normals[index + 1] = averaged_b.normalized()

# Based on: https://github.com/mattdesl/simplify-path/blob/master/radial-distance.js
func simplify_path(points: Array[Vector3]) -> Array[Vector3]:
	if points.size() <= 1:
		return points
		
	var tolerance = 0.2
	var tolerance_squared = tolerance * tolerance
	
	var previous_point: Vector3 = points[0]
	var new_points: Array[Vector3] = [previous_point]
	var point: Vector3
	
	for index in range(1, points.size()):
		point = points[index]
		
		if previous_point.distance_squared_to(point) < tolerance_squared:
			continue
		
		new_points.append(point)
		previous_point = point
	
	if previous_point != point:
		new_points.append(point)

	return new_points
	
func search(initial_position: Vector3, initial_direction: Vector3, inital_normal: Vector3, temp_dir: int = 1) -> Array[Vector3]:
	var resolution = 0.02
	
	var points: Array[Vector3] = []
	var last_position = initial_position
	var last_direction = initial_direction
	var last_normal = inital_normal
	
	for index in range(10):
		var next_search_position = (last_direction * resolution * index)
		# TODO: Temporary thing to get it working, make it more elgant later.
		var search_position = last_position + next_search_position if temp_dir == 1 else last_position - next_search_position
		var ledge = get_ledge_info(search_position, last_normal)
		
		if debug:
			DebugDraw.draw_cube(search_position, 0.05, Color.RED)
		
		if ledge.has("error"):
			break
			
		points.append(ledge.position)
		
		last_position = ledge.position + (ledge.normal * 0.1) + (Vector3.DOWN * 0.1)
		last_normal = -ledge.normal
		last_direction = ledge.direction
		
	return points

func get_ledge_info(start_position: Vector3, direction: Vector3) -> Dictionary:
	var wall_hit = Raycast.cast_in_direction(start_position, direction, search_distance)
	
	if wall_hit.is_empty():
		return { "error": "no_wall_hit" }

	var floor_hit = Raycast.cast_in_direction(
		wall_hit.position - (wall_hit.normal * 0.1) + (Vector3.UP * grab_height), 
		Vector3.DOWN, 
		grab_height
	)
	
	if floor_hit.is_empty():
		return { "error": "no_floor_hit" }
		
	# Edge normal is the wall normal with the Y component flattened to zero.
	var edge_normal = Vector3(wall_hit.normal.x, 0, wall_hit.normal.z).normalized()
	
	var floor_plane = Plane(floor_hit.normal, floor_hit.position)
	var edge_position = floor_plane.intersects_ray(wall_hit.position, floor_hit.normal)
	
	return {
		# Position of the edge.
		"position": edge_position,
		# Direction of the edge facing outwards.
		"normal": edge_normal,
		# Direction the edge flows facing right.
		"direction": edge_normal.cross(-floor_hit.normal)
	}
