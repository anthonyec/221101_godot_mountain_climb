extends PlayerState

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO
var into_jump_movement: Vector3 = Vector3.ZERO
var original_gravity: float = 0

var debug_last_height: float = 0
var debug_start_position: Vector3

func enter(params: Dictionary) -> void:
	into_jump_movement = params.get("movement", Vector3.ZERO)
	var momentum_speed = params.get("momentum_speed", 0)
	
	into_jump_movement.x = into_jump_movement.x * 1.7 * momentum_speed
	into_jump_movement.z = into_jump_movement.z * 1.7 * momentum_speed
	
	# Calculation from: https://gamedev.net/forums/topic/640123-calculating-the-force-to-jump-an-exact-distance/5042043/
	var jump_velocity = player.gravity * sqrt(player.jump_height / player.gravity)
	
	# TODO: Remove this once I have dedicated wall jump state
	if params.has("jump_strength"):
		jump_velocity = params.get("jump_strength")
		
	movement.y = jump_velocity
	
	player.animation.play("Jump")
	
	# Variable jump height thanks to the creator of Bounce.
	# TODO: Credit jack as jump researcher.
	original_gravity = player.gravity
	player.gravity = original_gravity / 2
#	snap_vector = Vector3.ZERO

	if params.has("face_towards"):
		player.face_towards(params.get("face_towards"))
		
	debug_start_position = player.global_transform.origin

func exit() -> void:
	into_jump_movement = Vector3.ZERO
	player.gravity = original_gravity
	
	debug_last_height = 0

func update(_delta: float) -> void:
	if player.is_on_ground():
		state_machine.transition_to("Move")
		return
		
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	var debug_jump_height = player.global_transform.origin.y - debug_start_position.y
	
	if debug_jump_height > debug_last_height:
		debug_last_height = debug_jump_height
	
	DebugDraw.set_text("jump_height", debug_last_height)
	
	if state_machine.time_in_current_state > 5000:
		push_warning("In JUMP state longer than expected")
		state_machine.transition_to("Move", {
			"global_origin": player.global_transform.origin + (Vector3.UP * 2)
		})
		return
	
func physics_update(delta: float) -> void:
#	player.face_towards(player.global_transform.origin + direction, player.air_turn_speed, delta)
	
	movement.x = into_jump_movement.x + direction.x
	movement.z = into_jump_movement.z + direction.z
	
	# TODO: Add euler interation or something to so that there isn't tiny 
	# variations in jump height when timescale or framerate changes:
	# https://youtu.be/h2r3_KjChf4?t=446
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
