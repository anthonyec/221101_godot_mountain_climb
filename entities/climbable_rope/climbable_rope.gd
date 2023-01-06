class_name ClimbableRope
extends Node3D

@onready @export var target: Node3D
@export var max_length: float = 10

@onready var rope: RaycastRope = $RaycastRope

func _ready() -> void:
#	rope.target = target
	rope.target = get_parent().get_node("Player1")
	rope.joints.append(Vector3(-22.39463, 1.759457, 1.901428))
	rope.joints.append(Vector3(-22.35454, 1.595588, 3.910301))
	rope.joints.append(Vector3(-22.35104, 1.589803, 4.072887))
	rope.joints.append(Vector3(-24.26815, 1.529129, 4.145714))
	rope.joints.append(Vector3(-24.54599, 1.521866, 4.070595))
	
func _process(_delta: float) -> void:
	var pos = get_position_on_rope(1)
	DebugDraw.draw_cube(pos, 1, Color.YELLOW)
	
func get_position_on_rope(length: float) -> Vector3:
	length = clamp(length, 0, rope.total_length)
	
	var joints = get_joints()
	var totalled_length: float = 0
	var position_on_rope: Vector3 = Vector3.ZERO
	
	for index in range(joints.size()):
		if index == 0:
			continue
		
		var joint_a = joints[index - 1]
		var joint_b = joints[index]
		var segment_length = joint_a.distance_to(joint_b)
		
		totalled_length += segment_length
		
		if totalled_length >= length:
			var previous_index = index - 1
			var difference_in_length = totalled_length - length
			var direction_a_to_b = joint_a.direction_to(joint_b)
			
			position_on_rope = joint_b - (direction_a_to_b * difference_in_length)
			break
	
	return position_on_rope

func get_nearest_position_to(other_position: Vector3) -> Vector3:
	var joints_including_target = get_joints()
	var nearest_position: Vector3
	
	for index in range(joints_including_target.size()):
		if index == 0:
			continue
		
		var joint_a = joints_including_target[index - 1]
		var joint_b = joints_including_target[index]
		var distance_a_to_b = joint_a.distance_to(joint_b)
		var direction_a_to_b = joint_a.direction_to(joint_b) 
		var unnormalized_direction_to_other = other_position - joint_a
		
		var dot_product = clamp(
			unnormalized_direction_to_other.dot(direction_a_to_b), 
			0, 
			distance_a_to_b
		)
		var projected_position: Vector3 = joint_a + (direction_a_to_b * dot_product)
		
		if projected_position.distance_squared_to(other_position) < nearest_position.distance_squared_to(other_position):
			nearest_position = projected_position
		
	return nearest_position

# TODO: Fix this so raycast rope reports target as last joint.
func get_joints() -> Array[Vector3]:
	var joints_including_target: Array[Vector3] = rope.joints.duplicate()
	
	joints_including_target.append(rope.target.global_transform.origin)
	
	return joints_including_target
	
