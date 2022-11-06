extends Spatial

export var segment_count: int = 15
export var segment_length = 0.5
export var root_attachment: NodePath
export var leaf_attachment: NodePath

var start_position: float = (-segment_length / 2)

# NOTE: The radius of rigid bodies can't bee too small, like 0.1, otherwise
# the physics freak out.
var segments = []

func _ready() -> void:	
	var segment_scene = preload("res://entities/Rope/Segment.tscn")
	
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
		
func get_last_segment() -> RigidBody:
	return segments[segments.size() - 1]
	
func get_middle_segment() -> RigidBody:
	var index: int = floor((segments.size() / 2)) 
	return segments[index]
