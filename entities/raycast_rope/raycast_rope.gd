class_name RaycastRope
extends Node3D

const WORLD_COLLISION_MASK: int = 1

@export var debug: bool = false
@onready @export var target: Node3D

@export var margin: float = 0.1
@export var max_length: float = 10
@export var edge_search_iterations: int = 20
@export var edge_search_distance_step: float = 0.2
@export var discard_joint_iterations: int = 20

var target_position: Vector3
var total_length: float = 0
var joints: Array[Vector3] = []
var edge_info: Array = []

func _ready() -> void:
	target_position = target.global_transform.origin
	joints.append(global_transform.origin)

func _process(_delta: float) -> void:
	target_position = target.global_transform.origin
	total_length = 0
	
	# Calculate the total length of the rope
	for index in joints.size():
		if index == 0:
			continue
			
		var previous_joint = joints[index - 1]
		var joint = joints[index]
		var distance_between_joints = previous_joint.distance_to(joint)
		
		total_length += distance_between_joints
		
	total_length += joints[joints.size() - 1].distance_to(target_position)
	
	# TODO: Yes I know this max length stuff is a mess, don't you think I know this!!!
	# Will be great if everything is in the joints array, including the target.
	if joints.size() == 1 and total_length >= max_length:
		var joint_a = joints[0]
		var joint_b = target.global_transform.origin
		var direction_a_to_b = joint_a.direction_to(joint_b)
		var difference = total_length - max_length

		target_position = joint_b - (direction_a_to_b * difference)
		
	if joints.size() > 1 and total_length >= max_length:
		var joint_a = joints[joints.size() - 1]
		var joint_b = target.global_transform.origin
		var direction_a_to_b = joint_a.direction_to(joint_b)
		var difference = total_length - max_length

		target_position = joint_b - (direction_a_to_b * difference)

	var t = get_last_edge_info()
	
	if not t.is_empty():
		DebugDraw.draw_cube(t.position, 0.3, Color.GREEN)
		DebugDraw.draw_ray_3d(t.position, t.normal, 1, Color.GREEN)
	
	# Debug draw rope
	for index in joints.size():
		DebugDraw.draw_cube(joints[index], 0.1, Color.PURPLE)
		
		if index > 0:
			DebugDraw.draw_line_3d(joints[index - 1], joints[index], Color.PURPLE)
			
	DebugDraw.draw_line_3d(joints[joints.size() - 1], target_position, Color.PURPLE)
	
	# Check the point between last third joint and target to see if it can be 
	# discarded, essentially unwinding the rope.
	if joints.size() > 1:
		var first_joint = joints[joints.size() - 2]
		
		# TODO: Maybe rename this stuff, Alex was right about my naming skills...
		var potentially_discardable_joint_index = joints.size() - 1
		var hit_between_joints = Raycast.intersect_ray(first_joint, target_position, WORLD_COLLISION_MASK)
		
		if hit_between_joints.is_empty():
			var middle_joint = joints[potentially_discardable_joint_index]
			var is_something_between_rope = false
			
			# The line of sight might be clear between the first and last joint,
			# but there may still be something in between them. This prevets the 
			# problem of discarding joints on thin objects.
			for index in range(discard_joint_iterations):
				var step = float(index) / discard_joint_iterations
				var hit_between_rope = Raycast.intersect_ray(
					middle_joint.lerp(first_joint, step), 
					middle_joint.lerp(target_position, step), 
					WORLD_COLLISION_MASK
				)
				
				if not hit_between_rope.is_empty():
					is_something_between_rope = true
					break
			
			if not is_something_between_rope:
				joints.remove_at(potentially_discardable_joint_index)
				edge_info.remove_at(potentially_discardable_joint_index - 1)
		
	# TODO: I think I saw another method that returns the size minus one somewhere. Replace with that maybe.
	var raycast_start_position = joints[joints.size() - 1]
	
	# TODO: Can this be done with one raycast? I saw in the docs about checking for back faces also.
	var hit_torwards_target = Raycast.intersect_ray(raycast_start_position, target_position, WORLD_COLLISION_MASK)
	var hit_torwards_origin = Raycast.intersect_ray(target_position, raycast_start_position, WORLD_COLLISION_MASK)
	
	if hit_torwards_target.is_empty() or hit_torwards_origin.is_empty():
		return

	# Add a bit of a "skin" to the hit position so hovers a bit above the surface
	hit_torwards_target.position = hit_torwards_target.position + (hit_torwards_target.normal * margin)
	hit_torwards_origin.position = hit_torwards_origin.position + (hit_torwards_origin.normal * margin)
	
	var average_edge_normal = (hit_torwards_target.normal + hit_torwards_origin.normal) / 2
	var edge_position: Vector3
	
	if debug:
		DebugDraw.draw_cube(hit_torwards_target.position, 0.1, Color.WHITE)
		DebugDraw.draw_cube(hit_torwards_origin.position, 0.1, Color.BLACK)
	
		DebugDraw.draw_ray_3d(hit_torwards_target.position, hit_torwards_target.normal, 1, Color.WHITE)
		DebugDraw.draw_ray_3d(hit_torwards_origin.position, hit_torwards_origin.normal, 1, Color.BLACK)
		DebugDraw.draw_ray_3d(hit_torwards_target.position.lerp(hit_torwards_origin.position, 0.5), average_edge_normal, 2, Color.YELLOW)
	
	
	for index in range(edge_search_iterations):
		# TODO: Come up with a better name for the search line between these normal. 
		# I don't like A and B, maybe in and out or something?
		var position_a: Vector3 = hit_torwards_target.position + (hit_torwards_target.normal * index * edge_search_distance_step)
		var position_b: Vector3 = hit_torwards_origin.position + (hit_torwards_origin.normal * index * edge_search_distance_step)
		var hit_between_normals = Raycast.intersect_ray(position_a, position_b, WORLD_COLLISION_MASK)
	
		if hit_between_normals.is_empty():
			edge_position = position_a.lerp(position_b, 0.5) + (average_edge_normal * margin)
			break
	
	DebugDraw.draw_cube(edge_position, 0.1, Color.WHITE)
	
	# TODO: Improve this check.
	if edge_position != Vector3.ZERO:
		joints.append(edge_position)
		
		# TODO: Combine joints and edge info? It's a lot of data. 
		# Is there a way to only keep the last one?
		edge_info.append({
			"position": edge_position,
			"normal": average_edge_normal
		})
	else:
		push_warning("Edge position was Vector3.ZERO")

func get_last_edge_info() -> Dictionary:
	if edge_info.is_empty():
		return {}
	
	return edge_info[edge_info.size() - 1]
	
func get_last_joint() -> Vector3:
	return joints[joints.size() - 1]
	
func get_position_on_rope(length: float) -> Vector3:
	var clamped_length = clamp(length, 0, total_length)
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
		
		if totalled_length >= clamped_length:
			var difference_in_length = totalled_length - clamped_length
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

# TODO: Fix this so raycast rope reports target as last joint?
func get_joints() -> Array[Vector3]:
	var joints_including_target: Array[Vector3] = joints.duplicate()
	
	joints_including_target.append(target_position)
	
	return joints_including_target
