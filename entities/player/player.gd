class_name Player
extends CharacterBody3D

const WORLD_COLLISION_MASK: int = 1

@export var debug: bool = false
@export_range(1, 2) var player_number: int = 1

@export var companion: Node3D
@export var height: float = 2.0

@export_group("Movement")
@export var gravity: float = 40
@export var jump_height: float = 1.5 # meters
@export var fall_multipler: float = 1.25
@export var rotation_speed: float = 20
@export var walk_speed: float = 5
@export var sprint_speed: float = 8
@export var climb_speed: float = 2
@export var ground_turn_speed: float = 10.0
@export var air_turn_speed: float = 2.5

@export_group("Ledge Grabbing")
@export var shimmy_speed: float = 2.0
@export var max_floor_angle: float = 40
@export var hang_distance_from_wall: float = 0.3
@export var grab_height: float = 1.2
@export var body_width: float = 0.75
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

enum InputType {
	CONTROLLER,
	KEYBOARD
}

var input_type: InputType = InputType.KEYBOARD
var input_direction: Vector2 = Vector2.ZERO

func get_state_properties(state: State) -> Dictionary:
	var properties = {}
	var list = state.get_property_list()
	
	list = list.filter(func(property): 
		return property.type == TYPE_VECTOR3 or property.type == TYPE_INT or property.type == TYPE_FLOAT or property.type == TYPE_ARRAY
	)
	
	var index: int = 0
	
	for property in list:
		var value = state[property.name]
		properties[property.name] = value
	
	return properties
	
func draw_transform(player_transform: Transform3D) -> void:
	DebugDraw.draw_box(player_transform.origin, Vector3(0.3, 2, 0.3), Color.RED)
	
func debug_draw_vector(player_transform: Transform3D, direction: Vector3, color: Color) -> void:
	DebugDraw.draw_ray_3d(player_transform.origin, direction, 1, color)

func _on_state_entered(state: State, params: Dictionary) -> void:
	DebugFrames.add({
		"title": state.name + " enter",
		"params": params,
		"node_properties": get_state_properties(state)
	})
	
func _on_state_exited(state: State) -> void:
	DebugFrames.add({
		"title": state.name + " exit"
	})

func _on_state_updated(state: State) -> void:
	DebugFrames.add({
		"title": state.name + " update",
		"node_properties": get_state_properties(state),
		"draw_transform": draw_transform.bind(global_transform),
		"draw_input_direction": debug_draw_vector.bind(
			global_transform, 
			transform_direction_to_camera_angle(Vector3(input_direction.x, 0, input_direction.y)), 
			Color.WHITE
		),
		"draw_velocity_direction": debug_draw_vector.bind(
			global_transform, 
			velocity, 
			Color.CYAN
		),
		"draw_player_direction": debug_draw_vector.bind(
			global_transform, 
			-global_transform.basis.z, 
			Color.BLUE
		)
	})
	
func _on_state_physics_updated(state: State) -> void:
	DebugFrames.add({
		"title": state.name + " physics_update",
		"node_properties": get_state_properties(state)
	})
	
func _on_state_inputed(state: State) -> void:
	DebugFrames.add({
		"title": state.name + " input"
	})
	
func _on_state_transition_requested(state_name: String, params: Dictionary) -> void:
	DebugFrames.add({
		"title": "[transition_to] " + state_name,
		"params": params,
	})
	
func _on_state_deferred_transition_requested(state_name: String, _params_callback: Callable) -> void:
	DebugFrames.add({
		"title": "[deferred_transition_to] " + state_name
	})

func _ready() -> void:
	if player_number == 2:
		state_machine.connect("state_transition_requested", _on_state_transition_requested)
		state_machine.connect("state_deferred_transition_requested", _on_state_deferred_transition_requested)
		state_machine.connect("state_entered", _on_state_entered)
		state_machine.connect("state_exited", _on_state_exited)
		state_machine.connect("state_updated", _on_state_updated)
		state_machine.connect("state_physics_updated", _on_state_physics_updated)
		state_machine.connect("state_inputed", _on_state_inputed)

func _process(_delta: float) -> void:
	DebugDraw.set_text("player " + str(player_number))
#	DebugDraw.set_text("player " + str(player_number) + " speed", velocity.length())
#	DebugDraw.set_text("player " + str(player_number) + " state", state_machine.get_current_state_path())
#	DebugDraw.set_text("player " + str(player_number) + " animation", animation.current_animation)
#	DebugDraw.set_text("player " + str(player_number) + " woods", inventory.items.get("wood", 0))
#	DebugDraw.set_text("player " + str(player_number) + " input", InputType.keys()[input_type])
	
	DebugDraw.set_text("velocity.y", global_transform.origin.y)
	
	if Input.is_action_just_pressed(get_action_name("debug")):
		if state_machine.current_state.name != "Debug":
			state_machine.transition_to("Debug")
			return
		else:
			state_machine.transition_to("Move")
			return

func _input(event: InputEvent) -> void:
	var is_move_left_action = event.get_action_strength(get_action_name("move_left")) > 0
	var is_move_right_action = event.get_action_strength(get_action_name("move_right")) > 0
	var is_move_forward_action = event.get_action_strength(get_action_name("move_forward")) > 0
	var is_move_backward_action = event.get_action_strength(get_action_name("move_backward")) > 0
	
	var is_movement_action = is_move_left_action or is_move_right_action or is_move_forward_action or is_move_backward_action
	
	if is_movement_action and event is InputEventKey:
		input_type = InputType.KEYBOARD
		
	if is_movement_action and event is InputEventJoypadMotion:
		input_type = InputType.CONTROLLER
		
	input_direction = Input.get_vector(
		get_action_name("move_left"),
		get_action_name("move_right"),
		get_action_name("move_forward"),
		get_action_name("move_backward")
	)

var floor_normal_lerped: Vector3 = Vector3.ZERO
var align_to_floor_amount: float = 0.7

func align_model_to_floor(delta: float) -> void:
	var floor_hit = Raycast.cast_in_direction(global_transform.origin, Vector3.DOWN, height, WORLD_COLLISION_MASK)
	
	if floor_hit.is_empty():
		return
	
	floor_normal_lerped += (floor_hit.normal - floor_normal_lerped) * delta * 5.0
	
	var floor_aligned_forward: Vector3 = Plane(floor_normal_lerped).project(global_transform.basis.z).normalized()
	var floor_aligned_right: Vector3 = floor_normal_lerped.cross(floor_aligned_forward).normalized()
	var model_basis: Basis = Basis(floor_aligned_right, floor_normal_lerped, floor_aligned_forward).orthonormalized()
	var model_position: Vector3 = floor_hit.position + (floor_normal_lerped.lerp(Vector3.UP, align_to_floor_amount))
	
	model_basis = model_basis.slerp(global_transform.basis, align_to_floor_amount)
	
	model.global_transform.basis = model_basis
	model.global_transform.origin = model_position
	
	if debug:
		DebugDraw.draw_ray_3d(floor_hit.position, model_basis.x, 2, Color.RED)
		DebugDraw.draw_ray_3d(floor_hit.position, model_basis.y, 2, Color.GREEN)
		DebugDraw.draw_ray_3d(floor_hit.position, model_basis.z, 2, Color.CYAN)
		DebugDraw.draw_ray_3d(floor_hit.position, floor_normal_lerped, 3, Color.WHITE)

func reset_model_alignment() -> void:
	model.transform.basis = Basis.IDENTITY
	model.transform.origin = Vector3.ZERO

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

func stand_at_position(stand_position: Vector3) -> void:
	global_transform.origin = stand_position + (Vector3.UP * 0.95)

func get_offset_position(forward: float = 0.0, up: float = 0.0) -> Vector3:
	return global_transform.origin - (global_transform.basis.z * forward) + (global_transform.basis.y * up)

func set_collision_mode(mode: String) -> void:
	if mode == "abseil":
		collision.disabled = true
		abseil_collision.disabled = false
		
	if mode == "default":
		collision.disabled = false
		abseil_collision.disabled = true
		
func is_on_ground() -> bool:
	var floor_hit = Raycast.cast_in_direction(global_transform.origin, Vector3.DOWN, height, WORLD_COLLISION_MASK)
	
	if floor_hit.is_empty():
		return false
	
	var feet_position = global_transform.origin.y - (height / 2)
	
	return floor_hit.position.y >= feet_position
	
func is_near_ground() -> bool:
	var floor_hit = Raycast.cast_in_direction(global_transform.origin, Vector3.DOWN, height, WORLD_COLLISION_MASK)
	
	if floor_hit.is_empty():
		return false
	
	return true 
	
func snap_to_ground() -> void:
	var floor_hit = Raycast.cast_in_direction(global_transform.origin, Vector3.DOWN, height, WORLD_COLLISION_MASK)
	
	if floor_hit.is_empty():
		return
	
	var position_when_grounded: Vector3 = Vector3(
		global_transform.origin.x,
		floor_hit.position.y + (height / 2),
		global_transform.origin.z
	)
	
	global_transform.origin = position_when_grounded
