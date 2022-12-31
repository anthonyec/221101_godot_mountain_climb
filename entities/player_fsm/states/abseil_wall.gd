extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var abseil_wall_speed: float = 2
var gravity_towards_wall: float = 10
var movement: Vector3

func enter(_params: Dictionary) -> void:
	player.collision.disabled = true
	player.abseil_collision.disabled = false
	player.animation.play("Idle")
	
func exit() -> void:
	player.collision.disabled = false
	player.abseil_collision.disabled = true
	movement = Vector3.ZERO
	
func update(delta: float) -> void:
	player.face_towards(player.rope.get_last_joint())

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		return state_machine.transition_to("AbseilGround")
	
#	var wall_hit = Raycast.cast_in_direction(player.global_transform.origin, -player.global_transform.basis.z, 1, WORLD_COLLISION_MASK)
	
#	if not wall_hit.is_empty():
#		player.face_towards(player.global_transform.origin - wall_hit.normal)
#		player.global_transform.origin = wall_hit.position + wall_hit.normal * 0.35
	
	var direction_to_rope = player.global_transform.origin.direction_to(player.rope.get_last_joint())
	
	movement = direction_to_rope * gravity_towards_wall
	movement.y = -player.input_direction.y * abseil_wall_speed
	
	if Input.is_action_just_pressed(player.get_action_name("jump")):
		movement = (-player.global_transform.basis.z) * 20
		
	DebugDraw.draw_ray_3d(player.global_transform.origin, direction_to_rope, 1, Color.RED)
	
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
#	player.set_up_direction(direction_to_rope)
	player.set_floor_stop_on_slope_enabled(true)

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
#	movement = player.velocity
