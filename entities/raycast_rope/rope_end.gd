class_name RopeEnd
extends RigidBody3D

@export var rope: RaycastRope = null

func _ready() -> void:
	assert(rope, "Rope end needs raycast rope assigned")
	
	connect("body_entered", on_body_entered)

func _physics_process(_delta: float) -> void:
	apply_central_impulse(global_transform.origin.direction_to(rope.get_last_joint()) * 0.05)
	
	if rope.total_length > rope.max_length:
		var direction_to_end = global_transform.origin.direction_to(rope.target_position)
		var distance_to_end = global_transform.origin.distance_to(rope.target_position)

		apply_central_impulse(direction_to_end * distance_to_end)

func on_body_entered(_body: Node) -> void:
	pass
