extends Node3D

@onready @export var root_node: Node3D
@onready @export var leaf_node: Node3D

@export var segment_count: int = 15
@export var segment_length: float = 0.5
@export var enable_blob: bool = false
@export var blob_position: float = 0
 
var start_position: float = (-segment_length / 2)

# NOTE: The radius of rigid bodies can't bee too small, like 0.1, otherwise
# the physics freak out.
var segments: Array[RigidBody3D] = []
var total_length: float

func _ready() -> void:	
	var segment_scene = preload("res://entities/Rope/Segment.tscn")
	
	total_length = segment_length * float(segment_count)
	
	for index in segment_count:
		var segment = segment_scene.instantiate()
		segments.append(segment)
		add_child(segment)
		
	for index in segments.size():
		var segment = segments[index] as RigidBody3D
		
		segment.transform.origin.z = start_position - (segment_length * index)
		
		if index > 0:
			var pin_joint: PinJoint3D = PinJoint3D.new()
			var previous_segment = segments[index - 1]

			pin_joint.transform.origin = previous_segment.transform.origin + ((segment.transform.origin - previous_segment.transform.origin) / 2)

			# TODO: There is absolutely no documention checked how to setup joints 
			# programatically! For example no "set_node_a" or about path. Maybe make
			# a tutorial?
			pin_joint.set_node_a(previous_segment.get_path())
			pin_joint.set_node_b(segment.get_path())

			add_child(pin_joint)

func _physics_process(delta: float) -> void:
	if root_node:
		segments[0].global_transform.origin = root_node.global_transform.origin
		segments[0].freeze = true
	
	if leaf_node:
		segments[segments.size() - 1].global_transform.origin = leaf_node.global_transform.origin
		segments[segments.size() - 1].freeze = true

# Return the position on the rope given a distance in world units. 
# E.g, a distance of 10 meters on a 20 meter rope will give a position halfway.
func get_position_on_rope(distance: float) -> Vector3:
	distance = clamp(distance, 0, total_length)
	
	var percent: float = distance / total_length
	
	# Don't use size - 1 otherwise the percent will be wrong. Not sure why.
	# TODO: Find out why to really understand.
	var index: float = floor(percent * float(segments.size()))
	var clamped_index: float = clamp(index, 0, segments.size() - 1)
	
	# Using hard-coded segment length will result in jumps between segments
	# because phyics will cause tiny gaps to appear between segments. This could be
	# fixed either by using "real-time" segment length or ensuring there are no gaps.
	var nearest_segment_length = index * segment_length
	var distance_in_segment = distance - nearest_segment_length
	
	var segment: RigidBody3D = segments[clamped_index]
	var direction = -segment.global_transform.basis.z
	
	# Subtract half the segment length because the pivot point of the segments 
	# is in the center. This makes it act like the pivot is at the start.
	var start_position = segment.global_transform.origin - (direction * (segment_length / 2))
	var end_position = start_position + (direction * segment_length)
	
	# TODO: Fix this. THis is done because index isn't subtracting 1.
	if distance == total_length:
		return end_position
	
	return start_position + (direction * distance_in_segment)
	
func get_distance_on_rope_from_segment(index: int) -> float:
	return (float(index) / (segments.size() - 1)) * total_length
		
func get_last_segment() -> RigidBody3D:
	return segments[segments.size() - 1]
	
func get_middle_segment() -> RigidBody3D:
	var index: int = floor((segments.size() / 2)  - 1) 
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
			
func get_closest_segment(position: Vector3) -> RigidBody3D:		
	return segments[get_closest_segment_index(position)]

