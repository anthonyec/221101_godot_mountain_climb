class_name AbseilRope
extends Node3D

@export var host: Node3D

@onready var rope: RaycastRope = $RaycastRope as RaycastRope
@onready var end: RopeEnd = $RopeEnd as RopeEnd

var grabbed_by: Player = null

func _ready() -> void:
	assert(host, "Need a host assigned, such as a player or other Node3D")
	
	end.rope = rope
	rope.target = end
	
func _process(_delta: float) -> void:
	if grabbed_by:
		(end.get_node("CollisionShape3D") as CollisionShape3D).disabled = true
		end.global_transform.origin = grabbed_by.global_transform.origin
	else:
		(end.get_node("CollisionShape3D") as CollisionShape3D).disabled = false

func throw() -> void:
	var force_forward = -host.global_transform.basis.z * 7
	var force_up = host.global_transform.basis.y * 2

	end.apply_central_impulse(force_forward + force_up)

func grab(player_who_grabs: Player) -> void:
	rope.target = player_who_grabs
	grabbed_by = player_who_grabs
	
func release() -> void:
	rope.target = end
	grabbed_by = null

# TODO: Not get I have to forward all these as getters but oh well. I don't wanna
# have things access this as `rope.rope` so this is the best way atm.
func get_joints() -> Array[Vector3]:
	return rope.joints
	
func get_joint_count() -> int:
	return rope.joints.size()
	
func get_target_position() -> Vector3:
	return rope.target_position

func get_total_length() -> float:
	return rope.total_length
	
func get_max_length() -> float:
	return rope.max_length

func get_nearest_position_to(other_position: Vector3) -> Vector3:
	return rope.get_nearest_position_to(other_position)
	
func get_last_joint() -> Vector3:
	return rope.get_last_joint()
	
func get_last_edge_info() -> Dictionary:
	return rope.get_last_edge_info()
