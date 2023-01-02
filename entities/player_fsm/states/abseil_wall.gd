extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var abseil_wall_speed: float = 2
var gravity_towards_wall: float = 20
var jump_power: float = 5
var movement: Vector3

func enter(_params: Dictionary) -> void:
	player.set_collision_mode("abseil")
	player.animation.play("Rope-wall")
	player.floor_stop_on_slope = true
	player.up_direction = Vector3.UP
	
func exit() -> void:
	player.set_collision_mode("default")
	movement = Vector3.ZERO
	
func update(delta: float) -> void:
	var last_edge_info = player.rope.get_last_edge_info()
	
	if last_edge_info.is_empty():
		last_edge_info.normal = Vector3.ZERO
		
	player.face_towards(player.rope.get_last_joint() - last_edge_info.normal)
	player.stamina.use(1.0 * delta)

func physics_update(delta: float) -> void:
	# TODO: Add check here to to see if joint is below the player. If it is, then transition
	# to a state where we can fall while grabbed to the rope.
	
	if player.is_on_floor():
		return state_machine.transition_to("AbseilGround")
		
	if player.is_on_wall():
#		return state_machine.transition_to("AbseilAir")
		pass
	
	var direction_to_last_rope_joint = player.global_transform.origin.direction_to(player.rope.get_last_joint())
	
	# This adding velocity instead of setting directly makes everything smooth
	# and the jump work correctly.
	movement += direction_to_last_rope_joint * gravity_towards_wall * delta
	
	# Dampen movement on wall to stop any swinging effect.
	movement = movement * 0.98 
	
	# Remove any vertical direction, this will instead be controlled by player input
	movement.y = -player.input_direction.y * abseil_wall_speed
	
	if player.is_on_wall() and Input.is_action_just_pressed(player.get_action_name("jump")):
		movement += (player.global_transform.basis.z) * jump_power
#		return state_machine.transition_to("AbseilWallJump")
	
	player.velocity = movement
	player.move_and_slide()
	
	movement = player.velocity
