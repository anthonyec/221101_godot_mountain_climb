class_name AbseilRope
extends Node3D

@export var host_player: Player

@onready var rope: RaycastRope = $RaycastRope as RaycastRope
@onready var end: RopeEnd = $RopeEnd as RopeEnd

func _ready() -> void:
	assert(host_player, "Need a host player assigned")
	
	end.rope = rope
	rope.target = end

func throw() -> void:
	var force_forward = -host_player.global_transform.basis.z * 7
	var force_up = host_player.global_transform.basis.y * 2

	end.apply_central_impulse(force_forward + force_up)
