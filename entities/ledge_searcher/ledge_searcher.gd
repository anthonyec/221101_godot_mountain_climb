class_name LedgeSearcher
extends Node3D

const WORLD_COLLISION_MASK: int = 1

@export var debug: bool = false
@export var max_floor_angle: float = 40
@export var hang_distance_from_wall: float = 0.3
@export var grab_height: float = 1.2
# The depth size of space required to be collision free for hands to grab.
@export var hand_depth: float = 0.1
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
			
	if last_min_ledge_info:
		DebugDraw.draw_cube(last_min_ledge_info.position, 0.2, Color.CYAN)
		
	if last_max_ledge_info:
		DebugDraw.draw_cube(last_max_ledge_info.position, 0.2, Color.ORANGE)

func reset() -> void:
	path = []
	normals = []
	min_length = 0
	max_length = 0
	total_length = 0
	last_min_ledge_info = null
	last_max_ledge_info = null
	
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
	var ledge_info: LedgeInfo = null
	
	if direction == Direction.RIGHT and last_max_ledge_info != null:
		ledge_info = last_max_ledge_info
		
	if direction == Direction.LEFT and last_min_ledge_info != null:
		ledge_info = last_min_ledge_info

	if ledge_info != null:
		find_and_build_path(ledge_info, direction)

func find_and_build_path(initial_ledge_info: LedgeInfo, direction: Direction) -> void:
	var search_result = search_for_more_ledge(initial_ledge_info, direction)
	
	if search_result.points.is_empty():
		# Ensure a min or max still exists even if additional ledge was not found.
		# This is because the enviroment might change while hanging, and we'd 
		# still want to continue a ledge search from this position.
		if direction == Direction.RIGHT:
			last_max_ledge_info = initial_ledge_info
			
		if direction == Direction.LEFT:
			last_min_ledge_info = initial_ledge_info
			
		return
		
	var new_length: float = 0
	
	if direction == Direction.RIGHT:
		var new_points = simplify_path(search_result.points)
		
		path.append_array(new_points)
		
		new_length = Utils.get_path_length(new_points)
		last_max_ledge_info = search_result.last_ledge_info
	
	if direction == Direction.LEFT:
		var new_points = simplify_path(search_result.points)
		
		# TODO: Tehe, maybe there's a better to preprend_array to front. 
		# Or maybe this is genius.
		path.reverse()
		path.append_array(new_points)
		path.reverse()
		
		# The length needs to include the first path element, otherwise
		# the current position will move back one path segment in size.
		# TOOD: Clean this up! Appending and removing seems a bit messy.
		new_points.append(path[0])
		new_length = Utils.get_path_length(new_points)
		new_points.pop_back()
		last_min_ledge_info = search_result.last_ledge_info

	# TODO: This can actually be done when appending to avoid
	# the path changing. However, I'm doing it here to avoid positioning
	# doubling up and messing up normals.
	path = simplify_path(path)
	
	# Measure the added path length after simplifying so that the size is 
	# awlays consistent.
	if direction == Direction.RIGHT:
		# TODO: This length seems to be lower than the min length??
		max_length += new_length
		
	if direction == Direction.LEFT:
		min_length -= new_length
	
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
	assert(initial_ledge != null, "Ledge info must exist")
	assert(!initial_ledge.has_error(), "Ledge info must not have error")
	
	var resolution = 0.01
	
	var result: LedgeSearchResult = LedgeSearchResult.new()
	var last_ledge = initial_ledge
	
	# Start from index 1 and not 0 to skip "re-finding" the last ledge.
	for index in range(1, 10):
		var offset_along_ledge = (last_ledge.direction * resolution * index)
		var offset_away_from_ledge = (last_ledge.normal * 0.1) + (-last_ledge.floor_normal * 0.1)
		var start_search_position: Vector3 = last_ledge.position
		
		if direction == Direction.RIGHT:
			start_search_position = start_search_position + offset_along_ledge + offset_away_from_ledge
		
		if direction == Direction.LEFT:
			start_search_position = start_search_position - offset_along_ledge + offset_away_from_ledge
		
		var ledge = get_ledge_info(start_search_position, -last_ledge.wall_normal)
		
		if ledge.has_error():
			# TODO: Add a way to do retries here to search a little further 
			# along the ledge.
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
	var edge_direction = edge_normal.cross(-floor_hit.normal)
	
	# Hand direction is perpendicular to the edge direction, going inwards to the ledge.
	var hand_direction = floor_hit.normal.cross(edge_direction)
	var hand_position = edge_position + (floor_hit.normal * hand_depth) + (hand_direction * hand_depth)
	var hand_hit = Raycast.intersect_ray(hand_position - (hand_direction * hand_depth * 2), hand_position, WORLD_COLLISION_MASK)
	
	if not hand_hit.is_empty():
		info.error = LedgeInfo.Error.NO_HAND_SPACE
		return info
		
	var hang_position = edge_position - (hand_direction * hang_distance_from_wall) + (Vector3.DOWN * 0.35)
	var hang_hit_params = Raycast.CollideCylinderParams.new()
	
	hang_hit_params.collision_mask = WORLD_COLLISION_MASK
	
	var hang_hit = Raycast.collide_cylinder(hang_position, 1.5, 0.1, hang_hit_params)
	
	# Edge position fuzz starts a little bit above the edge position to clear 
	# any little steps in the geometry.
	var edge_position_fuzz = (floor_hit.normal * 0.05)
	
	# Check for collisions between the edge and hang position because there can 
	# be cases where there is a thin wall between them. .
	var space_between_edge_and_hang_hit = Raycast.intersect_ray(edge_position + edge_position_fuzz, hang_position, WORLD_COLLISION_MASK)
	
	if not hang_hit.is_empty() or not space_between_edge_and_hang_hit.is_empty():
		info.error = LedgeInfo.Error.NO_HANG_SPACE
		return info
	
	info.position = edge_position
	info.normal = edge_normal
	info.direction = edge_normal.cross(-floor_hit.normal)
	info.wall_normal = wall_hit.normal
	info.floor_normal = floor_hit.normal
	
	return info
