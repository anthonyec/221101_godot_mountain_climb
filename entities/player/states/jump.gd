extends PlayerState

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO
var into_jump_movement: Vector3 = Vector3.ZERO
var original_gravity: float = 0

func enter(params: Dictionary) -> void:
	into_jump_movement = params.get("movement", Vector3.ZERO) * 1.2
	movement.y = params.get("jump_strength", player.jump_strength)
	
	player.animation.play("Jump")
	
	# Variable jump height thanks to the creator of Bounce.
	# TODO: Credit jack as jump researcher.
	original_gravity = player.gravity
	player.gravity = original_gravity / 2
#	snap_vector = Vector3.ZERO

	if params.has("face_towards"):
		player.face_towards(params.get("face_towards"))

func exit() -> void:
	into_jump_movement = Vector3.ZERO
	player.gravity = original_gravity

func update(_delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if state_machine.time_in_current_state > 5000:
		push_warning("In JUMP state longer than expected")
		state_machine.transition_to("Move", {
			"global_origin": player.global_transform.origin + (Vector3.UP * 2)
		})
		return
	
func physics_update(delta: float) -> void:	
	player.face_towards(player.global_transform.origin + direction, player.air_turn_speed, delta)
	
	movement.x = into_jump_movement.x + direction.x
	movement.z = into_jump_movement.z + direction.z
	movement.y -= player.gravity * delta
	
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity
	
	if player.is_on_floor():
		state_machine.transition_to("Move")
		return 
		
	if movement.y < 0:
		state_machine.transition_to("Fall", { "movement": movement })
		return 
	
func handle_input(event: InputEvent) -> void:
	if event.is_action_released(player.get_action_name("jump")):
		player.gravity = original_gravity
