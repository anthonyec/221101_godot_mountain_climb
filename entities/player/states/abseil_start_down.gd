extends PlayerState

const WORLD_COLLISION_MASK: int = 1

var movement: Vector3
var start_position: Vector3

func enter(params: Dictionary) -> void:
	assert(parent_state.rope, "Abseil states need rope")
	
	Raycast.debug = true
	player.animation.play("Idle")
	start_position = player.global_transform.origin
	
func exit() -> void:
	movement = Vector3.ZERO
	Raycast.debug = false

func update(_delta: float) -> void:
	player.face_towards(parent_state.rope.global_transform.origin)

func physics_update(_delta: float) -> void:
	if player.is_on_floor():
		state_machine.transition_to("Abseil/AbseilGround")
		return
	
	var distance_from_start: float = start_position.y - player.global_transform.origin.y
	
	# TODO: Think of a better check.
	if distance_from_start > 1.0 and parent_state.rope.joints.size() > 1:
		state_machine.transition_to("Abseil/AbseilWall")
		return

	movement.y = -3
	
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)

	player.move_and_slide()
	movement = player.velocity
