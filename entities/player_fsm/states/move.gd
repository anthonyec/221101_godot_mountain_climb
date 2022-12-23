extends PlayerState

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO

func enter(params: Dictionary) -> void:
	Raycast.debug = true
	player.stamina.can_recover = true
	
	if params.has("global_origin"):
		player.global_transform.origin = params.get("global_origin")
	
func exit() -> void:
	player.stamina.can_recover = false

func update(delta: float) -> void:
	player.find_ledge_info()
	
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if direction.length():
		player.animation.play("Run")
	else:
		player.animation.play("Idle")

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		return state_machine.transition_to("Fall", {
			"movement": movement,
			"coyote_time_enabled": true,
		})
	
	movement.x = direction.x * player.walk_speed
	movement.z = direction.z * player.walk_speed
	movement.y -= player.gravity * delta
	
	player.face_towards(player.global_transform.origin + direction)
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity
	
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("jump")):
		return state_machine.transition_to("Jump", { "movement": movement })
