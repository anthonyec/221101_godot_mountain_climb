extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var abseil_wall_speed: float = 2
var gravity_towards_wall: float = 20
var jump_power: float = 5
var dampening = 0.98

var movement: Vector3

func enter(params: Dictionary) -> void:
	assert(parent_state.rope, "Abseil states need rope")
	
	player.animation.play("T-pose")
	player.floor_stop_on_slope = true
	player.up_direction = Vector3.UP
	
func exit() -> void:
	player.set_collision_mode("default")
	movement = Vector3.ZERO
	
func update(delta: float) -> void:
	var last_edge_info = parent_state.rope.get_last_edge_info()
	
	if last_edge_info.is_empty():
		last_edge_info.normal = Vector3.ZERO
		
	player.face_towards(parent_state.rope.get_last_joint() - last_edge_info.normal)
	
	# TODO: Decide on the amount of stamina to use.
	player.stamina.use(1.0 * delta)

func physics_update(delta: float) -> void:
	# TODO: Add check here to to see if joint is below the player. If it is, then transition
	# to a state where we can fall while grabbed to the rope.

	if player.is_on_floor():
		state_machine.transition_to("Abseil/AbseilGround")
		return
		
	if not player.is_on_wall():
#		state_machine.transition_to("AbseilAir")
#		return
		pass
	
	var direction_to_last_rope_joint = player.global_transform.origin.direction_to(parent_state.rope.get_last_joint())
	
	# This adding velocity instead of setting directly makes everything smooth
	# and the jump work correctly.
	movement += direction_to_last_rope_joint * gravity_towards_wall * delta
	
	# Dampen movement on wall to stop any swinging effect.
	movement = movement * dampening
	
	# Remove any vertical direction, this will instead be controlled by player input
	movement.y = -player.input_direction.y * abseil_wall_speed
	
	if parent_state.rope.get_total_length() > parent_state.rope.get_max_length():
		movement.y = 0
		
		# TODO: Fix jittering by smoothing out the movement somehow.
		player.global_transform.origin = parent_state.rope.get_target_position()
	
	if player.is_on_wall() and Input.is_action_just_pressed(player.get_action_name("jump")):
		movement += (player.global_transform.basis.z) * jump_power
#		state_machine.transition_to("AbseilWallJump")
#		return
	
	var last_edge_info = parent_state.rope.get_last_edge_info()
	
	if not player.is_on_wall() and not last_edge_info.is_empty():
		var swing_direction = -last_edge_info.normal.cross(Vector3.UP)
		
		movement += swing_direction * player.input_direction.x * 5 * delta
		DebugDraw.draw_ray_3d(player.global_transform.origin, swing_direction, 2, Color.RED)

	
	player.velocity = movement
	player.move_and_slide()
	
	movement = player.velocity
	
	if !Input.is_action_pressed(player.get_action_name("grab")):
		state_machine.transition_to("Move")
		return
