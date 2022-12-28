# TODO: Rename this to `Player` once it replaces the old one.
class_name PlayerFSM
extends CharacterBody3D

@export_range(1, 2) var player_number: int = 1

# TODO: Find out if I need @onready annotation. Seems to work without but maybe 
# it's safer. I originally saw it in this video: https://youtu.be/8BgAeN4RRR4?t=150
@onready @export var companion: PlayerFSM

@export_group("Movement")
@export var gravity: float = 40
@export var jump_strength: float = 8
@export var rotation_speed: float = 20
@export var walk_speed: float = 5
@export var sprint_speed: float = 8
@export var climb_speed: float = 2

@export_group("Ledge Grabbing")
@export var max_floor_angle: float = 40
@export var hang_distance_from_wall: float = 0.3
@export var grab_height: float = 1.2
@export var search_distance: float = 1

@onready var collision: CollisionShape3D = $Collision
@onready var model: Node3D = $Model
@onready var animation: AnimationPlayer = $Model/godot_model/AnimationPlayer
@onready var pickup_collision: Area3D = $PickupArea
@onready var stamina: Stamina = $Stamina as Stamina
@onready var balance: Balance = $Balance as Balance
@onready var inventory: Inventory = $Inventory
@onready var state_machine: StateMachine = $StateMachine as StateMachine

var input_direction: Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	DebugDraw.set_text("player " + str(player_number) + " state", state_machine.current_state.name)
	DebugDraw.set_text("player " + str(player_number) + " animation", animation.current_animation)
	DebugDraw.set_text("player " + str(player_number) + " woods", inventory.items.get("wood", 0))
	
	input_direction = Input.get_vector(
		get_action_name("move_left"),
		get_action_name("move_right"),
		get_action_name("move_forward"),
		get_action_name("move_backward")
	)

# Get the action name with player number suffix.
func get_action_name(action_name: String) -> String:
	return action_name + "_" + str(player_number)

# Get the active cameras global Y axis rotation and use that to rotate the
# direction vector.
func transform_direction_to_camera_angle(direction: Vector3) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var camera_angle_y = camera.global_transform.basis.get_euler().y
	return direction.rotated(Vector3.UP, camera_angle_y)

# Like `look_at` but only on the Y axis.
# TODO: Add `speed` argument here to lerp rotation over time?
func face_towards(target: Vector3) -> void:
	if global_transform.origin == target:
		return

	look_at(target, Vector3.UP)
	global_rotation.x = 0
	global_rotation.z = 0
	
func get_offset_position(forward: float = 0.0, up: float = 0.0) -> Vector3:
	return global_transform.origin - (global_transform.basis.z * forward) + (global_transform.basis.y * up)

func find_ledge_info() -> Dictionary:
	# TODO: Sweep the fan upwards to catch walls above the players head. Use the last hit as the result.
	var wall_hit = Raycast.fan_out(
		global_transform.origin + (global_transform.basis.y * 0.25), # TODO: Sync this with suggestion hang position. Hand postion can't be lower than this.
		-global_transform.basis.z, 
		search_distance,
	)
	
	if wall_hit.is_empty():
		return {}
		
	var wall_angle = wall_hit.normal.angle_to(Vector3.UP)
	
	# This is a naive check to see if walls are "wall like". It avoids glitches
	# with tilted platforms. Though ideally `intersect_cylinder` would correctly.
	# TODO: This has problems with walls that slope outwards at the bottom.
	# Might need to be a seperate kind of grab.
	if wall_angle < deg_to_rad(80) or wall_angle > deg_to_rad(120):
		return {}
		
	var direction_to_player = global_transform.origin.direction_to(Vector3(wall_hit.position.x, 0, wall_hit.position.z))
	var floor_hit = Raycast.cast_in_direction(wall_hit.position + (direction_to_player * 0.1) + (Vector3.UP * grab_height), Vector3.DOWN, grab_height)
	
	if floor_hit.is_empty():
		return {}
	
	var floor_normal: Vector3 = floor_hit.normal
	var floor_angle = abs(floor_normal.angle_to(Vector3.UP))
	
	if (floor_angle > deg_to_rad(max_floor_angle)):
		return {}

	var edge_hit = {}
	var edge_sweep_iterations = 15 # TODO: Move somewhere else
	var start_edge_sweep_position: Vector3 = floor_hit.position + floor_hit.normal
	var end_edge_sweep_position: Vector3 = floor_hit.position + floor_hit.normal + (wall_hit.normal * hang_distance_from_wall * 2)
	
	for index in edge_sweep_iterations:
		var sweep_position = start_edge_sweep_position.lerp(end_edge_sweep_position, float(index) / float(edge_sweep_iterations))
		var sweep_hit = Raycast.cast_in_direction(sweep_position, -floor_hit.normal, 1.2, 1)
		
		if sweep_hit and sweep_hit.collider != self:
			edge_hit = sweep_hit
		
		if sweep_hit.is_empty():
			break
	
	if edge_hit.is_empty():
		return {}
		
	var edge_direction = wall_hit.normal.cross(floor_hit.normal)
	
	var floor_left_bound = Raycast.cast_in_direction(
		edge_hit.position + (Vector3.UP * 0.5) + (edge_direction * 0.25), # TODO: Replace with player width / 2 var.
		Vector3.DOWN,
		search_distance
	)
	var floor_right_bound = Raycast.cast_in_direction(
		edge_hit.position + (Vector3.UP * 0.5) - (edge_direction * 0.25), # TODO: Replace with player width / 2 var.
		Vector3.DOWN,
		search_distance
	)
	
	if Raycast.debug:
		DebugDraw.draw_cube(edge_hit.position, 0.2, Color.BLUE)
		DebugDraw.draw_ray_3d(edge_hit.position - (edge_direction * 0.25), edge_direction, 0.5, Color.BLUE)
	
	var suggested_hang_position = edge_hit.position + (wall_hit.normal * hang_distance_from_wall) + (Vector3.DOWN * 0.25) # TODO: Tidy up with var name for player_height / 2
	
	# TODO: Implement exlcuding self. The last argument does not work hehe.
	# TODO: Find out why the cylinder sometimes in the same position of the ledge, which seems very wrong.
	var hang_position_hit = Raycast.intersect_cylinder(suggested_hang_position, 1.5, 0.25, 1)

	var is_hang_position_blocked = false
	
	for collision in hang_position_hit:
		if collision.collider != self:
			is_hang_position_blocked = true
			break
	
	if is_hang_position_blocked:
		return {}
		
	var has_reached_left_bound = floor_left_bound.is_empty() or rad_to_deg(floor_left_bound.normal.angle_to(Vector3.UP)) > max_floor_angle
	var has_reached_right_bound = floor_right_bound.is_empty() or rad_to_deg(floor_right_bound.normal.angle_to(Vector3.UP)) > max_floor_angle

	return {
		"hang_position": suggested_hang_position,
		"floor": floor_hit,
		"wall": wall_hit,
		"edge": edge_hit,
		"edge_direction": edge_direction,
		"has_reached_left_bound": has_reached_left_bound,
		"has_reached_right_bound": has_reached_right_bound
	}
