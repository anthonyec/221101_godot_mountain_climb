extends PlayerState

func enter(params: Dictionary) -> void:
	player.animation.playback_speed = 2
	player.animation.play("Hang-vault_RobotArmature")
	
	await player.animation.animation_finished
	
	state_machine.transition_to("Move", {
		"move_to": params.get("move_to", player.get_offset_position(0.5, 1.2)),
		"snap_to_floor": true
	})
	return

func exit() -> void:
	player.animation.playback_speed = 1
