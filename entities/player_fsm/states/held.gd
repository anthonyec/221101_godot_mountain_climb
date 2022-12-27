extends PlayerState

func enter(_params: Dictionary) -> void:
	player.collision.disabled = true
	player.animation.play("T-pose")
	
func exit() -> void:
	player.collision.disabled = false

func update(_delta: float) -> void:
	player.global_transform.origin = player.companion.global_transform.origin + (Vector3.UP * 1.5)
	player.global_rotation = player.companion.global_rotation

func handle_input(event: InputEvent) -> void:
	# TODO: This should use input flushing
	if state_machine.time_in_current_state > 500 and event.is_action_pressed(player.get_action_name("jump")):
		# TODO: This should send an event, not force the other player into a state
		player.companion.state_machine.transition_to("Move")
		return state_machine.transition_to("Jump")
