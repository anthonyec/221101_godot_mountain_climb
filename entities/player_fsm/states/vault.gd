extends PlayerState

func enter(_params: Dictionary) -> void:
	player.animation.playback_speed = 2
	player.animation.play("Hang-vault_RobotArmature")
	
	await player.animation.animation_finished
	
	return state_machine.transition_to("Move", {
		"move_to": player.get_offset_position(0.5, 1.2)
	})

func exit() -> void:
	player.animation.playback_speed = 1
