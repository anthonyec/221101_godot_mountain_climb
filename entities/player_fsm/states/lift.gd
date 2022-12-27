extends PlayerState

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO

func enter(_params: Dictionary) -> void:
	player.animation.playback_speed = 0.5
	
func exit() -> void:
	player.companion.global_transform.origin = player.global_transform.origin - (player.global_transform.basis.z * 0.1)
	player.companion.state_machine.transition_to("Move")
	player.animation.playback_speed = 1

func update(_delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		return state_machine.transition_to("Fall", {
			"movement": movement,
			"coyote_time_enabled": true,
		})
		
	movement.x = direction.x * player.walk_speed / 2
	movement.z = direction.z * player.walk_speed / 2
	movement.y -= player.gravity * delta
	
	if direction.length():
		player.animation.play("Run")
	else:
		player.animation.play("Idle")
		
	player.face_towards(player.global_transform.origin + direction)
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity

func handle_input(event: InputEvent) -> void:
	if event.is_action_released(player.get_action_name("grab")):
		return player.state_machine.transition_to("Move")
