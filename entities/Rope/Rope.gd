extends Spatial

export var segment_count: int = 15
export var segment_length: float = 0.5
export var root_attachment: NodePath
export var leaf_attachment: NodePath
export var enable_blob: bool = false
export var blob_position: float = 0
 
var start_position: float = (-segment_length / 2)

# NOTE: The radius of rigid bodies can't bee too small, like 0.1, otherwise
# the physics freak out.
var segments = []
var total_length: float

func _ready() -> void:	
	var segment_scene = preload("res://entities/Rope/Segment.tscn")
	
	total_length = segment_length * float(segment_count)
	
	for index in segment_count:
		var segment = segment_scene.instance()
		segments.append(segment)
		add_child(segment)
		
	for index in segments.size():
		var segment = segments[index]
	
		segment.mode = RigidBody.MODE_STATIC	
		segment.transform.origin.z = start_position - (segment_length * index)
		
		if index > 0:
			var pin_joint: PinJoint = PinJoint.new()
			var previous_segment = segments[index - 1]

			pin_joint.transform.origin = previous_segment.transform.origin + ((segment.transform.origin - previous_segment.transform.origin) / 2)

			# TODO: There is absolutely no documention on how to setup joints 
			# programatically! For example no "set_node_a" or about path. Maybe make
			# a tutorial?
			pin_joint.set_node_a(previous_segment.get_path())
			pin_joint.set_node_b(segment.get_path())

			add_child(pin_joint)
			
		segment.mode = RigidBody.MODE_RIGID

func _physics_process(delta: float) -> void:
	var root_node: Spatial = get_node_or_null(root_attachment)
	var leaf_node: Spatial = get_node_or_null(leaf_attachment)
	
	if root_node:
		segments[0].global_transform.origin = root_node.global_transform.origin
		segments[0].mode = RigidBody.MODE_STATIC
	
	if leaf_node:
		segments[segments.size() - 1].global_transform.origin = leaf_node.global_transform.origin
		segments[segments.size() - 1].mode = RigidBody.MODE_STATIC
		
func get_position_on_rope(distance: float) -> Vector3:
	distance = clamp(distance, 0, total_length)
	
	var percent: float = distance / total_length
	var index_float: float = percent * float(segment_count)
	var index: int = floor(index_float)
	var remainder: float = index_float - int(index_float)
	
	# TODO: This is messy and not elegant because I can't be bothered to do nice
	# maths right now.
	if index == segment_count - 1:		
		# If the length is the total length, then just place the point at the end manually.
		var segment: RigidBody = segments[index]
		var previous_segment: RigidBody = segments[index - 1]
		var direction = previous_segment.global_transform.origin.direction_to(segment.global_transform.origin)
		
		return segment.global_transform.origin + (direction * (segment_length / 2))
		
	var segment: RigidBody = segments[index]
	var next_segment: RigidBody = segments[index + 1]
	var direction = segment.global_transform.origin.direction_to(next_segment.global_transform.origin)

	return segment.global_transform.origin + (direction * remainder)
	
func get_distance_on_rope_from_segment(index: int) -> float:
	return (float(index) / (segments.size() - 1)) * total_length
		
func get_last_segment() -> RigidBody:
	return segments[segments.size() - 1]
	
func get_middle_segment() -> RigidBody:
	var index: int = floor((segments.size() / 2)) 
	return segments[index]

func get_closest_segment_index(position: Vector3) -> int:
	var closest_index: int
	var smallest_distance: float = INF
	
	for index in segments.size() - 1:
		var segment = segments[index]
		var distance = segment.global_transform.origin.distance_to(position)
		
		if distance < smallest_distance:
			smallest_distance = distance
			closest_index = index
			
	return closest_index
			
func get_closest_segment(position: Vector3) -> RigidBody:		
	return segments[get_closest_segment_index(position)]
