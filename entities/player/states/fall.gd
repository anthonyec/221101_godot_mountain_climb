extends PlayerState

# TODO: Work out how to use `player` when insead of `owner`. It's null at the 
# time of initialisation.
@onready var coyote_time: Timer = owner.get_node("CoyoteTime")

var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO
var into_fall_movement: Vector3 = Vector3.ZERO

func enter(params: Dictionary) -> void:	
	player.animation.play("Fall")
	into_fall_movement = params.get("movement", Vector3.ZERO)
	
	player.up_direction = Vector3.UP
	player.floor_stop_on_slope = true
	
	if params.get("coyote_time_enabled", false):
		coyote_time.start()

func exit() -> void:
	into_fall_movement = Vector3.ZERO
	coyote_time.stop()
	
	# TODO: I need to reset Y velocity for some reason otherwise it gets bigger after grabbing
	movement.y = 0
	
func update(_delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if state_machine.time_in_current_state > 5000:
		push_warning("In FALL state longer than expected")
		state_machine.transition_to("Move", {
			"move_to": player.global_transform.origin + (Vector3.UP * 2)
		})
		return

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		state_machine.transition_to("Move")
		return
		
	var ledge_info = player.find_ledge_info()	
	
	if Input.is_action_pressed(player.get_action_name("grab")) and not ledge_info.is_empty() and not ledge_info.has("error") and not player.stamina.is_depleted():		
		state_machine.transition_to("Hang", {
			"move_to": ledge_info.hang_position,
			"face_towards": ledge_info.wall.position
		})
		return
		
	player.face_towards(player.global_transform.origin + direction, player.air_turn_speed, delta)

	movement.x = into_fall_movement.x + direction.x
	movement.z = into_fall_movement.z + direction.z
	movement.y -= player.gravity * delta
	
	player.velocity = movement
	
	if player.velocity.length() >= 20.0:
		player.velocity = player.velocity.normalized() * 20.0

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity

func handle_input(event: InputEvent) -> void:		
	if not coyote_time.is_stopped() and event.is_action_pressed(player.get_action_name("jump")):
		state_machine.transition_to("Jump", { "movement": movement })
		return
