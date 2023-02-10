class_name Player
extends CharacterBody3D

@export_range(1, 2) var player_number: int = 1

# TODO: Find out if I need @onready annotation. Seems to work without but maybe 
# it's safer. I originally saw it in this video: https://youtu.be/8BgAeN4RRR4?t=150
@export var companion: Node3D

@export_group("Movement")
@export var gravity: float = 40
@export var jump_strength: float = 8
@export var rotation_speed: float = 20
@export var walk_speed: float = 5
@export var sprint_speed: float = 8
@export var climb_speed: float = 2
@export var ground_turn_speed: float = 10.0
@export var air_turn_speed: float = 2.5

@export_group("Ledge Grabbing")
@export var max_floor_angle: float = 40
@export var hang_distance_from_wall: float = 0.3
@export var grab_height: float = 1.2
@export var search_distance: float = 0.7

@onready var collision: CollisionShape3D = $Collision
@onready var abseil_collision: CollisionShape3D = $AbseilCollision
@onready var model: Node3D = $Model
@onready var animation: AnimationPlayer = $Model/player_model/AnimationPlayer
@onready var pickup_collision: Area3D = $PickupArea
@onready var stamina: Stamina = $Stamina as Stamina
@onready var balance: Balance = $Balance as Balance
@onready var inventory: Inventory = $Inventory as Inventory
@onready var state_machine: StateMachine = $StateMachine as StateMachine
@onready var ledge: LedgeSearcher = $LedgeSearcher as LedgeSearcher

var input_direction: Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	DebugDraw.set_text("player " + str(player_number) + " speed", velocity.length())
	DebugDraw.set_text("player " + str(player_number) + " state", state_machine.get_current_state_path())
	DebugDraw.set_text("player " + str(player_number) + " animation", animation.current_animation)
	DebugDraw.set_text("player " + str(player_number) + " woods", inventory.items.get("wood", 0))
	
	# TODO: This seems broken at 45 degree angles, Godot RC.1 bug?
	input_direction = Input.get_vector(
		get_action_name("move_left"),
		get_action_name("move_right"),
		get_action_name("move_forward"),
		get_action_name("move_backward")
	)
	
	if Input.is_action_just_pressed(get_action_name("debug")):
		if state_machine.current_state.name != "Debug":
			state_machine.transition_to("Debug")
			return
		else:
			state_machine.transition_to("Move")
			return

# Get the action name with player number suffix.
func get_action_name(action_name: String) -> String:
	return action_name + "_" + str(player_number)

# Get the active cameras global Y axis rotation and use that to rotate the
# direction vector.
func transform_direction_to_camera_angle(direction: Vector3) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var camera_angle_y = camera.global_transform.basis.get_euler().y
	return direction.rotated(Vector3.UP, camera_angle_y)
	
func face_towards_instantly(target: Vector3) -> void:
	look_at(target, Vector3.UP)
	global_rotation.x = 0
	global_rotation.z = 0
		
# Like `look_at` but only on the Y axis.
# TODO: Add `speed` argument here to lerp rotation over time?
func face_towards(target: Vector3, speed: float = 0.0, delta: float = 0.0) -> void:
	if global_transform.origin == target:
		return
		
	if is_zero_approx(speed):
		look_at(target, Vector3.UP)
		global_rotation.x = 0
		global_rotation.z = 0
	else:
		# From: https://github.com/JohnnyRouddro/3d_rotate_direct_constant_smooth/blob/master/rotate.gd
		var direction = global_transform.origin.direction_to(target)
		global_rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), speed * delta)
		
	
func snap_to_floor() -> void:
	var iterations: int = 0
	
	while iterations < 10:
		move_and_slide()
		
		if is_on_floor():
			break
			
		global_transform.origin += Vector3.DOWN * 0.01
		iterations += 1

func stand_at_position(stand_position: Vector3) -> void:
	global_transform.origin = stand_position + (Vector3.UP * 0.95)

func get_offset_position(forward: float = 0.0, up: float = 0.0) -> Vector3:
	return global_transform.origin - (global_transform.basis.z * forward) + (global_transform.basis.y * up)
	
func get_ledge(direction: Vector3) -> Dictionary:
	var wall_hit = Raycast.cast_in_direction(global_transform.origin, direction, search_distance)
	
	if wall_hit.is_empty():
		return { "error": "no_wall_hit" }

	var floor_hit = Raycast.cast_in_direction(
		wall_hit.position - (wall_hit.normal * 0.1) + (Vector3.UP * grab_height), 
		Vector3.DOWN, 
		grab_height
	)
	
	if floor_hit.is_empty():
		return { "error": "no_floor_hit" }
		
	# Edge normal is the wall normal with the Y component flattened to zero.
	var edge_normal = Vector3(wall_hit.normal.x, 0, wall_hit.normal.z).normalized()
	
	var start_edge_sweep_position: Vector3 = floor_hit.position + floor_hit.normal - (edge_normal * 0.1)
	var end_edge_sweep_position: Vector3 = floor_hit.position + floor_hit.normal + (edge_normal * hang_distance_from_wall * 2)
	var edge_hit = Raycast.sweep_find_edge(start_edge_sweep_position, end_edge_sweep_position, -floor_hit.normal, 1.2, {
		"exclude": [self],
		"collision_mask": 1
	})
	
	return {
		"position": edge_hit.position,
		"normal": edge_normal,
		"direction": edge_normal.cross(-floor_hit.normal)
	}

# TODO: When find_ledge_info fails, return an error and a reason why it failed. This is 
# a somewhat chunky change though as I wont be able to check for is_empty when failed
func find_ledge_info() -> Dictionary:
	# TODO: Sweep the fan upwards to catch walls above the players head. Use the last hit as the result.
	var wall_hit = Raycast.fan_out(
		# TODO: Sync this with suggestion hang position. Hand postion can't be lower than this.
		# TODO: I've just put 0.2 to avoid glitches when it probably should be 0.25. Fix this later hehe.
		global_transform.origin + (global_transform.basis.y * 0.2),
		-global_transform.basis.z, 
		search_distance,
	)
	
	if wall_hit.is_empty():
		return { "error": "no_wall_hit" }
		
	var wall_angle = wall_hit.normal.angle_to(Vector3.UP)
	
	# This is a naive check to see if walls are "wall like". It avoids glitches
	# with tilted platforms. Though ideally `intersect_cylinder` would correctly.
	# TODO: This has problems with walls that slope outwards at the bottom.
	# Might need to be a seperate kind of grab.
	if wall_angle < deg_to_rad(80) or wall_angle > deg_to_rad(120):
		return { "error": "bad_wall_angle" }
	
	var wall_angle_to_player_forward = wall_hit.normal.angle_to(global_transform.basis.z)
	
	if wall_angle_to_player_forward > deg_to_rad(60):
		return { "error": "bad_wall_angle_relation_to_player" }
		
	var direction_to_player = global_transform.origin.direction_to(Vector3(wall_hit.position.x, 0, wall_hit.position.z))
	var floor_hit = Raycast.cast_in_direction(wall_hit.position + (direction_to_player * 0.1) + (Vector3.UP * grab_height), Vector3.DOWN, grab_height)
	
	if floor_hit.is_empty():
		return { "error": "no_floor_hit" }
	
	var floor_normal: Vector3 = floor_hit.normal
	var floor_angle = abs(floor_normal.angle_to(Vector3.UP))
	
	if (floor_angle > deg_to_rad(max_floor_angle)):
		return { "error": "bad_floor_angle" }

	# Edge normal is the wall normal with the Y component flattened to zero.
	var edge_normal = Vector3(wall_hit.normal.x, 0, wall_hit.normal.z)
	
	var start_edge_sweep_position: Vector3 = floor_hit.position + floor_hit.normal - (edge_normal * 0.1)
	var end_edge_sweep_position: Vector3 = floor_hit.position + floor_hit.normal + (edge_normal * hang_distance_from_wall * 2)
#
	var edge_hit = Raycast.sweep_find_edge(start_edge_sweep_position, end_edge_sweep_position, -floor_hit.normal, 1.2, {
		"exclude": [self],
		"collision_mask": 1
	})

	if edge_hit.is_empty():
		return { "error": "no_edge_hit" }

	# TODO: Make this better. Potentially a deep/long rectangle that is aligned to the floor normal.
	var hand_hit = Raycast.intersect_cylinder(edge_hit.position + edge_hit.normal * 0.1, 0.1, 0.2, 1)
	
	if not hand_hit.is_empty():
		return { "error": "no_space_for_hand" }
		
	var edge_direction = edge_normal.cross(floor_hit.normal)
	
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
	
	var suggested_hang_position = edge_hit.position + (edge_normal * hang_distance_from_wall) + (Vector3.DOWN * 0.25) # TODO: Tidy up with var name for player_height / 2
	
	# TODO: Implement exlcuding self. The last argument does not work hehe.
	# TODO: Find out why the cylinder sometimes in the same position of the ledge, which seems very wrong.
	var hang_position_hit = Raycast.intersect_cylinder(suggested_hang_position, 1.5, 0.25, 1, [self])

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
		"edge_normal": edge_normal,
		"has_reached_left_bound": has_reached_left_bound,
		"has_reached_right_bound": has_reached_right_bound
	}

func set_collision_mode(mode: String) -> void:
	if mode == "abseil":
		collision.disabled = true
		abseil_collision.disabled = false
		
	if mode == "default":
		collision.disabled = false
		abseil_collision.disabled = true
