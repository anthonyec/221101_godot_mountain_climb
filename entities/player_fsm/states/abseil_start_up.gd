extends PlayerState

func update(_delta: float) -> void:
	player.face_towards(player.companion.global_transform.origin)

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(player.get_action_name("start_hosting_abseil")):
		return state_machine.transition_to("Move")
