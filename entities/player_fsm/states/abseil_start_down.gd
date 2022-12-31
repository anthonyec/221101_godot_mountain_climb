extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var movement: Vector3
var start_position: Vector3

func enter(_params: Dictionary) -> void:
	Raycast.debug = true
	player.animation.play("Idle")
	start_position = player.global_transform.origin
	
func exit() -> void:
	movement = Vector3.ZERO
	Raycast.debug = false

func update(_delta: float) -> void:
	player.face_towards(player.rope.global_transform.origin)

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		return state_machine.transition_to("AbseilGround")
		
	var middle_wall_hit = Raycast.cast_in_direction(
		player.global_transform.origin, 
		-player.global_transform.basis.z, 
		0.8, 
	WORLD_COLLISION_MASK)
	
	var bottom_wall_hit = Raycast.cast_in_direction(
		player.get_offset_position(0, -1), 
		-player.global_transform.basis.z, 
		0.8, 
	WORLD_COLLISION_MASK)
	
	var distance_from_start: float = player.global_transform.origin.distance_to(start_position)
	
	if distance_from_start > 0.8 and (not middle_wall_hit.is_empty() or not bottom_wall_hit.is_empty()):
		return state_machine.transition_to("AbseilWall")

	movement.y -= 1.5 * delta
	
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)

	player.move_and_slide()
	movement = player.velocity
