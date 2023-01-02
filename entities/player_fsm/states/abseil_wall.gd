extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var abseil_wall_speed: float = 2
var gravity_towards_wall: float = 10
var movement: Vector3

func enter(_params: Dictionary) -> void:
	player.set_collision_mode("abseil")
	player.animation.play("Idle")
	
func exit() -> void:
	player.set_collision_mode("default")
	movement = Vector3.ZERO
	
func update(delta: float) -> void:
	player.face_towards(player.rope.get_last_joint())

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		return state_machine.transition_to("AbseilGround")
		
	DebugDraw.set_text("is_on_wall", player.is_on_wall())
	
#	var wall_hit = Raycast.cast_in_direction(player.global_transform.origin, -player.global_transform.basis.z, 1, WORLD_COLLISION_MASK)
	
#	if not wall_hit.is_empty():
#		player.face_towards(player.global_transform.origin - wall_hit.normal)
#		player.global_transform.origin = wall_hit.position + wall_hit.normal * 0.35
	
	var direction_to_rope = player.global_transform.origin.direction_to(player.rope.get_last_joint())
	
	direction_to_rope.y = 0
	
	movement = direction_to_rope * gravity_towards_wall
	movement.y = -player.input_direction.y * abseil_wall_speed
	
	if Input.is_action_just_pressed(player.get_action_name("jump")):
		movement = (-player.global_transform.basis.z) * 20
		
	DebugDraw.draw_ray_3d(player.global_transform.origin, direction_to_rope, 1, Color.RED)
	DebugDraw.draw_ray_3d(player.global_transform.origin, movement, 2, Color.GREEN)
	
	player.set_floor_stop_on_slope_enabled(true)
	
	player.set_up_direction(Vector3.UP)
#	player.set_up_direction(direction_to_rope)
	
	player.velocity = movement
	player.move_and_slide()
