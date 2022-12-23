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
	
	if params.get("coyote_time_enabled", false):
		coyote_time.start()

func exit() -> void:
	into_fall_movement = Vector3.ZERO
	coyote_time.stop()
	
func update(_delta: float) -> void:
	direction = player.transform_direction_to_camera_angle(Vector3(player.input_direction.x, 0, player.input_direction.y))
	
	if state_machine.time_in_current_state > 5000:
		push_warning("In FALL state longer than expected")
		return state_machine.transition_to("Move", {
			"move_to": player.global_transform.origin + (Vector3.UP * 2)
		})

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		return state_machine.transition_to("Move")

	movement.x = into_fall_movement.x + direction.x
	movement.z = into_fall_movement.z + direction.z
	movement.y -= player.gravity * delta
	
	player.set_velocity(movement)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)

	# TODO: Add correct warning ID to ignore unused vars.
	# warning-ignore:warning-id
	player.move_and_slide()
	movement = player.velocity

func handle_input(event: InputEvent) -> void:
	if not coyote_time.is_stopped() and event.is_action_pressed(player.get_action_name("jump")):
		return state_machine.transition_to("Jump", { "movement": movement })
