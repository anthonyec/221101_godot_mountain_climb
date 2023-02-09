class_name LedgeSearcher
extends Node3D

@export var debug: bool = false
@export var max_floor_angle: float = 40
@export var hang_distance_from_wall: float = 0.3
@export var grab_height: float = 1.2
@export var search_distance: float = 0.7

enum Direction {
	LEFT = -1,
	RIGHT = 1
}

var path: Array[Vector3] = []
var normals: Array[Vector3] = []
var min_length: float = 0
var max_length: float = 0
var total_length: float = 0
var last_min_ledge_info: LedgeInfo
var last_max_ledge_info: LedgeInfo

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
	
func extend_path(direction: Direction) -> void:
	var ledge_info: LedgeInfo
	
	if direction == Direction.RIGHT:
		ledge_info = last_max_ledge_info
		
	if direction == Direction.LEFT:
		ledge_info = last_min_ledge_info

	find_and_build_path(ledge_info, direction)

func find_and_build_path(initial_ledge_info: LedgeInfo, direction: Direction) -> void:
	var search_result = search_for_more_ledge(initial_ledge_info, direction)
	
	if search_result.points.is_empty():
		# TODO: Maybe return just one ledge point so that player can just 
		# hand but not move?
		return
		
	var path_size_before_appending = path.size()
	
	if direction == Direction.RIGHT:
		path.append_array(search_result.points)
		last_max_ledge_info = search_result.last_ledge_info
	
	if direction == Direction.LEFT:
		# TODO: Tehe, maybe there's a better to preprend_array to front. 
		# Or maybe this is genius.
		path.reverse()
		path.append_array(search_result.points)
		path.reverse()
		last_min_ledge_info = search_result.last_ledge_info

	# TODO: This can actually be done when appending to avoid
	# the path changing. However, I'm doing it here to avoid positioning
	# doubling up and messing up normals.
	path = simplify_path(path)
	
	# Measure the added path length after simplifying so that the size is 
	# awlays consistent.
	if direction == Direction.RIGHT:
		# TODO: This length seems to be lower than the min length??
		max_length += Utils.get_path_length(path.slice(path_size_before_appending, path.size()))
		
	if direction == Direction.LEFT:
		min_length -= Utils.get_path_length(search_result.points.slice(0, search_result.points.size()))
	
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
	
func search_for_more_ledge(initial_ledge: LedgeInfo, direction: Direction) -> LedgeSearchResult:
	var resolution = 0.02
	
	var result: LedgeSearchResult = LedgeSearchResult.new()
	var last_ledge = initial_ledge

	for index in range(10):
		var offset_along_ledge = (last_ledge.direction * resolution * index)
		var offset_away_from_ledge = (last_ledge.normal * 0.1) + (Vector3.DOWN * 0.1)
	
		var start_search_position: Vector3 = last_ledge.position
		
		if direction == Direction.RIGHT:
			start_search_position = start_search_position + offset_along_ledge + offset_away_from_ledge
		
		if direction == Direction.LEFT:
			start_search_position = start_search_position - offset_along_ledge + offset_away_from_ledge
		
		var ledge = get_ledge_info(start_search_position, -last_ledge.wall_normal)
		
		if ledge.has_error():
			result.error = ledge.error
			break
			
		result.points.append(ledge.position)
		last_ledge = ledge
	
	result.last_ledge_info = last_ledge
	return result

func get_ledge_info(start_position: Vector3, direction: Vector3) -> LedgeInfo:
	var info = LedgeInfo.new()
	var wall_hit = Raycast.cast_in_direction(start_position, direction, search_distance)

	if wall_hit.is_empty():
		info.error = LedgeInfo.Error.NO_WALL_HIT
		return info
		
	if wall_hit.normal.angle_to(Vector3.UP) < deg_to_rad(80):
		info.error = LedgeInfo.Error.BAD_WALL_ANGLE
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
		
	
	var floor_plane = Plane(floor_hit.normal, floor_hit.position)
	var edge_position = floor_plane.intersects_ray(wall_hit.position, floor_hit.normal)
	
	# Edge normal is the wall normal with the Y component flattened to zero.
	var edge_normal = Vector3(wall_hit.normal.x, 0, wall_hit.normal.z).normalized()
	
	info.position = edge_position
	info.normal = edge_normal
	info.direction = edge_normal.cross(-floor_hit.normal)
	info.wall_normal = wall_hit.normal
	
	return info
