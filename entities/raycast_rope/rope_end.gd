class_name RopeEnd
extends RigidBody3D

@export var rope: RaycastRope

func _physics_process(_delta: float) -> void:
	if not rope or not rope.has_joints():
		return
	
	var last_joint = rope.get_last_joint()
	var vertical_distance_to_last_joint = abs(global_transform.origin.y - last_joint.y)
	
	# Gentle amount of gravity to move it towards the last joint. Only do this 
	# if it's below the origin to stop it sliding backwards on the floor.
	if vertical_distance_to_last_joint > 1:
		apply_central_impulse(global_transform.origin.direction_to(rope.get_last_joint()) * 0.05)
	
	if rope.total_length > rope.max_length:
		var direction_to_end = global_transform.origin.direction_to(rope.target_position)
		var distance_to_end = global_transform.origin.distance_to(rope.target_position)

		apply_central_impulse(direction_to_end * distance_to_end)
