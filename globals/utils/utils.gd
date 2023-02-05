extends Node

static func get_progress_on_path(points: Array[Vector3], length: float, start_length: float = 0) -> Dictionary:
	var total_length: float = start_length
	var index_on_path: float = float(points.size() - 1)
	var progress: float = 0
	
	for index in range(points.size() - 1):
		var point_a = points[index]
		var point_b = points[index + 1]
		var distance_between_a_to_b = point_a.distance_to(point_b)
		
		total_length += distance_between_a_to_b
		
		if total_length >= length:
			var difference_in_length = total_length - length
			var direction_a_to_b = point_a.direction_to(point_b)
			var progress_percent = 1 - (difference_in_length / distance_between_a_to_b)
			
			index_on_path = index
			progress = progress_percent
			break
			
	return {
		"index": index_on_path,
		"percent": progress
	}
	
static func get_position_on_path(points: Array[Vector3], length: float, start_length: float = 0) -> Vector3:
	var total_length: float = start_length
	
	# TODO: This is a bit of a work around because the total_length
	# will be smaller than the max_length.
	var position_on_path: Vector3 = points[points.size() - 1]
	
	for index in range(points.size()):
		if index == 0:
			continue
		
		var point_a = points[index - 1]
		var point_b = points[index]
		var distance_between_a_to_b = point_a.distance_to(point_b)
		
		total_length += distance_between_a_to_b
		
		if total_length >= length:
			var difference_in_length = total_length - length
			var direction_a_to_b = point_a.direction_to(point_b)
			
			position_on_path = point_b - (direction_a_to_b * difference_in_length)
			break
			
	return position_on_path

static func get_path_length(points: Array[Vector3]) -> float:
	var total_length: float = 0
	
	for index in points.size():
		if index == 0:
			continue
			
		var point_a = points[index - 1]
		var point_b = points[index]
		var distance_between_a_to_b = point_a.distance_to(point_b)
		
		total_length += distance_between_a_to_b

	return total_length
