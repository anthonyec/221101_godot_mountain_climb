extends Node
	
static func get_position_on_path(points: Array[Vector3], length: float) -> Vector3:
	var total_length: float = 0
	var position_on_path: Vector3 = Vector3.ZERO
	
	for index in range(points.size()):
		if index == 0:
			continue
		
		var point_a = points[index - 1]
		var point_b = points[index]
		var segment_length = point_a.distance_to(point_b)
		
		total_length += segment_length
		
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
		var distance_between_joints = point_a.distance_to(point_b)
		
		total_length += distance_between_joints

	return total_length
