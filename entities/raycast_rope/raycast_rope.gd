class_name RaycastRope
extends Node3D

const WORLD_COLLISION_MASK: int = 1

@onready @export var target: Node3D

@export var margin: float = 0.1
@export var edge_search_iterations: int = 10
@export var edge_search_distance_step: float = 0.1

var joints: Array[Vector3] = []

func _ready() -> void:
	joints.append(global_transform.origin)

func _process(delta: float) -> void:
	# Debug draw rope
	for index in joints.size():
		DebugDraw.draw_cube(joints[index], 0.1, Color.PURPLE)
		
		if index > 0:
			DebugDraw.draw_line_3d(joints[index - 1], joints[index], Color.PURPLE)
			
	DebugDraw.draw_line_3d(joints[joints.size() - 1], target.global_transform.origin, Color.PURPLE)
	
	# Check the point between last third joint and target to see if it can be 
	# discarded, esentially unwinding the rope.
	if joints.size() > 1:
		var first_joint = joints[joints.size() - 2]
		
		# TODO: Maybe rename this stuff, Alex was right about my naming skills...
		var potentially_discardable_joint_index = joints.size() - 1
		
		var hit_between_joints = Raycast.intersect_ray(first_joint, target.global_transform.origin, WORLD_COLLISION_MASK)
		
		if hit_between_joints.is_empty():
			joints.remove_at(potentially_discardable_joint_index)
		
	# TODO: I think I saw another method that returns the size minus one somewhere. Replace with that maybe.
	var raycast_start_position = joints[joints.size() - 1]
	
	# TODO: Can this be done with one raycast? I saw in the docs about checking for back faces also.
	var hit_torwards_target = Raycast.intersect_ray(raycast_start_position, target.global_transform.origin, WORLD_COLLISION_MASK)
	var hit_torwards_origin = Raycast.intersect_ray(target.global_transform.origin, raycast_start_position, WORLD_COLLISION_MASK)
	
	if hit_torwards_target.is_empty() or hit_torwards_origin.is_empty():
		return

	# Add a bit of a "skin" to the hit position so hovers a bit above the surface
	hit_torwards_target.position = hit_torwards_target.position + (hit_torwards_target.normal * margin)
	hit_torwards_origin.position = hit_torwards_origin.position + (hit_torwards_origin.normal * margin)
	
	var average_edge_normal = (hit_torwards_target.normal + hit_torwards_origin.normal) / 2
	var edge_position: Vector3
	
	for index in range(edge_search_iterations):
		# TODO: Come up with a better name for the search line between these normal. 
		# I don't like A and B, maybe in and out or something?
		var position_a: Vector3 = hit_torwards_target.position + (hit_torwards_target.normal * index * edge_search_distance_step)
		var position_b: Vector3 = hit_torwards_origin.position + (hit_torwards_origin.normal * index * edge_search_distance_step)
		var hit_between_normals = Raycast.intersect_ray(position_a, position_b, WORLD_COLLISION_MASK)
	
		if hit_between_normals.is_empty():
			edge_position = position_a.lerp(position_b, 0.5) + (average_edge_normal * margin)
			break
	
	# TODO: Can there ever be no edge position? Might be a pointles check or could be a better check.
	if edge_position:
		joints.append(edge_position)
