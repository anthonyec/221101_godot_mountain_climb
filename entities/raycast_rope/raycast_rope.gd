class_name RaycastRope
extends Node3D

@onready @export var target: Node3D

@export var margin: float = 0.1

var joints: Array[Vector3] = []

func _ready() -> void:
	Raycast.debug = true
	joints.append(global_transform.origin)

func _process(delta: float) -> void:
	# Debug draw rope
	for index in joints.size():
		DebugDraw.draw_cube(joints[index], 0.1, Color.PURPLE)
		
		if index > 0:
			DebugDraw.draw_line_3d(joints[index - 1], joints[index], Color.PURPLE)
		
	# TODO: I think I saw another method that returns the size minus one somewhere. Replace with that maybe.
	var raycast_start_position = joints[joints.size() - 1]
	var hit = Raycast.intersect_ray(raycast_start_position, target.global_transform.origin, 1)
	
	if hit.is_empty():
		return
	
	# Add a bit of a "skin" to the hit position so hovers a bit above the surface
	hit.position = hit.position + (hit.normal * margin)
	
#	joints.append(hit.position)
	DebugDraw.draw_cube(hit.position, 0.1, Color.WHITE)
	
	var normal_left = hit.normal.cross(Vector3.UP)
	var normal_right = hit.normal.cross(Vector3.DOWN)
	var normal_up = hit.normal.cross(normal_right)
	var normal_down = hit.normal.cross(normal_left)
	
	DebugDraw.draw_ray_3d(hit.position, normal_left, 1, Color.WHITE)
	DebugDraw.draw_ray_3d(hit.position, normal_right, 1, Color.BLACK)
	DebugDraw.draw_ray_3d(hit.position, normal_up, 1, Color.DARK_GREEN)
	DebugDraw.draw_ray_3d(hit.position, normal_down, 1, Color.DARK_GOLDENROD)

	for index in range(10):
		var potential_joint_position = hit.position + normal_right * 0.1 * index
		var potential_joint_hit = Raycast.intersect_ray(potential_joint_position, target.global_transform.origin, 1)
		
		if potential_joint_hit.is_empty():
			joints.append(potential_joint_position)
			break
		
		DebugDraw.draw_cube(potential_joint_position, 0.1, Color.RED)

