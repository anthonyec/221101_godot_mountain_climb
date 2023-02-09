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
		DebugDraw.draw_ray_3d(point, normals[index], 1, Color.WHITE)
		
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
	
	var normal_a = normals[index]
	
	if index < normals.size() - 1:
		var normal_b = normals[index + 1]
		return normal_a.lerp(normal_b, progress.percent)
	
	return normal_a

func get_position_on_ledge(length: float) -> Vector3:
	return Utils.get_position_on_path(path, clamp(length, min_length, max_length), min_length)

func find_path(direction: int = 1, is_continuation: bool = false) -> void:
	# TODO: Make this not tied to player? Or maybe kee it??
	var ledge: LedgeInfo
	
	if not is_continuation:
		ledge = get_ledge_info(global_transform.origin, -global_transform.basis.z)
		
	if is_continuation:
		if direction == 1:
			var normal = normals[normals.size() - 1]
			ledge = get_ledge_info(path[path.size() - 1] + (normal * 0.1) + (Vector3.DOWN * 0.1), -normal)
		else:
			var normal = normals[0]
			ledge = get_ledge_info(path[0] + (normal * 0.1) + (Vector3.DOWN * 0.1), -normal)
	
	if ledge.has_error():
		push_warning(ledge.get_error_message())
		return
		
	var search_result = search(
		ledge.position + (ledge.normal * 0.1) + (Vector3.DOWN * 0.1), 
		ledge.direction * direction, 
		-ledge.normal,
		direction
	)
	
	var points = search_result.points
	
	if points.is_empty():
		return
	
	var path_size_before_appending = path.size()
	
	if direction == 1:
		path.append_array(points)
	
	if direction == -1:
		# TODO: Tehe, maybe there's a better to preprend_array to front. 
		# Or maybe this is genius.
		path.reverse()
		path.append_array(points)
		path.reverse()

	# TODO: This can actually be done when appending to avoid
	# the path changing. However, I'm doing it here to avoid positioning
	# doubling up and messing up normals.
	path = simplify_path(path)
	
	# Measure the added path length after simplifying so that the size is 
	# awlays consistent.
	if direction == 1:
		max_length += Utils.get_path_length(path.slice(path_size_before_appending, path.size()))
		
	if direction == -1:
		min_length -= Utils.get_path_length(points.slice(0, points.size()))
	
	# Calculate normals.
	normals = []
	
	var last_original_normal: Vector3
		
	for index in range(path.size()):
		if index == path.size() - 1:
			normals.append(last_original_normal)
			continue
		
		var point_a = path[index]
		var point_b = path[index + 1]
		var direction_a_to_b = point_a.direction_to(point_b)
		var cross = direction_a_to_b.cross(Vector3.UP)
		
		if last_original_normal:
			normals.append((last_original_normal + cross) / 2)
		else:
			normals.append(cross)
			
		last_original_normal = cross
	
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
	
func search(initial_ledge_position: Vector3, initial_ledge_direction: Vector3, inital_normal: Vector3, temp_dir: int = 1) -> LedgeSearchResult:
	var resolution = 0.02
	
	var result: LedgeSearchResult = LedgeSearchResult.new()
	var last_position = initial_ledge_position
	var last_direction = initial_ledge_direction
	var last_wall_normal = inital_normal

	for index in range(10):
		var next_search_position = (last_direction * resolution * index)
		# TODO: Temporary thing to get it working, make it more elgant later.
		var search_position = last_position + next_search_position if temp_dir == 1 else last_position - next_search_position
		var ledge = get_ledge_info(search_position, last_wall_normal)
		
		if ledge.has_error():
			result.error = ledge.error
			break
			
		result.points.append(ledge.position)
		
		last_position = ledge.position + (ledge.normal * 0.1) + (Vector3.DOWN * 0.1)
		last_wall_normal = -ledge.wall_normal
		last_direction = ledge.direction
	
	return result

func get_ledge_info(start_position: Vector3, direction: Vector3) -> LedgeInfo:
	var info = LedgeInfo.new()
	var wall_hit = Raycast.cast_in_direction(start_position, direction, search_distance)
	
	if wall_hit.is_empty():
		info.error = LedgeInfo.Error.NO_WALL_HIT
		return info

	var floor_hit = Raycast.cast_in_direction(
		wall_hit.position - (wall_hit.normal * 0.1) + (Vector3.UP * grab_height), 
		Vector3.DOWN, 
		grab_height
	)
	
	if floor_hit.is_empty():
		info.error = LedgeInfo.Error.NO_FLOOR_HIT
		return info
	
	if floor_hit.normal.angle_to(Vector3.UP) > deg_to_rad(35):
		info.error = LedgeInfo.Error.BAD_FLOOR_ANGLE
		return info
		
	# Edge normal is the wall normal with the Y component flattened to zero.
	var edge_normal = Vector3(wall_hit.normal.x, 0, wall_hit.normal.z).normalized()
	
	var floor_plane = Plane(floor_hit.normal, floor_hit.position)
	var edge_position = floor_plane.intersects_ray(wall_hit.position, floor_hit.normal)
	
	info.position = edge_position
	info.normal = edge_normal
	info.direction = edge_normal.cross(-floor_hit.normal)
	info.wall_normal = wall_hit.normal
	
	return info
