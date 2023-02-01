class_name LedgeSearcher
extends Node3D

@export var max_floor_angle: float = 40
@export var hang_distance_from_wall: float = 0.3
@export var grab_height: float = 1.2
@export var search_distance: float = 0.7

var path: Array[Vector3] = []
var normals: Array[Vector3] = []
var total_length: float = 0

func _ready() -> void:
	Raycast.debug = true
	find_path()
	print(total_length)

func _process(_delta: float) -> void:
	for index in range(path.size()):
		var point = path[index]
		DebugDraw.draw_cube(point, 0.05, Color.PURPLE)
		
		if index > 0:
			var previous_point = path[index - 1]
			DebugDraw.draw_line_3d(previous_point, point, Color.PURPLE)
			
	var position = get_position_on_path(path, 1)
	DebugDraw.draw_cube(position, 0.1, Color.RED)

func get_position_on_path(points: Array[Vector3], length: float) -> Vector3:	
	return Utils.get_position_on_path(points, clamp(length, 0, total_length))

func find_path() -> void:
	var ledge = get_ledge_info(global_transform.origin, -global_transform.basis.z)
	
	if ledge.has("error"):
		return
		
	var points = search(
		ledge.position + (ledge.normal * 0.1) + (Vector3.DOWN * 0.1), 
		ledge.direction, 
		-ledge.normal
	)
	
	path = simplify_path(points)
	total_length = Utils.get_path_length(path)

# Based on: https://github.com/mattdesl/simplify-path/blob/master/radial-distance.js
func simplify_path(points: Array[Vector3]) -> Array[Vector3]:
	if points.size() <= 1:
		return points
		
	var tolerance = 0.2
	var tolerance_squared = tolerance * tolerance
	
	var previous_point = points[0]
	var new_points = [previous_point]
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
	
func search(initial_position: Vector3, initial_direction: Vector3, inital_normal: Vector3) -> Array[Vector3]:
	var resolution = 0.02
	
	var points = []
	var last_position = initial_position
	var last_direction = initial_direction
	var last_normal = inital_normal
	
	for index in range(10):
		var search_position = last_position + (last_direction * resolution * index)
		var ledge = get_ledge_info(search_position, last_normal)
		
		DebugDraw.draw_cube(search_position, 0.05, Color.RED)
		
		if ledge.has("error"):
			break
			
#		DebugDraw.draw_ray_3d(ledge.position, ledge.direction, 1, Color.PURPLE)
#		DebugDraw.draw_cube(ledge.position, 0.05, Color.BLUE)
		
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
